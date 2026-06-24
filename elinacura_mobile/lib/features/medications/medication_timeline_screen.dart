import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/design_system/ec_haptics.dart';
import '../../core/health/dose_log.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../core/theme/ec_type.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

/// One scheduled dose slot (a medication at a specific time of day).
class _Slot {
  const _Slot(this.med, this.time);
  final MedicationItem med;
  final String time;
  String get key => doseSlotKey(med.id, time);
}

/// 90-day medication adherence timeline — a GitHub-contributions-style grid.
/// Columns = days, rows = dose slots; gold dot = taken, faint = missed.
class MedicationTimelineScreen extends ConsumerWidget {
  const MedicationTimelineScreen({super.key});

  static const int _days = 90;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ec = EcColors.of(context);
    final overview = ref.watch(healthOverviewProvider).valueOrNull;
    final meds = overview?.medications ?? const <MedicationItem>[];
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};

    final slots = <_Slot>[
      for (final m in meds)
        for (final t in m.times) _Slot(m, t),
    ];

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Adherence timeline'),
      body: slots.isEmpty
          ? const Center(
              child: EcEmptyState(
                icon: Icons.calendar_month_rounded,
                title: 'No medications yet',
                message: 'Add medications with a schedule to see your '
                    '90-day adherence story.',
              ),
            )
          : _TimelineBody(slots: slots, log: log, days: _days, ec: ec),
    );
  }
}

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({
    required this.slots,
    required this.log,
    required this.days,
    required this.ec,
  });

  final List<_Slot> slots;
  final Map<String, Set<String>> log;
  final int days;
  final EcColors ec;

  static const double _cell = 16;
  static const double _dot = 11;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = [
      for (var i = days - 1; i >= 0; i--)
        DateTime(today.year, today.month, today.day).subtract(Duration(days: i)),
    ];

    // Adherence summary across the window.
    var taken = 0;
    var total = 0;
    for (final d in dates) {
      final set = log[dayKey(d)] ?? const <String>{};
      for (final s in slots) {
        total++;
        if (set.contains(s.key)) taken++;
      }
    }
    final pct = total == 0 ? 0 : (taken / total * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, kEcNavBottomPadding),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$pct%', style: EcType.metric(color: EcTokens.accentGold, size: 40)),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('$taken of $total doses\nlast $days days',
                  style: TextStyle(color: ec.textSecondary, fontSize: 12, height: 1.3)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        EcGlassSurface(
          variant: EcGlassVariant.elevated,
          borderRadius: EcTokens.radiusGlass,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in slots)
                    SizedBox(
                      height: _cell,
                      child: Text(
                        '${s.med.name} · ${s.time}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: EcType.mono(color: ec.textMuted, size: 9),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: [
                      for (final d in dates)
                        _DayColumn(
                          date: d,
                          slots: slots,
                          takenSet: log[dayKey(d)] ?? const <String>{},
                          cell: _cell,
                          dot: _dot,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Legend(ec: ec),
      ],
    );
  }
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.date,
    required this.slots,
    required this.takenSet,
    required this.cell,
    required this.dot,
  });

  final DateTime date;
  final List<_Slot> slots;
  final Set<String> takenSet;
  final double cell;
  final double dot;

  @override
  Widget build(BuildContext context) {
    final faint = EcColors.of(context).textMuted.withValues(alpha: 0.18);
    return Column(
      children: [
        for (final s in slots)
          SizedBox(
            width: cell,
            height: cell,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  EcHaptics.lightTap();
                  final taken = takenSet.contains(s.key);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(
                        '${s.med.name} · ${s.time} · ${_fmtDate(date)} · '
                        '${taken ? 'Taken' : 'Missed'}',
                      ),
                    ));
                },
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: takenSet.contains(s.key)
                        ? EcTokens.accentGold
                        : faint,
                    boxShadow: takenSet.contains(s.key)
                        ? [
                            BoxShadow(
                              color: EcTokens.accentGold.withValues(alpha: 0.4),
                              blurRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.ec});

  final EcColors ec;

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(fontSize: 12, color: ec.textSecondary)),
          ],
        );
    return Row(
      children: [
        item(EcTokens.accentGold, 'Taken'),
        const SizedBox(width: 20),
        item(ec.textMuted.withValues(alpha: 0.18), 'Missed'),
      ],
    );
  }
}
