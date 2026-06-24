import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/ec_haptics.dart';
import '../../core/health/vitals_store.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../core/theme/ec_type.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_sparkline.dart';

/// Health key-metrics as a variable-height bento grid:
///   Heart Rate (tall) · Blood Oxygen + Weight (stacked squares) · Blood
///   Pressure (wide) · Resting HR + HRV (squares). Each tile shows a sparkline
///   backdrop (flat zero line when empty) and supports inline number-spinner
///   logging without leaving the screen. Blood pressure (two values) opens the
///   existing log sheet via [onLog].
class HealthBentoGrid extends ConsumerWidget {
  const HealthBentoGrid({super.key, required this.onLog});

  final void Function(VitalType type) onLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(vitalsProvider); // rebuild when readings change

    return Column(
      children: [
        // Row 1: tall Heart Rate (left) | stacked Blood Oxygen + Weight (right)
        SizedBox(
          height: 244,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: _MetricTile(
                  type: VitalType.heartRate,
                  accent: EcTokens.accentGold,
                  valueSize: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Expanded(
                      child: _MetricTile(
                        type: VitalType.bloodOxygen,
                        accent: EcTokens.accentJade,
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: _MetricTile(
                        type: VitalType.weight,
                        accent: EcTokens.accentJade,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Row 2: wide Blood Pressure
        SizedBox(
          height: 108,
          child: _BpTile(onTap: () => onLog(VitalType.bloodPressureSystolic)),
        ),
        const SizedBox(height: 12),
        // Row 3: Resting HR | HRV
        SizedBox(
          height: 124,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(
                child: _MetricTile(
                  type: VitalType.restingHR,
                  accent: EcTokens.accentJade,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  type: VitalType.hrv,
                  accent: EcTokens.accentJade,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

double _defaultFor(VitalType t) {
  final r = t.normalRange;
  if (r != null) return ((r.$1 + r.$2) / 2).roundToDouble();
  return switch (t) {
    VitalType.weight => 70,
    VitalType.steps => 5000,
    _ => 0,
  };
}

double _stepFor(VitalType t) => t == VitalType.weight ? 0.5 : 1;

(double, double) _clampFor(VitalType t) => switch (t) {
      VitalType.heartRate => (30, 220),
      VitalType.restingHR => (30, 150),
      VitalType.bloodOxygen => (70, 100),
      VitalType.weight => (20, 400),
      VitalType.hrv => (0, 250),
      _ => (0, 100000),
    };

String _fmt(VitalType t, double v) =>
    t == VitalType.weight ? v.toStringAsFixed(1) : v.toStringAsFixed(0);

/// Single-value metric tile with sparkline backdrop + inline number spinner.
class _MetricTile extends ConsumerStatefulWidget {
  const _MetricTile({
    required this.type,
    required this.accent,
    this.valueSize = 30,
  });

  final VitalType type;
  final Color accent;
  final double valueSize;

  @override
  ConsumerState<_MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends ConsumerState<_MetricTile> {
  bool _editing = false;
  double _draft = 0;

  void _start() {
    final latest = ref.read(vitalsProvider.notifier).latest(widget.type);
    EcHaptics.lightTap();
    setState(() {
      _editing = true;
      _draft = latest?.value ?? _defaultFor(widget.type);
    });
  }

  void _bump(double delta) {
    final (lo, hi) = _clampFor(widget.type);
    EcHaptics.lightTap();
    setState(() => _draft = (_draft + delta).clamp(lo, hi));
  }

  Future<void> _commit() async {
    await EcHaptics.doseConfirmed();
    await ref.read(vitalsProvider.notifier).log(widget.type, _draft);
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(vitalsProvider);
    final n = ref.read(vitalsProvider.notifier);
    final latest = n.latest(widget.type);
    final values = n.lastN(widget.type).map((e) => e.value).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight;
    final ec = EcColors.of(context);

    return EcGlassSurface(
      onTap: _editing ? null : _start,
      variant: EcGlassVariant.regular,
      borderRadius: EcTokens.radiusCard,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.55,
                child: EcSparkline(
                  values: values.length >= 2 ? values : List.filled(6, 0.0),
                  color: widget.accent,
                  height: 32,
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _editing
                ? _editor(primary, ec)
                : _display(primary, ec, latest?.value),
          ),
        ],
      ),
    );
  }

  Widget _display(Color primary, EcColors ec, double? value) {
    return Column(
      key: const ValueKey('display'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(widget.type.icon, size: 16, color: widget.accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ec.textSecondary,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _AnimatedValue(
              value: value,
              type: widget.type,
              size: widget.valueSize,
              color: primary,
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                widget.type.unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ec.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _editor(Color primary, EcColors ec) {
    final step = _stepFor(widget.type);
    return Column(
      key: const ValueKey('editor'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.type.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ec.textSecondary,
          ),
        ),
        Row(
          children: [
            _circleBtn(Icons.remove_rounded, () => _bump(-step), ec),
            Expanded(
              child: Center(
                child: Text(
                  _fmt(widget.type, _draft),
                  style: EcType.metric(color: primary, size: 24),
                ),
              ),
            ),
            _circleBtn(Icons.add_rounded, () => _bump(step), ec),
            const SizedBox(width: 6),
            _circleBtn(Icons.check_rounded, _commit, ec, filled: true),
          ],
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, EcColors ec,
      {bool filled = false}) {
    return Material(
      color: filled
          ? EcTokens.accentGold
          : Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 18,
            color: filled ? EcTokens.onAccentDark : ec.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Counts up to the new value with an easeOut curve when it changes.
class _AnimatedValue extends StatelessWidget {
  const _AnimatedValue({
    required this.value,
    required this.type,
    required this.size,
    required this.color,
  });

  final double? value;
  final VitalType type;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Text('--', style: EcType.metric(color: color, size: size));
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value!),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, v, _) =>
          Text(_fmt(type, v), style: EcType.metric(color: color, size: size)),
    );
  }
}

/// Wide Blood Pressure tile (two values) — opens the log sheet via [onTap].
class _BpTile extends ConsumerWidget {
  const _BpTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(vitalsProvider);
    final n = ref.read(vitalsProvider.notifier);
    final sys = n.latest(VitalType.bloodPressureSystolic);
    final dia = n.latest(VitalType.bloodPressureDiastolic);
    final values =
        n.lastN(VitalType.bloodPressureSystolic).map((e) => e.value).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight;
    final ec = EcColors.of(context);
    final display = sys == null
        ? '--'
        : (dia == null
            ? sys.value.toStringAsFixed(0)
            : '${sys.value.toStringAsFixed(0)}/${dia.value.toStringAsFixed(0)}');

    return EcGlassSurface(
      onTap: () {
        EcHaptics.lightTap();
        onTap();
      },
      variant: EcGlassVariant.regular,
      borderRadius: EcTokens.radiusCard,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            left: 120,
            bottom: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.5,
                child: EcSparkline(
                  values: values.length >= 2 ? values : List.filled(6, 0.0),
                  color: EcTokens.accentGold,
                  height: 30,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed_rounded,
                            size: 16, color: EcTokens.accentGold),
                        const SizedBox(width: 6),
                        Text(
                          'Blood pressure',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ec.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(display,
                            style: EcType.metric(color: primary, size: 32)),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('mmHg',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ec.textMuted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ec.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
