import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/design_system/ec_haptics.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../core/theme/ec_type.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';
import 'body_map_store.dart';

/// Pixel rects for each tappable region, derived from the canvas [size].
Map<BodyRegion, Rect> _regionRects(Size s) {
  final w = s.width;
  final h = s.height;
  Rect c(double cx, double cy, double rw, double rh) => Rect.fromCenter(
        center: Offset(cx * w, cy * h),
        width: rw * w,
        height: rh * h,
      );
  return {
    BodyRegion.head: c(0.50, 0.085, 0.20, 0.15),
    BodyRegion.chest: c(0.50, 0.30, 0.36, 0.18),
    BodyRegion.abdomen: c(0.50, 0.49, 0.32, 0.18),
    BodyRegion.leftArm: c(0.235, 0.34, 0.12, 0.30),
    BodyRegion.rightArm: c(0.765, 0.34, 0.12, 0.30),
    BodyRegion.leftLeg: c(0.40, 0.78, 0.15, 0.36),
    BodyRegion.rightLeg: c(0.60, 0.78, 0.15, 0.36),
  };
}

/// Body Map — tap a region to log a symptom. Conditions highlight zones in
/// jade; logged symptoms shade the region gold by severity.
class BodyMapScreen extends ConsumerWidget {
  const BodyMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ec = EcColors.of(context);
    final overview = ref.watch(healthOverviewProvider).valueOrNull;
    final conditions = overview?.profile?.conditions ?? const <String>[];
    final highlighted = zonesForConditions(conditions);
    final logged = ref.watch(symptomLogProvider).valueOrNull ?? const {};

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Body map'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, kEcNavBottomPadding),
        children: [
          Text(
            'Tap where it hurts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Log a symptom by tapping a body region. Zones tied to your '
            'conditions glow jade.',
            style: TextStyle(color: ec.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final size = Size(w, w / 0.52);
              final rects = _regionRects(size);
              return GestureDetector(
                onTapDown: (d) {
                  for (final entry in rects.entries) {
                    if (entry.value.contains(d.localPosition)) {
                      EcHaptics.lightTap();
                      _showLogSheet(context, ref, entry.key,
                          logged[entry.key]);
                      break;
                    }
                  }
                },
                child: CustomPaint(
                  size: size,
                  painter: _BodyPainter(
                    rects: rects,
                    highlighted: highlighted,
                    logged: {
                      for (final e in logged.entries) e.key: e.value.severity,
                    },
                    baseFill: ec.textMuted.withValues(alpha: 0.10),
                    border: ec.textMuted.withValues(alpha: 0.35),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _Legend(),
          if (logged.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Logged symptoms',
                style: EcType.sectionLabel(color: EcTokens.accentGold)),
            const SizedBox(height: 10),
            ...logged.entries.map(
              (e) => _SymptomRow(region: e.key, entry: e.value, ref: ref),
            ),
          ],
        ],
      ),
    );
  }
}

void _showLogSheet(
  BuildContext context,
  WidgetRef ref,
  BodyRegion region,
  SymptomEntry? existing,
) {
  showEcGlassSheet(
    context,
    children: [_LogSheetContent(region: region, existing: existing, ref: ref)],
  );
}

class _LogSheetContent extends StatefulWidget {
  const _LogSheetContent({
    required this.region,
    required this.existing,
    required this.ref,
  });

  final BodyRegion region;
  final SymptomEntry? existing;
  final WidgetRef ref;

  @override
  State<_LogSheetContent> createState() => _LogSheetContentState();
}

class _LogSheetContentState extends State<_LogSheetContent> {
  late int _severity = widget.existing?.severity ?? 3;
  late final TextEditingController _note =
      TextEditingController(text: widget.existing?.note ?? '');

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log symptom · ${widget.region.label}',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Text('Severity', style: TextStyle(color: ec.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final active = i < _severity;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    EcHaptics.lightTap();
                    setState(() => _severity = i + 1);
                  },
                  child: Container(
                    height: 38,
                    margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: active
                          ? EcTokens.accentGold.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? EcTokens.accentGold.withValues(alpha: 0.6)
                            : ec.textMuted.withValues(alpha: 0.25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: active ? EcTokens.accentGold : ec.textMuted,
                        )),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Add a note (optional)'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.existing != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.ref
                          .read(symptomLogProvider.notifier)
                          .clear(widget.region);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
              if (widget.existing != null) const SizedBox(width: 12),
              Expanded(
                child: EcGlassButton(
                  label: 'Save',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    EcHaptics.doseConfirmed();
                    widget.ref.read(symptomLogProvider.notifier).log(
                          widget.region,
                          _severity,
                          _note.text.trim(),
                        );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.rects,
    required this.highlighted,
    required this.logged,
    required this.baseFill,
    required this.border,
  });

  final Map<BodyRegion, Rect> rects;
  final Set<BodyRegion> highlighted;
  final Map<BodyRegion, int> logged;
  final Color baseFill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in rects.entries) {
      final region = entry.key;
      final rect = entry.value;
      final sev = logged[region];
      final isHighlighted = highlighted.contains(region);

      Color fill;
      Color stroke;
      if (sev != null) {
        fill = EcTokens.accentGold.withValues(alpha: 0.12 + 0.12 * sev);
        stroke = EcTokens.accentGold.withValues(alpha: 0.8);
      } else if (isHighlighted) {
        fill = EcTokens.accentJade.withValues(alpha: 0.22);
        stroke = EcTokens.accentJade.withValues(alpha: 0.7);
      } else {
        fill = baseFill;
        stroke = border;
      }

      final fillPaint = Paint()..color = fill;
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = stroke;

      if (region == BodyRegion.head) {
        canvas.drawOval(rect, fillPaint);
        canvas.drawOval(rect, strokePaint);
      } else {
        final radius = Radius.circular(
          region == BodyRegion.leftArm || region == BodyRegion.rightArm ||
                  region == BodyRegion.leftLeg ||
                  region == BodyRegion.rightLeg
              ? 22
              : 16,
        );
        final rrect = RRect.fromRectAndRadius(rect, radius);
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.highlighted != highlighted ||
      old.logged.length != logged.length ||
      old.baseFill != baseFill;
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color),
              ),
            ),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(fontSize: 12, color: ec.textSecondary)),
          ],
        );
    return Row(
      children: [
        item(EcTokens.accentJade, 'Condition zone'),
        const SizedBox(width: 20),
        item(EcTokens.accentGold, 'Logged symptom'),
      ],
    );
  }
}

class _SymptomRow extends StatelessWidget {
  const _SymptomRow({
    required this.region,
    required this.entry,
    required this.ref,
  });

  final BodyRegion region;
  final SymptomEntry entry;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EcGlassSurface(
        variant: EcGlassVariant.regular,
        borderRadius: EcTokens.radiusCard,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(region.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    entry.note.isEmpty ? 'Severity ${entry.severity}/5' : entry.note,
                    style: TextStyle(color: ec.textSecondary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(
                5,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < entry.severity
                        ? EcTokens.accentGold
                        : ec.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: ec.textMuted),
              onPressed: () =>
                  ref.read(symptomLogProvider.notifier).clear(region),
            ),
          ],
        ),
      ),
    );
  }
}
