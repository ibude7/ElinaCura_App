import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';

// ─────────────────────────────────────────────────────── Core glass card ──

class EcCard extends StatelessWidget {
  const EcCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.variant = EcGlassVariant.regular,
    this.elevated = false,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final EcGlassVariant variant;
  final bool elevated;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return EcGlassSurface(
      onTap: onTap,
      padding: padding,
      margin: margin,
      tint: tint,
      variant: elevated ? EcGlassVariant.elevated : variant,
      borderRadius: elevated ? EcTokens.radiusGlass : EcTokens.radiusCard,
      child: child,
    );
  }
}

// ───────────────────────────────────────────────────────────── Status pill ──

enum EcPillTone { neutral, critical, caution, positive, info }

class EcPill extends StatelessWidget {
  const EcPill({
    super.key,
    required this.label,
    this.tone = EcPillTone.neutral,
    this.icon,
  });

  final String label;
  final EcPillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bg, fg) = switch (tone) {
      EcPillTone.critical => (
        ec.accentBlushFill.withValues(alpha: isDark ? 0.22 : 0.90),
        ec.textCritical,
      ),
      EcPillTone.caution => (
        ec.accentAmberFill.withValues(alpha: isDark ? 0.22 : 0.90),
        ec.accentAmberText,
      ),
      EcPillTone.positive => (
        ec.accentMintFill.withValues(alpha: isDark ? 0.22 : 0.90),
        ec.accentMintText,
      ),
      EcPillTone.info => (
        ec.accentSkyFill.withValues(alpha: isDark ? 0.22 : 0.90),
        EcTokens.accentSkyText,
      ),
      EcPillTone.neutral => (
        Colors.white.withValues(alpha: isDark ? 0.08 : 0.60),
        ec.textSecondary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(EcTokens.radiusFull),
        border: Border.all(
          color: fg.withValues(alpha: isDark ? 0.18 : 0.14),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────── Clock hero (Dashboard) ──

/// Large time + greeting display for the Dashboard hero.
class EcClockHero extends StatefulWidget {
  const EcClockHero({
    super.key,
    required this.greeting,
    required this.date,
    this.onEmergency,
  });

  final String greeting;
  final String date;
  final VoidCallback? onEmergency;

  @override
  State<EcClockHero> createState() => _EcClockHeroState();
}

class _EcClockHeroState extends State<EcClockHero> {
  late String _time = _formatTime(DateTime.now());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tick on a steady cadence but only rebuild when the visible minute
    // actually changes — far cheaper than a per-second setState loop, and
    // it stops cleanly when the widget leaves the tree.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = _formatTime(DateTime.now());
      if (next != _time) setState(() => _time = next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.paddingOf(context).top;
    final textColor = isDark ? Colors.white : EcTokens.textPrimaryLight;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row + emergency
          Row(
            children: [
              Text(
                widget.date.toUpperCase(),
                style: TextStyle(
                  color: ec.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontFamily: EcTokens.fontFamily,
                ),
              ),
              const Spacer(),
              if (widget.onEmergency != null)
                _EmergencyBadge(onTap: widget.onEmergency!),
            ],
          ),
          const SizedBox(height: 6),
          // Clock
          Text(
            _time,
            style: TextStyle(
              fontSize: EcTokens.fontSizeDisplayXL,
              fontWeight: FontWeight.w800,
              letterSpacing: EcTokens.letterSpacingDisplayXL,
              color: textColor,
              height: 0.92,
              fontFamily: EcTokens.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          // Greeting
          Text(
            widget.greeting,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: textColor.withValues(alpha: 0.80),
              fontFamily: EcTokens.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyBadge extends StatelessWidget {
  const _EmergencyBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Emergency SOS',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: EcTokens.statusCritical.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(EcTokens.radiusFull),
            border: Border.all(
              color: EcTokens.statusCritical.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.emergency_rounded,
                  color: EcTokens.statusCritical, size: 14),
              SizedBox(width: 5),
              Text(
                'SOS',
                style: TextStyle(
                  color: EcTokens.statusCritical,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontFamily: EcTokens.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────── Medication pill card ──

/// Horizontal-scroll glass card for a single medication in the Dashboard rail.
class EcMedPillCard extends StatelessWidget {
  const EcMedPillCard({
    super.key,
    required this.name,
    required this.dose,
    required this.timeLabel,
    this.taken = false,
    this.onTap,
  });

  final String name;
  final String dose;
  final String timeLabel;
  final bool taken;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = taken ? ec.accentMint : ec.accentBrand;

    return EcGlassSurface(
      onTap: onTap,
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusCard,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    taken
                        ? Icons.check_circle_rounded
                        : Icons.medication_rounded,
                    color: accentColor,
                    size: 17,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: isDark ? 0.07 : 0.50,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    timeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ec.textMuted,
                      fontFamily: EcTokens.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              dose,
              style: TextStyle(
                fontSize: 11.5,
                color: ec.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────── Timeline node ──

/// A single event in a vertical care-rhythm timeline.
class EcTimelineNode extends StatelessWidget {
  const EcTimelineNode({
    super.key,
    required this.time,
    required this.label,
    required this.done,
    this.isLast = false,
    this.onTap,
  });

  final String time;
  final String label;
  final bool done;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final dotColor = done ? ec.accentMint : ec.textMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor.withValues(alpha: done ? 0.16 : 0.10),
                    border: Border.all(color: dotColor, width: 1.5),
                  ),
                  child: done
                      ? Icon(Icons.check_rounded, size: 10, color: dotColor)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: ec.textMuted.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: ec.textMuted,
                        letterSpacing: 0.5,
                        fontFamily: EcTokens.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: done ? FontWeight.w500 : FontWeight.w600,
                        color: done
                            ? ec.textSecondary
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: ec.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────── Health ring ──

/// Circular arc ring showing a health score / adherence percentage.
/// Painted as a solid arc — no gradient fill.
class EcHealthRing extends StatelessWidget {
  const EcHealthRing({
    super.key,
    required this.score,
    this.size = 180,
    this.label = 'Score',
    this.accentColor,
  });

  /// 0.0 – 1.0
  final double score;
  final double size;
  final String label;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final color = accentColor ?? ec.accentBrand;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              score: score,
              color: color,
              trackColor: color.withValues(alpha: 0.12),
              strokeWidth: size * 0.065,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(score * 100).round()}',
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  fontFamily: EcTokens.fontFamily,
                ),
              ),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.075,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: ec.textMuted,
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

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.score,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double score;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;
    const fullSweep = 2 * math.pi;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Arc (solid color, no gradient)
    if (score > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        fullSweep * score.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.score != score || old.color != color;
}

// ──────────────────────────────────────────────────── Glass ID card ──

/// Glass identity card for the Profile screen.
class EcGlassIDCard extends StatelessWidget {
  const EcGlassIDCard({
    super.key,
    required this.name,
    this.subtitle,
    this.bloodType,
    this.initials,
    this.trailing,
  });

  final String name;
  final String? subtitle;
  final String? bloodType;
  final String? initials;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ec.accentBrand.withValues(alpha: 0.14),
              border: Border.all(
                color: ec.accentBrand.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                initials ?? _initials(name),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ec.accentBrand,
                  fontFamily: EcTokens.fontFamily,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: ec.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          // Blood type badge
          if (bloodType != null) ...[
            const SizedBox(width: 12),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: EcTokens.statusCritical.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: EcTokens.statusCritical.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    bloodType!,
                    style: const TextStyle(
                      color: EcTokens.statusCritical,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: EcTokens.fontFamily,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Blood',
                  style: TextStyle(
                    fontSize: 9,
                    color: ec.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontFamily: EcTokens.fontFamily,
                  ),
                ),
              ],
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ──────────────────────────────────────────────────── Progress bar ──

/// Solid-fill progress bar (no gradient) for goals and adherence.
class EcGlassProgressBar extends StatelessWidget {
  const EcGlassProgressBar({
    super.key,
    required this.value,
    required this.label,
    this.valueLabel,
    this.color,
  });

  /// 0.0 – 1.0
  final double value;
  final String label;
  final String? valueLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final fillColor = color ?? ec.accentBrand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              valueLabel ?? '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fillColor,
                fontFamily: EcTokens.fontFamily,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(EcTokens.radiusFull),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: fillColor.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(fillColor),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────── Stat / metric ──

class EcStat extends StatelessWidget {
  const EcStat({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: ec.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            fontFamily: EcTokens.fontFamily,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(color: ec.textSecondary, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

/// Glass stat tile — used in metric strips.
class EcMetricTile extends StatelessWidget {
  const EcMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = EcPillTone.neutral,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final EcPillTone tone;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (iconBg, iconFg) = switch (tone) {
      EcPillTone.critical => (
        EcTokens.statusCritical.withValues(alpha: isDark ? 0.16 : 0.10),
        EcTokens.statusCritical,
      ),
      EcPillTone.caution => (
        ec.accentAmberFill.withValues(alpha: isDark ? 0.22 : 0.90),
        ec.accentAmberText,
      ),
      EcPillTone.positive => (
        ec.accentMintFill.withValues(alpha: isDark ? 0.22 : 0.90),
        ec.accentMintText,
      ),
      EcPillTone.info => (
        ec.accentSkyFill.withValues(alpha: isDark ? 0.22 : 0.90),
        EcTokens.accentSkyText,
      ),
      EcPillTone.neutral => (
        Colors.white.withValues(alpha: isDark ? 0.07 : 0.40),
        ec.textSecondary,
      ),
    };

    return EcCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: iconBg,
            ),
            child: Icon(icon, color: iconFg, size: 18),
          ),
          const SizedBox(height: 12),
          EcStat(label: label, value: value, subtitle: subtitle),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────── Section title ──

class EcSectionTitle extends StatelessWidget {
  const EcSectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: ec.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontFamily: EcTokens.fontFamily,
            ),
          ),
          const Spacer(),
          ?action,
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────── Legacy screen hero ──

/// Legacy hero card — kept for screens not yet migrated to new layout.
class EcScreenHero extends StatelessWidget {
  const EcScreenHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accent,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final color = accent ?? ec.accentBrand;
    return EcCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withValues(alpha: 0.14),
                  border: Border.all(color: color.withValues(alpha: 0.20)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontFamily: EcTokens.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: ec.textSecondary,
              fontSize: 14,
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────── Loading / state ──

class EcSkeleton extends StatelessWidget {
  const EcSkeleton({super.key, this.height = 16, this.width, this.radius = 10});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return EcGlassSurface(
      variant: EcGlassVariant.subtle,
      borderRadius: radius,
      padding: EdgeInsets.zero,
      child: SizedBox(height: height, width: width),
    );
  }
}

class EcErrorState extends StatelessWidget {
  const EcErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: EcGlassSurface(
          variant: EcGlassVariant.elevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ec.accentAmberFill.withValues(alpha: 0.20),
                ),
                child: Icon(Icons.cloud_off_rounded,
                    size: 28, color: ec.accentAmberText),
              ),
              const SizedBox(height: 16),
              Text('Something needs attention',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: ec.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 20),
              EcGlassButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class EcEmptyState extends StatelessWidget {
  const EcEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: EcCard(
          elevated: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ec.accentMintFill.withValues(alpha: 0.22),
                ),
                child: Icon(icon, color: ec.accentMintText, size: 26),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: ec.textSecondary, height: 1.45),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class EcOfflineBanner extends StatelessWidget {
  const EcOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return EcGlassSurface(
      variant: EcGlassVariant.subtle,
      borderRadius: EcTokens.radiusSm,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: ec.accentAmberText),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'You are offline. Showing cached data.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass app bar for pushed (full-screen) routes.
class EcAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EcAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showEmergency = true,
    this.showBack = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool showEmergency;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      title: Text(title),
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: EcTokens.glassBlurZ3,
            sigmaY: EcTokens.glassBlurZ3,
          ),
          child: DecoratedBox(decoration: _headerDecoration(context)),
        ),
      ),
      actions: [
        ...?actions,
        if (showEmergency)
          IconButton(
            icon: const Icon(
              Icons.emergency_rounded,
              color: EcTokens.statusCritical,
            ),
            tooltip: 'Emergency',
            onPressed: () => context.push('/emergency'),
          ),
      ],
    );
  }
}

BoxDecoration _headerDecoration(BuildContext context) {
  final glass = EcGlass.of(context);
  return BoxDecoration(
    color: glass.navFill,
    border: Border(
      bottom: BorderSide(color: glass.border),
    ),
  );
}
