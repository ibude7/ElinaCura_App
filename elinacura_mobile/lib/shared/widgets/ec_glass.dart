import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/ec_a11y.dart';
import '../../core/theme/ec_perf.dart';
import '../../core/theme/ec_tokens.dart';
import '../../core/theme/ec_theme.dart';

// ─────────────────────────────────────────────────────── Background system ──

/// App-wide canvas — a solid, neutral near-black (dark) or paper (light)
/// surface with a single colorless light highlight painted in
/// [EcDepthScenePainter]. Glass surfaces BackdropFilter this neutral canvas;
/// there are no colored ambient blobs. The glass itself stays achromatic.
///
/// Use this for all post-auth screens.
class EcVoidBackground extends StatelessWidget {
  const EcVoidBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? EcTokens.bgVoid : EcTokens.bgVoidLight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: EcDepthScenePainter(isDark: isDark),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Paints a single colorless light highlight + a soft vignette.
/// Monochrome only — premium depth comes from luminance, never hue.
class EcDepthScenePainter extends CustomPainter {
  const EcDepthScenePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft color washes — Google Health airy canvas (light mode only).
    if (!isDark) {
      final washes = [
        (Offset(w * 0.12, h * 0.08), EcTokens.categoryActivityLight, 0.55),
        (Offset(w * 0.88, h * 0.18), EcTokens.categorySleepLight, 0.45),
        (Offset(w * 0.72, h * 0.92), EcTokens.categoryNutritionLight, 0.35),
      ];
      for (final wsh in washes) {
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              wsh.$2.withValues(alpha: wsh.$3),
              wsh.$2.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: wsh.$1, radius: w * 0.55));
        canvas.drawRect(Offset.zero & size, paint);
      }
    }

    // A single, colorless top-center highlight gives floating glass something
    // neutral to refract. No hues anywhere.
    final highlight = Paint()
      ..blendMode = isDark ? BlendMode.plus : BlendMode.srcOver
      ..shader = RadialGradient(
        colors: [
          (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isDark ? 0.05 : 0.035),
          (isDark ? Colors.white : Colors.black).withValues(alpha: 0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(w * 0.5, h * -0.04), radius: w * 1.05),
      );
    canvas.drawRect(Offset.zero & size, highlight);

    // Subtle bottom vignette seats content and adds gravity (monochrome).
    final vignette = Paint()
      ..shader = LinearGradient(
        begin: Alignment.center,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(EcDepthScenePainter old) => old.isDark != isDark;
}

/// Legacy background kept for onboarding / auth screens. Do not use post-auth.
class EcLiquidBackground extends StatelessWidget {
  const EcLiquidBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => EcVoidBackground(child: child);
}

/// @deprecated Use [EcVoidBackground] for post-auth screens. Onboarding only.
@Deprecated('Use EcVoidBackground — aurora violates solid void canvas rule')
class EcAuroraBackground extends StatefulWidget {
  const EcAuroraBackground({
    super.key,
    required this.child,
    this.colors,
    this.intensity = 1.0,
    this.scrim = true,
  });

  final Widget child;
  final List<Color>? colors;
  final double intensity;
  final bool scrim;

  @override
  State<EcAuroraBackground> createState() => _EcAuroraBackgroundState();
}

class _EcAuroraBackgroundState extends State<EcAuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = widget.colors ??
        const [
          EcTokens.auroraViolet,
          EcTokens.auroraIndigo,
          EcTokens.auroraDeep,
        ];
    return ColoredBox(
      color: isDark ? EcTokens.bgVoid : EcTokens.bgVoidLight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: EcAuroraPainter(
                    t: _controller.value,
                    isDark: isDark,
                    colors: palette,
                    intensity: widget.intensity * (isDark ? 0.62 : 0.5),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Paints soft, luminous aurora orbs. Used by [EcAuroraBackground].
class EcAuroraPainter extends CustomPainter {
  const EcAuroraPainter({
    required this.t,
    required this.isDark,
    required this.colors,
    this.intensity = 0.5,
    this.pan = 0,
  });

  final double t;
  final bool isDark;
  final List<Color> colors;
  final double intensity;
  final double pan;

  static const _orbs = <List<double>>[
    [0.84, 0.04, 1.05, 0.06, 0, 0.0],
    [0.10, 0.26, 0.92, 0.05, 1, 1.7],
    [0.50, 0.96, 1.15, 0.04, 2, 3.1],
    [0.94, 0.62, 0.74, 0.05, 0, 4.6],
    [0.06, 0.80, 0.70, 0.06, 1, 2.3],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final blend = isDark ? BlendMode.plus : BlendMode.srcOver;
    final baseAlpha = intensity * (isDark ? 0.85 : 0.66);

    for (var i = 0; i < _orbs.length; i++) {
      final o = _orbs[i];
      final phase = (t * 2 * math.pi) + o[5];
      final parallax = pan * w * (0.05 + 0.03 * (i.isEven ? 1 : -1));
      final cx = (o[0] + o[3] * math.sin(phase)) * w - parallax;
      final cy = (o[1] + o[3] * 0.8 * math.cos(phase * 0.85)) * h;
      final radius = o[2] * w * 0.66 * (1 + 0.05 * math.sin(phase * 1.3));
      final color = colors[o[4].toInt() % colors.length];
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      final paint = Paint()
        ..blendMode = blend
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: baseAlpha),
            color.withValues(alpha: baseAlpha * 0.35),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EcAuroraPainter old) =>
      old.t != t ||
      old.isDark != isDark ||
      old.intensity != intensity ||
      old.pan != pan ||
      old.colors != colors;
}

// ─────────────────────────────────────────────────────── Glass surfaces ──

enum EcGlassVariant { regular, elevated, tinted, subtle, float }

/// Neutral frosted glass surface with specular edge highlights and depth shadow.
///
/// Glass is intentionally colorless — its appearance is determined by the
/// ambient depth blobs painted behind it via [EcVoidBackground]. The [tint]
/// param adds a very subtle semantic color overlay (e.g. sent messages).
///
/// Rec #2: specular rim + press states via [onTap].
/// Rec #47: solid fallback when reduced transparency is preferred.
class EcGlassSurface extends StatefulWidget {
  const EcGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = EcTokens.radiusLg,
    this.blur = EcTokens.glassBlur,
    this.onTap,
    this.variant = EcGlassVariant.regular,
    this.tint,
    this.categoryFill,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final VoidCallback? onTap;
  final EcGlassVariant variant;
  final Color? tint;
  /// Pastel card wash (Google Health metric tiles). Light mode only.
  final Color? categoryFill;

  @override
  State<EcGlassSurface> createState() => _EcGlassSurfaceState();
}

class _EcGlassSurfaceState extends State<EcGlassSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glass = EcGlass.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reducedGlass = EcA11y.prefersReducedTransparency(context);
    final scale = _pressed && widget.onTap != null ? 0.985 : 1.0;

    final (fill, effectiveBlur) = switch (widget.variant) {
      EcGlassVariant.elevated => (glass.fillElevated, EcTokens.glassBlurZ3),
      EcGlassVariant.float => (glass.fillFloat, EcTokens.glassBlurZ4),
      EcGlassVariant.subtle => (glass.fillSubtle, EcTokens.glassBlurZ2 * 0.6),
      EcGlassVariant.tinted => (
        (widget.tint ?? glass.tintBrand).withValues(
          alpha: isDark ? 0.16 : 0.12,
        ),
        EcTokens.glassBlurZ2,
      ),
      EcGlassVariant.regular => (glass.fill, widget.blur),
    };

    final isElevated = widget.variant == EcGlassVariant.elevated ||
        widget.variant == EcGlassVariant.float;
    final borderRadius = widget.borderRadius;
    final padding = widget.padding ?? const EdgeInsets.all(16);
    final margin = widget.margin;

    final shadowSoft = isDark ? 0.28 : 0.10;
    final shadowStrong = isDark ? 0.46 : 0.14;
    final cardColor = widget.categoryFill ??
        (isDark ? fill : EcTokens.bgCardLight);
    final shadowHue = widget.tint ??
        widget.categoryFill ??
        glass.shadowColor;

    Widget surface;
    if (reducedGlass || !isDark) {
      surface = Container(
        margin: margin,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isDark ? glass.border : glass.border.withValues(alpha: 0.9),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowHue.withValues(
                alpha: isElevated ? shadowStrong : shadowSoft,
              ),
              blurRadius: isElevated ? 28 : 16,
              spreadRadius: 0,
              offset: Offset(0, isElevated ? 10 : 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: widget.child),
        ),
      );
    } else {
      final blurSigma = EcPerf.blurSigma(context, effectiveBlur);
      if (blurSigma <= 0) {
        surface = Container(
          margin: margin,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: glass.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: glass.shadowColor.withValues(
                  alpha: isElevated ? shadowSoft : shadowSoft * 0.65,
                ),
                blurRadius: isElevated ? 20 : 12,
                offset: Offset(0, isElevated ? 8 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(padding: padding, child: widget.child),
          ),
        );
      } else {
        surface = Container(
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: glass.shadowColor.withValues(
                  alpha: isElevated ? shadowStrong : shadowSoft,
                ),
                blurRadius: isElevated ? 44 : 22,
                spreadRadius: isElevated ? -14 : -6,
                offset: Offset(0, isElevated ? 24 : 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: EcA11y.glassHairline(context),
                  color: fill,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 1,
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(borderRadius),
                            topRight: Radius.circular(borderRadius),
                          ),
                          child: ColoredBox(color: glass.specularTop),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 0.5,
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(borderRadius),
                            bottomLeft: Radius.circular(borderRadius),
                          ),
                          child: ColoredBox(color: glass.specularSide),
                        ),
                      ),
                    ),
                    Padding(padding: padding, child: widget.child),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    if (widget.onTap != null) {
      surface = GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.white.withValues(alpha: 0.04),
            child: surface,
          ),
        ),
      );
    }

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: surface,
    );
  }
}

// ─────────────────────────────────────────────────────── Navigation ──

/// Navigation destination descriptor for [EcFloatingNav].
class EcGlassNavDestination {
  const EcGlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.accent = EcTokens.categoryActivity,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color accent;
}

/// Floating glass pill navigation bar — detached from screen edges.
///
/// Renders 4 tab destinations with a spring-animated solid-white indicator.
/// An elevated glass orb + button sits centered above the pill for quick-add.
///
/// Use with [EcGlassScaffold] `extendBody: true` so scroll content slides
/// underneath. Each screen is responsible for its own bottom scroll padding
/// via [kEcNavBottomPadding].
class EcFloatingNav extends StatelessWidget {
  const EcFloatingNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    this.onAdd,
    this.onAddLongPress,
    this.compressLabels = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<EcGlassNavDestination> destinations;
  final VoidCallback? onAdd;
  final VoidCallback? onAddLongPress;
  final bool compressLabels;

  static const double _pillHeight = 64.0;
  static const double _orbDiameter = 52.0;
  static const double _orbRise = 18.0; // how far orb sits above pill top

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hasAdd = onAdd != null;
    final totalHeight = _pillHeight + bottom + 16 + (hasAdd ? _orbRise : 0);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glass pill
          Positioned(
            left: 24,
            right: 24,
            bottom: bottom + 12,
            height: _pillHeight,
            child: _FloatingPill(
              selectedIndex: selectedIndex,
              onSelected: onSelected,
              destinations: destinations,
              compressLabels: compressLabels,
            ),
          ),
          // + orb
          if (hasAdd)
            Positioned(
              bottom: bottom + 12 + _pillHeight - (_orbDiameter / 2) + _orbRise,
              left: 0,
              right: 0,
              child: Center(
                child: _AddOrb(onTap: onAdd!, onLongPress: onAddLongPress),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingPill extends StatelessWidget {
  const _FloatingPill({
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    this.compressLabels = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<EcGlassNavDestination> destinations;
  final bool compressLabels;

  @override
  Widget build(BuildContext context) {
    final glass = EcGlass.of(context);
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(EcTokens.radiusGlass),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: EcTokens.glassBlurZ4,
          sigmaY: EcTokens.glassBlurZ4,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: glass.fillFloat,
            borderRadius: BorderRadius.circular(EcTokens.radiusGlass),
            border: Border.all(color: glass.borderStrong, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.50 : 0.14),
                blurRadius: 40,
                spreadRadius: -8,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Specular top edge
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(EcTokens.radiusGlass),
                    topRight: Radius.circular(EcTokens.radiusGlass),
                  ),
                  child: ColoredBox(color: glass.specularTop),
                ),
              ),
              // Tab items
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth =
                      constraints.maxWidth / destinations.length;
                  return SizedBox(
                    height: double.infinity,
                    child: Stack(
                      children: [
                        // Animated indicator capsule (solid white, no gradient)
                        AnimatedPositioned(
                          duration: EcTokens.motionBase,
                          curve: Curves.easeOutBack,
                          left: itemWidth * selectedIndex + 8,
                          width: itemWidth - 16,
                          top: 8,
                          bottom: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(EcTokens.radiusXl),
                              color: destinations[selectedIndex].accent
                                  .withValues(alpha: isDark ? 0.22 : 0.16),
                              border: Border.all(
                                color: destinations[selectedIndex].accent
                                    .withValues(alpha: 0.28),
                                width: 0.6,
                              ),
                            ),
                          ),
                        ),
                        // Tab items
                        Row(
                          children: List.generate(destinations.length, (i) {
                            final d = destinations[i];
                            final selected = i == selectedIndex;
                            return Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => onSelected(i),
                                  borderRadius: BorderRadius.circular(
                                    EcTokens.radiusXl,
                                  ),
                                  splashColor:
                                      Colors.white.withValues(alpha: 0.06),
                                  highlightColor: Colors.transparent,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: EcTokens.motionFast,
                                        child: Icon(
                                          selected
                                              ? d.selectedIcon
                                              : d.icon,
                                          key: ValueKey(selected),
                                          size: selected ? 24 : 22,
                                          color: selected
                                              ? destinations[i].accent
                                              : ec.textMuted,
                                        ),
                                      ),
                                      if (!compressLabels) ...[
                                        const SizedBox(height: 3),
                                        AnimatedDefaultTextStyle(
                                          duration: EcTokens.motionFast,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: selected
                                                ? destinations[i].accent
                                                : ec.textMuted,
                                            letterSpacing: -0.1,
                                            fontFamily: EcTokens.fontFamily,
                                          ),
                                          child: Text(d.label),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOrb extends StatelessWidget {
  const _AddOrb({required this.onTap, this.onLongPress});

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  static const double _size = EcFloatingNav._orbDiameter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onAccent = isDark ? EcTokens.onAccentDark : EcTokens.onAccentLight;

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: EcTokens.categoryActivity.withValues(alpha: isDark ? 0.50 : 0.35),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: EcTokens.glassBlurZ4,
            sigmaY: EcTokens.glassBlurZ4,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              splashColor: Colors.white.withValues(alpha: 0.18),
              highlightColor: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EcTokens.categoryActivity,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                    width: 1.2,
                  ),
                ),
                child: Semantics(
                  button: true,
                  label: 'Quick add',
                  child: Icon(
                    Icons.add_rounded,
                    color: onAccent,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Legacy bottom nav — preserved for caregiver shell (3 tabs, no add button).
/// For the patient shell, prefer [EcFloatingNav].
class EcGlassBottomNav extends StatelessWidget {
  const EcGlassBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<EcGlassNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return EcFloatingNav(
      selectedIndex: selectedIndex,
      onSelected: onSelected,
      destinations: destinations,
    );
  }
}

// ─────────────────────────────────────────────────── Layout scaffolds ──

bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// Standard padding at the top of a tab-page list.
const kEcGlassTabPadding = EdgeInsets.fromLTRB(16, 8, 16, 16);

/// Standard padding for full-screen scrollable lists (accounts for floating nav).
const kEcGlassListPadding = EdgeInsets.fromLTRB(16, 8, 16, 24);

/// Bottom clearance for the floating nav (use as ListView bottom padding).
const kEcNavBottomPadding = 104.0;

/// Scaffold with transparent background. Set [extendBody] true when using
/// [EcFloatingNav] so content scrolls behind the nav.
class EcGlassScaffold extends StatelessWidget {
  const EcGlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Header for full-screen pushed routes (not tabs).
class EcGlassHeader extends StatelessWidget {
  const EcGlassHeader({
    super.key,
    required this.title,
    this.actions,
    this.showEmergency = true,
    this.showBack = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool showEmergency;
  final bool showBack;

  static double heightOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + kToolbarHeight;

  @override
  Widget build(BuildContext context) {
    final glass = EcGlass.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: glass.navFill,
        border: Border(
          bottom: BorderSide(color: glass.border),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: EcTokens.glassBlurZ3,
            sigmaY: EcTokens.glassBlurZ3,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: top),
            child: SizedBox(
              height: kToolbarHeight + 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: NavigationToolbar(
                  leading: showBack
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => Navigator.maybePop(context),
                        )
                      : const SizedBox(width: 8),
                  middle: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: Theme.of(context).appBarTheme.titleTextStyle ??
                          Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...?actions,
                      if (showEmergency)
                        IconButton.filledTonal(
                          icon: const Icon(
                            Icons.emergency_rounded,
                            color: EcTokens.statusCritical,
                          ),
                          tooltip: 'Emergency',
                          onPressed: () => context.push('/emergency'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tab content wrapper — headerless for new immersive screens.
/// Screens manage their own header treatment inline.
class EcTabPage extends StatelessWidget {
  const EcTabPage({
    super.key,
    required this.title,
    required this.body,
    this.showEmergency = true,
  });

  final String title;
  final Widget body;
  final bool showEmergency;

  @override
  Widget build(BuildContext context) {
    return body;
  }
}

// ─────────────────────────────────────────────── Buttons & interactive ──

/// Primary CTA — solid brand fill, no gradient.
class EcGlassButton extends StatelessWidget {
  const EcGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onAccent = isDark ? EcTokens.onAccentDark : EcTokens.onAccentLight;
    final radius = BorderRadius.circular(EcTokens.radiusMd);
    final fill = isDark ? EcColors.of(context).accentBrand : EcTokens.categoryActivity;

    if (outlined) {
      return EcGlassSurface(
        onTap: onPressed,
        variant: EcGlassVariant.subtle,
        borderRadius: EcTokens.radiusMd,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: radius,
        splashColor: Colors.white.withValues(alpha: 0.18),
        highlightColor: Colors.transparent,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: fill,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: fill.withValues(alpha: 0.32),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: onAccent,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: onAccent, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: onAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Large solid-color CTA — used for primary actions on onboarding/auth.
/// Kept for backward compatibility with auth screens.
class EcGradientButton extends StatefulWidget {
  const EcGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.gradient,
    this.glow,
    this.height = 60,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final List<Color>? gradient;
  final Color? glow;
  final double height;
  final bool loading;

  @override
  State<EcGradientButton> createState() => _EcGradientButtonState();
}

class _EcGradientButtonState extends State<EcGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  )..repeat();
  bool _pressed = false;

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onAccent = isDark ? EcTokens.onAccentDark : EcTokens.onAccentLight;
    // Use solid brand color — no gradient fill — for the "gradient" button.
    final primaryColor = ec.accentBrand;
    final glowColor = widget.glow ?? primaryColor;
    final radius = BorderRadius.circular(EcTokens.radiusLg);

    return AnimatedScale(
      scale: _pressed ? 0.975 : 1,
      duration: EcTokens.motionFast,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: EcTokens.motionBase,
        curve: EcTokens.curveEmphasized,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.42),
              blurRadius: 40,
              spreadRadius: -8,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: glowColor.withValues(alpha: 0.20),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.loading ? null : widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: radius,
            splashColor: Colors.white.withValues(alpha: 0.14),
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: primaryColor,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.26),
                  width: 1.2,
                ),
              ),
              child: SizedBox(
                height: widget.height,
                width: double.infinity,
                child: Center(
                  child: widget.loading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: onAccent,
                          ),
                        )
                      : Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 18),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.label,
                                  style: TextStyle(
                                    color: onAccent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (widget.icon != null) ...[
                                  const SizedBox(width: 10),
                                  Icon(widget.icon,
                                      color: onAccent, size: 20),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass action chip for quick horizontal actions.
class EcGlassChip extends StatelessWidget {
  const EcGlassChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final color = tint ?? ec.accentBrand;
    return EcGlassSurface(
      onTap: onTap,
      variant: EcGlassVariant.regular,
      borderRadius: EcTokens.radiusHero,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Critical-action button (e.g. Call 911).
class EcGlassDangerButton extends StatelessWidget {
  const EcGlassDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.phone_rounded,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(EcTokens.radiusLg),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EcTokens.radiusLg),
            color: EcTokens.statusCritical,
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: EcTokens.statusCritical.withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// FAB — solid brand circle.
class EcGlassFab extends StatelessWidget {
  const EcGlassFab({super.key, required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onAccent = isDark ? EcTokens.onAccentDark : EcTokens.onAccentLight;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ec.accentBrand.withValues(alpha: 0.38),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: ec.accentBrand,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(icon, color: onAccent, size: 27),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────── Motion / utility ──

/// Staggered fade/slide entrance for glass lists.
class EcGlassEntrance extends StatelessWidget {
  const EcGlassEntrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(
          duration: 320.ms,
          delay: (EcTokens.staggerItem.inMilliseconds * index).ms,
        )
        .slideY(
          begin: 0.05,
          end: 0,
          curve: Curves.easeOutCubic,
          delay: (EcTokens.staggerItem.inMilliseconds * index).ms,
        );
  }
}

/// Glass menu row — profile, settings, more screens.
class EcGlassListTile extends StatelessWidget {
  const EcGlassListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
    this.grouped = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;
  /// When true, renders only the row — parent [EcGlassListGroup] supplies the shell.
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    if (grouped) {
      return _EcGlassListRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        iconColor: iconColor,
        onTap: onTap,
      );
    }
    return EcGlassSurface(
      variant: EcGlassVariant.subtle,
      borderRadius: EcTokens.radiusCard,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: _EcGlassListRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        iconColor: iconColor,
        onTap: onTap,
      ),
    );
  }
}

/// Multiple list rows inside one frosted shell — cleaner than stacked cards.
class EcGlassListGroup extends StatelessWidget {
  const EcGlassListGroup({
    super.key,
    required this.tiles,
    this.variant = EcGlassVariant.elevated,
  });

  final List<EcGlassListTile> tiles;
  final EcGlassVariant variant;

  @override
  Widget build(BuildContext context) {
    final glass = EcGlass.of(context);
    return EcGlassSurface(
      variant: variant,
      borderRadius: EcTokens.radiusGlass,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 68,
                color: glass.border,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: EcGlassListTile(
                icon: tiles[i].icon,
                title: tiles[i].title,
                subtitle: tiles[i].subtitle,
                trailing: tiles[i].trailing,
                iconColor: tiles[i].iconColor,
                onTap: tiles[i].onTap,
                grouped: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EcGlassListRow extends StatelessWidget {
  const _EcGlassListRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ??
        (isDark ? ec.accentBrand : EcTokens.categoryActivity);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EcTokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: isDark ? 0.18 : 0.20),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: ec.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right_rounded, color: ec.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted nav bar wrapper (legacy — for non-floating usage).
class EcGlassNavBar extends StatelessWidget {
  const EcGlassNavBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = EcGlass.of(context);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: EcTokens.glassBlurZ4,
          sigmaY: EcTokens.glassBlurZ4,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: glass.navFill,
            border: Border(top: BorderSide(color: glass.border)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glass-styled alert dialog.
Future<T?> showEcGlassDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget>? actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: EcGlassSurface(
        variant: EcGlassVariant.elevated,
        borderRadius: EcTokens.radiusGlass,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            content,
            if (actions != null) ...[
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Frosted modal bottom sheet.
Future<T?> showEcGlassSheet<T>(
  BuildContext context, {
  required List<Widget> children,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: EcGlassSurface(
          variant: EcGlassVariant.float,
          borderRadius: EcTokens.radiusHero,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: EcGlass.of(ctx).border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ...children,
              ],
            ),
          ),
        ),
      );
    },
  );
}
