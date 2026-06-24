import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/ec_haptics.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../core/theme/ec_type.dart';
import 'ec_glass.dart';

/// Chromatic Obsidian component kit.
///
/// Reusable primitives the redesigned screens compose:
/// • [EcAdherenceArc]  — full-width sweeping gold gauge (Today hero).
/// • [EcRingAvatar]    — adherence arc wrapped around initials/photo.
/// • [EcBentoTile]     — generic glass tile for bento grids.
/// • [EcBentoMetric]   — metric bento tile (icon, value, sparkline backdrop).
/// • [EcFrostedChip]   — micro-frost pill chip.
/// • [EcFloatingDock]  — Deep-Frost horizontal action dock.
/// • [EcGoldPulse]     — sin() opacity oscillation (active nav dot).
/// • [EcShimmerGoldBorder] — pulsing gold border (Ask Care AI tile).

// ─────────────────────────────────────────────────────── Arc gauge ──

/// A sweeping arc gauge painted in antique gold. Renders the arc only; callers
/// overlay their own number/label. Animates [progress] (0..1) on change.
class EcAdherenceArc extends StatelessWidget {
  const EcAdherenceArc({
    super.key,
    required this.progress,
    this.startAngle = math.pi,
    this.sweepAngle = math.pi,
    this.strokeWidth = 12,
    this.arcColor = EcTokens.accentGold,
    this.trackColorOverride,
    this.duration = const Duration(milliseconds: 900),
    this.horizon = false,
    this.child,
  });

  /// 0..1 adherence ratio.
  final double progress;

  /// Where the arc begins (radians, clockwise from +x). Default π = left.
  final double startAngle;

  /// How far it sweeps (radians). Default π = top semicircle.
  final double sweepAngle;
  final double strokeWidth;
  final Color arcColor;
  final Color? trackColorOverride;
  final Duration duration;

  /// When true, ignores [startAngle]/[sweepAngle] and paints a shallow,
  /// full-width sweep (a "horizon" arc) for the Today hero.
  final bool horizon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = trackColorOverride ??
        (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => CustomPaint(
        painter: _ArcPainter(
          progress: value,
          startAngle: startAngle,
          sweepAngle: sweepAngle,
          strokeWidth: strokeWidth,
          arcColor: arcColor,
          trackColor: track,
          horizon: horizon,
        ),
        child: child,
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.progress,
    required this.startAngle,
    required this.sweepAngle,
    required this.strokeWidth,
    required this.arcColor,
    required this.trackColor,
    this.horizon = false,
  });

  final double progress;
  final double startAngle;
  final double sweepAngle;
  final double strokeWidth;
  final Color arcColor;
  final Color trackColor;
  final bool horizon;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = strokeWidth / 2 + 2;

    late final Offset center;
    late final double radius;
    late final double effStart;
    late final double effSweep;

    if (horizon) {
      // Shallow, full-width sweep passing through the top-center apex and the
      // two bottom corners. Geometry: chord = width, sagitta = height.
      final a = size.width / 2 - pad; // half-chord
      final s = (size.height - 2 * pad).clamp(1.0, double.infinity); // sagitta
      radius = (a * a + s * s) / (2 * s);
      center = Offset(size.width / 2, pad + radius);
      final left = Offset(pad, size.height - pad);
      final right = Offset(size.width - pad, size.height - pad);
      effStart = math.atan2(left.dy - center.dy, left.dx - center.dx);
      final end = math.atan2(right.dy - center.dy, right.dx - center.dx);
      effSweep = end - effStart;
    } else {
      final isDome = (sweepAngle - math.pi).abs() < 0.01 &&
          (startAngle - math.pi).abs() < 0.01;
      radius = isDome
          ? math.min(size.width / 2 - pad, size.height - pad)
          : (math.min(size.width, size.height) / 2 - pad);
      center = isDome
          ? Offset(size.width / 2, size.height - pad)
          : Offset(size.width / 2, size.height / 2);
      effStart = startAngle;
      effSweep = sweepAngle;
    }

    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, effStart, effSweep, false, trackPaint);

    if (progress <= 0) return;

    final sweep = effSweep * progress;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: effStart,
        endAngle: effStart + effSweep,
        colors: [
          arcColor.withValues(alpha: 0.65),
          arcColor,
          arcColor.withValues(alpha: 0.85),
        ],
        stops: const [0.0, 0.6, 1.0],
        transform: GradientRotation(effStart),
      ).createShader(rect);
    canvas.drawArc(rect, effStart, sweep, false, arcPaint);

    // Soft luminous cap at the leading edge.
    final tip = effStart + sweep;
    final tipOffset = Offset(
      center.dx + radius * math.cos(tip),
      center.dy + radius * math.sin(tip),
    );
    canvas.drawCircle(
      tipOffset,
      strokeWidth * 0.62,
      Paint()
        ..color = arcColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress ||
      old.arcColor != arcColor ||
      old.sweepAngle != sweepAngle ||
      old.startAngle != startAngle ||
      old.horizon != horizon;
}

// ─────────────────────────────────────────────────────── Ring avatar ──

/// Circular adherence ring wrapped around a user's initials or photo —
/// the health score literally surrounds the person.
class EcRingAvatar extends StatelessWidget {
  const EcRingAvatar({
    super.key,
    required this.initials,
    required this.progress,
    this.size = 88,
    this.ringWidth = 5,
    this.ringColor = EcTokens.accentGold,
    this.imageProvider,
  });

  final String initials;
  final double progress;
  final double size;
  final double ringWidth;
  final Color ringColor;
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inner = size - ringWidth * 2 - 6;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          EcAdherenceArc(
            progress: progress,
            startAngle: -math.pi / 2,
            sweepAngle: math.pi * 2,
            strokeWidth: ringWidth,
            arcColor: ringColor,
          ),
          Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? EcTokens.surfaceL2Dark
                  : Colors.white,
              image: imageProvider != null
                  ? DecorationImage(image: imageProvider!, fit: BoxFit.cover)
                  : null,
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.04),
              ),
            ),
            alignment: Alignment.center,
            child: imageProvider != null
                ? null
                : Text(
                    initials,
                    style: EcType.display(
                      color: isDark
                          ? EcTokens.textPrimaryDark
                          : EcTokens.textPrimaryLight,
                      size: inner * 0.34,
                      weight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Bento tiles ──

/// Generic glass bento tile. Fills its parent's constraints (use inside sized
/// slots in a bento layout). [accent] tints the shadow/glow subtly.
class EcBentoTile extends StatelessWidget {
  const EcBentoTile({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.variant = EcGlassVariant.regular,
    this.tint,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EcGlassVariant variant;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return EcGlassSurface(
      onTap: onTap,
      variant: variant,
      tint: tint,
      borderRadius: EcTokens.radiusCard,
      padding: padding,
      child: SizedBox.expand(
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    );
  }
}

/// Metric bento tile: category icon + label header, large display value,
/// optional unit, optional sparkline backdrop (a flat zero line when empty so
/// the space reads as designed, not blank).
class EcBentoMetric extends StatelessWidget {
  const EcBentoMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.accent = EcTokens.accentJade,
    this.spark,
    this.onTap,
    this.valueSize = 32,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Color accent;
  final Widget? spark;
  final VoidCallback? onTap;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight;

    return EcGlassSurface(
      onTap: onTap,
      variant: EcGlassVariant.regular,
      borderRadius: EcTokens.radiusCard,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          if (spark != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(child: spark!),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: ec.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: EcType.metric(color: primary, size: valueSize)),
                  if (unit != null) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        unit!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ec.textMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Frosted chip ──

/// Micro-frost pill chip — e.g. `💊 0 meds`. Full-pill radius, subtle glass.
class EcFrostedChip extends StatelessWidget {
  const EcFrostedChip({
    super.key,
    required this.label,
    this.emoji,
    this.icon,
    this.accent,
    this.onTap,
  });

  final String label;
  final String? emoji;
  final IconData? icon;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final primary = Theme.of(context).brightness == Brightness.dark
        ? EcTokens.textPrimaryDark
        : EcTokens.textPrimaryLight;
    return EcGlassSurface(
      onTap: onTap,
      variant: EcGlassVariant.subtle,
      borderRadius: EcTokens.radiusFull,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 7),
          ] else if (icon != null) ...[
            Icon(icon, size: 15, color: accent ?? ec.textSecondary),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Floating dock ──

class EcDockAction {
  const EcDockAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// A horizontal Deep-Frost glass dock of icon actions — pin above the nav.
class EcFloatingDock extends StatelessWidget {
  const EcFloatingDock({super.key, required this.actions});

  final List<EcDockAction> actions;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return EcGlassSurface(
      variant: EcGlassVariant.float,
      borderRadius: EcTokens.radiusFull,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final a in actions)
            Expanded(
              child: _DockButton(action: a, color: ec.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({required this.action, required this.color});

  final EcDockAction action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          EcHaptics.lightTap();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(EcTokens.radiusFull),
        splashColor: EcTokens.accentGold.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Motion bits ──

/// Subtle opacity oscillation between [min] and [max] using a sine wave.
/// Honors reduced-motion (holds at [max]). Used on the active nav dot.
class EcGoldPulse extends StatefulWidget {
  const EcGoldPulse({
    super.key,
    required this.child,
    this.min = 0.6,
    this.max = 1.0,
    this.period = const Duration(seconds: 2),
  });

  final Widget child;
  final double min;
  final double max;
  final Duration period;

  @override
  State<EcGoldPulse> createState() => _EcGoldPulseState();
}

class _EcGoldPulseState extends State<EcGoldPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return Opacity(opacity: widget.max, child: widget.child);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi);
        return Opacity(
          opacity: widget.min + (widget.max - widget.min) * t,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A gold border that gently pulses every [period] — the Ask Care AI tile.
class EcShimmerGoldBorder extends StatefulWidget {
  const EcShimmerGoldBorder({
    super.key,
    required this.child,
    this.borderRadius = EcTokens.radiusCard,
    this.period = const Duration(seconds: 4),
  });

  final Widget child;
  final double borderRadius;
  final Duration period;

  @override
  State<EcShimmerGoldBorder> createState() => _EcShimmerGoldBorderState();
}

class _EcShimmerGoldBorderState extends State<EcShimmerGoldBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = reduced ? 0.5 : 0.5 + 0.5 * math.sin(_c.value * 2 * math.pi);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: EcTokens.accentGold.withValues(alpha: 0.25 + 0.45 * t),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: EcTokens.accentGold.withValues(alpha: 0.05 + 0.10 * t),
                blurRadius: 24,
                spreadRadius: -6,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
