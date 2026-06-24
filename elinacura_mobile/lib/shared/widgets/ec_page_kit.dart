import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';
import 'ec_widgets.dart';

/// Feature-domain accent palette for page identity (data glyphs only).
enum EcAccent { mint, sky, amber, blush, lavender, brand }

extension EcAccentColors on EcAccent {
  Color fill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      EcAccent.mint => EcTokens.categoryNutrition.withValues(alpha: isDark ? 0.22 : 0.14),
      EcAccent.sky => EcTokens.categoryActivity.withValues(alpha: isDark ? 0.22 : 0.14),
      EcAccent.amber => EcTokens.statusCaution.withValues(alpha: isDark ? 0.22 : 0.14),
      EcAccent.blush => EcTokens.statusCritical.withValues(alpha: isDark ? 0.18 : 0.12),
      EcAccent.lavender => EcTokens.categorySleep.withValues(alpha: isDark ? 0.22 : 0.14),
      EcAccent.brand => EcColors.of(context).accentBrand.withValues(alpha: 0.14),
    };
  }

  Color icon(BuildContext context) => switch (this) {
        EcAccent.mint => EcTokens.categoryNutrition,
        EcAccent.sky => EcTokens.categoryActivity,
        EcAccent.amber => EcTokens.statusCaution,
        EcAccent.blush => EcTokens.statusCritical,
        EcAccent.lavender => EcTokens.categorySleep,
        EcAccent.brand => EcColors.of(context).accentBrand,
      };

  Color? wash(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return null;
    return switch (this) {
      EcAccent.mint => EcTokens.washNutrition,
      EcAccent.sky => EcTokens.washActivity,
      EcAccent.amber => EcTokens.washCaution,
      EcAccent.blush => EcTokens.washHeart,
      EcAccent.lavender => EcTokens.washSleep,
      EcAccent.brand => null,
    };
  }
}

/// Rounded-square icon tile — signature ElinaCura page identity mark.
class EcMedallion extends StatelessWidget {
  const EcMedallion({
    super.key,
    required this.icon,
    this.accent = EcAccent.brand,
    this.size = 48,
  });

  final IconData icon;
  final EcAccent accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = accent.icon(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        color: accent.fill(context),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

/// Hero stat chip for page headers.
class EcHeroStat extends StatelessWidget {
  const EcHeroStat({
    super.key,
    required this.label,
    required this.value,
    this.tone = EcPillTone.neutral,
  });

  final String label;
  final String value;
  final EcPillTone tone;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: ec.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontFamily: EcTokens.fontFamily,
          ),
        ),
        const SizedBox(height: 4),
        EcPill(label: label, tone: tone),
      ],
    );
  }
}

/// Standard page hero — eyebrow, headline, optional stats, liquid glass band.
class EcPageHero extends StatelessWidget {
  const EcPageHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accent = EcAccent.brand,
    this.trailing,
    this.stats = const [],
    this.layer = EcSurfaceLayer.liquidGlass,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final EcAccent accent;
  final Widget? trailing;
  final List<Widget> stats;
  final EcSurfaceLayer layer;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EcMedallion(icon: icon, accent: accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: ec.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: ec.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(children: stats),
        ],
      ],
    );

    return switch (layer) {
      EcSurfaceLayer.liquidGlass => EcGlassSurface(
          variant: EcGlassVariant.elevated,
          borderRadius: EcTokens.radiusGlass,
          categoryFill: accent.wash(context),
          tint: accent.icon(context),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      EcSurfaceLayer.solidContent => EcCard(
          elevated: true,
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      EcSurfaceLayer.voidCanvas => child,
    };
  }
}

/// Accessible ring progress arc.
class EcRingProgress extends StatelessWidget {
  const EcRingProgress({
    super.key,
    required this.value,
    required this.label,
    this.size = 88,
    this.color,
    this.trackColor,
  });

  final double value;
  final String label;
  final double size;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final stroke = color ?? ec.accentBrand;
    final track = trackColor ?? ec.textMuted.withValues(alpha: 0.14);
    final clamped = value.clamp(0.0, 1.0);

    return Semantics(
      label: '$label ${(clamped * 100).round()} percent',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                value: clamped,
                stroke: stroke,
                track: track,
                strokeWidth: size * 0.09,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(clamped * 100).round()}',
                  style: TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    fontFamily: EcTokens.fontFamily,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: ec.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.track,
    required this.strokeWidth,
  });

  final double value;
  final Color stroke;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.stroke != stroke;
}

/// Horizontal KPI strip — tap scrolls to in-page anchor.
class EcGlanceStrip extends StatelessWidget {
  const EcGlanceStrip({
    super.key,
    required this.items,
  });

  final List<EcGlanceItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          return EcGlassSurface(
            onTap: item.onTap,
            variant: EcGlassVariant.regular,
            borderRadius: EcTokens.radiusCard,
            categoryFill: item.fillColor,
            tint: item.color,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: SizedBox(
              width: 118,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 18, color: item.color),
                  const Spacer(),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: EcColors.of(context).textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class EcGlanceItem {
  const EcGlanceItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fillColor,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? fillColor;
  final VoidCallback? onTap;
}

/// Material layer in the three-layer void / content / glass model.
enum EcSurfaceLayer { voidCanvas, solidContent, liquidGlass }

/// Groups liquid-glass siblings for morph/blend (nav + quick-add).
class EcLiquidGlassGroup extends StatelessWidget {
  const EcLiquidGlassGroup({
    super.key,
    required this.spacing,
    required this.children,
  });

  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(EcTokens.radiusFull),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            children[i],
          ],
        ],
      ),
    );
  }
}
