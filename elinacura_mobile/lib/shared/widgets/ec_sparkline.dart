import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/health/vitals_store.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';
import 'ec_widgets.dart';

// ──────────────────────────────────────────────── Sparkline ──

/// Inline 7-point line sparkline. Intentionally minimal — no axes, no grid.
/// [values] are y-values in order (oldest → newest).
class EcSparkline extends StatelessWidget {
  const EcSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 40,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);

    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (values.length - 1).toDouble(),
          lineTouchData: LineTouchData(enabled: false),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────── Metric card ──

/// Google-Health-style metric card: category icon + label, large value,
/// status chip, and a 7-point sparkline.
///
/// Use in a 2-column GridView.
class EcSparklineCard extends StatelessWidget {
  const EcSparklineCard({
    super.key,
    required this.type,
    required this.latestEntry,
    required this.sparkValues,
    this.onTap,
  });

  final VitalType type;
  final VitalEntry? latestEntry;
  final List<double> sparkValues;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasData = latestEntry != null;
    final value = latestEntry?.value;
    final color = type.color;
    final fillColor = isDark ? color.withValues(alpha: 0.14) : type.fillColor;
    final statusLabel = value != null ? type.statusLabel(value) : null;
    final inRange = value != null ? type.isInRange(value) : null;
    final tone = inRange == null
        ? EcPillTone.neutral
        : inRange
            ? EcPillTone.positive
            : EcPillTone.caution;

    return EcGlassSurface(
      onTap: onTap,
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusCard,
      categoryFill: isDark ? null : fillColor,
      tint: color,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category icon + label
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(type.icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.60),
                    fontFamily: EcTokens.fontFamily,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Value + unit
          if (hasData) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatValue(value!),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: EcTokens.fontFamily,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    type.unit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.45),
                      fontFamily: EcTokens.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
            if (statusLabel != null) ...[
              const SizedBox(height: 4),
              EcPill(label: statusLabel, tone: tone),
            ],
            if (sparkValues.length >= 2) ...[
              const SizedBox(height: 8),
              EcSparkline(values: sparkValues, color: color, height: 38),
            ],
          ] else ...[
            Text(
              'No data yet',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.40),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to log',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.80),
                fontFamily: EcTokens.fontFamily,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatValue(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

// ──────────────────────────────────────────── Activity ring ──

/// Google-Health-style circular arc showing a weekly goal percentage.
/// Rendered in [color] on a light track. A large percent label sits at centre.
class EcActivityRing extends StatelessWidget {
  const EcActivityRing({
    super.key,
    required this.value,
    required this.label,
    required this.subLabel,
    this.color = EcTokens.categoryActivity,
    this.size = 140,
  });

  /// 0.0–1.0 completion ratio.
  final double value;
  final String label;
  final String subLabel;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.12);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingArcPainter(
              value: value.clamp(0.0, 1.0),
              color: color,
              trackColor: trackColor,
              strokeWidth: size * 0.085,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(value.clamp(0.0, 1.0) * 100).round()}%',
                style: TextStyle(
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  color: textColor,
                  fontFamily: EcTokens.fontFamily,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: size * 0.095,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: EcTokens.fontFamily,
                  height: 1.0,
                ),
              ),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: size * 0.08,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.45),
                  fontFamily: EcTokens.fontFamily,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingArcPainter extends CustomPainter {
  const _RingArcPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const start = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (value > 0) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        2 * math.pi * value,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingArcPainter old) =>
      old.value != value || old.color != color;
}

// ────────────────────────────────────── Log vitals bottom sheet ──

/// Shows a sheet with one input per VitalType so the user can log readings.
Future<void> showLogVitalsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => EcLogVitalsSheet(
      types: const [
        VitalType.heartRate,
        VitalType.bloodPressureSystolic,
        VitalType.bloodOxygen,
        VitalType.weight,
        VitalType.restingHR,
        VitalType.hrv,
      ],
    ),
  );
}

/// Public sheet widget — can be pushed directly or used in showModalBottomSheet.
class EcLogVitalsSheet extends StatefulWidget {
  const EcLogVitalsSheet({super.key, required this.types});

  final List<VitalType> types;

  @override
  State<EcLogVitalsSheet> createState() => _EcLogVitalsSheetState();
}

class _EcLogVitalsSheetState extends State<EcLogVitalsSheet> {
  final Map<VitalType, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final t in widget.types) {
      _controllers[t] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The sheet is embedded inside a ConsumerWidget context via showEcLogVitalsSheet.
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final ec = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: EcGlassSurface(
        variant: EcGlassVariant.float,
        borderRadius: EcTokens.radiusHero,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ec.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Log vitals',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Enter today\'s readings — all fields are optional.',
              style: TextStyle(
                color: ec.onSurface.withValues(alpha: 0.55),
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 20),
            ...widget.types.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _controllers[t],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${t.label} (${t.unit})',
                    prefixIcon: Icon(t.icon, color: t.color, size: 20),
                    prefixIconColor: t.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Save button wired in calling widget via Navigator.pop + return value
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save readings'),
                onPressed: () {
                  final values = <VitalType, double>{};
                  for (final t in widget.types) {
                    final v = double.tryParse(_controllers[t]?.text.trim() ?? '');
                    if (v != null) values[t] = v;
                  }
                  Navigator.of(context).pop(values);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The duplicate _LogVitalsSheet below is unused — removed.
