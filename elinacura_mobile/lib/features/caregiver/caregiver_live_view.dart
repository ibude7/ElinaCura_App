import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/health/care_rhythm.dart';
import '../../core/health/dose_log.dart';
import '../../core/health/vitals_store.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../core/theme/ec_type.dart';
import '../../shared/widgets/ec_glass.dart';

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

/// Real-time patient snapshot for caregivers: doses today, last vitals,
/// next dose, and whether the patient has been active in the app today.
class CaregiverLiveView extends ConsumerWidget {
  const CaregiverLiveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ec = EcColors.of(context);
    final overview = ref.watch(healthOverviewProvider).valueOrNull;
    final meds = overview?.medications ?? const [];
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
    final vitals = ref.watch(vitalsProvider).valueOrNull ?? const {};
    final adherence = computeAdherence(log, meds);
    final rhythm = buildCareRhythm(medications: meds, doseLog: log);
    final next = rhythm.where((i) => !i.done).firstOrNull;

    // Most recent vital across all types.
    VitalEntry? lastVital;
    VitalType? lastVitalType;
    for (final entry in vitals.entries) {
      final last = entry.value.isNotEmpty ? entry.value.last : null;
      if (last == null) continue;
      if (lastVital == null || last.timestamp.isAfter(lastVital.timestamp)) {
        lastVital = last;
        lastVitalType = entry.key;
      }
    }

    final todayKey = dayKey(DateTime.now());
    final activeToday = (log[todayKey]?.isNotEmpty ?? false) ||
        (lastVital != null && dayKey(lastVital.timestamp) == todayKey);

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('LIVE VIEW',
                  style: EcType.sectionLabel(color: EcTokens.accentGold)),
              const Spacer(),
              _ActivePill(active: activeToday),
            ],
          ),
          const SizedBox(height: 16),
          _LiveStat(
            icon: Icons.medication_rounded,
            color: EcTokens.accentGold,
            label: 'Doses today',
            value: adherence.hasSchedule
                ? '${adherence.todayTaken}/${adherence.todayScheduled}'
                : 'No schedule',
          ),
          _divider(ec),
          _LiveStat(
            icon: Icons.favorite_rounded,
            color: EcTokens.accentJade,
            label: 'Last vitals',
            value: lastVital == null
                ? 'None logged'
                : '${lastVitalType!.label} · ${_ago(lastVital.timestamp)}',
          ),
          _divider(ec),
          _LiveStat(
            icon: Icons.schedule_rounded,
            color: ec.textSecondary,
            label: 'Next dose',
            value: next == null ? 'All done 🎉' : '${next.label} · ${next.time}',
          ),
        ],
      ),
    );
  }

  Widget _divider(EcColors ec) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: ec.textMuted.withValues(alpha: 0.15)),
      );
}

class _ActivePill extends StatelessWidget {
  const _ActivePill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? EcTokens.accentJade : EcColors.of(context).textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(EcTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Active today' : 'Not active yet',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  const _LiveStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final primary = Theme.of(context).brightness == Brightness.dark
        ? EcTokens.textPrimaryDark
        : EcTokens.textPrimaryLight;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 13, color: ec.textSecondary)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }
}
