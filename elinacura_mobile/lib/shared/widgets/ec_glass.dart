import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/ec_tokens.dart';
import '../../core/theme/ec_theme.dart';

/// App-wide premium backdrop — a deep indigo "aurora" in dark mode and an airy,
/// cool light field in light mode. Static and inexpensive so it can sit behind
/// every screen; use the animated [EcAuroraBackground] for hero surfaces such
/// as onboarding and auth.
class EcLiquidBackground extends StatelessWidget {
  const EcLiquidBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? EcTokens.bgRampDark : EcTokens.bgRampLight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                painter: EcAuroraPainter(
                  t: 0.16,
                  isDark: isDark,
                  colors: const [
                    EcTokens.auroraViolet,
                    EcTokens.auroraIndigo,
                    EcTokens.auroraDeep,
                  ],
                  intensity: isDark ? 0.5 : 0.4,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Animated liquid-aurora background for hero surfaces (onboarding / auth).
///
/// Slowly drifts several luminous orbs over the base field. Pass [colors] to
/// tint the aurora to a feature's palette; the orbs cross-fade when [colors]
/// changes, so callers can shift the mood per page.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? EcTokens.bgRampDark : EcTokens.bgRampLight,
        ),
      ),
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
          if (widget.scrim)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              const Color(0xFF05060D).withValues(alpha: 0.0),
                              const Color(0xFF05060D).withValues(alpha: 0.35),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.22),
                            ],
                      stops: const [0.55, 1.0],
                    ),
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

/// Paints soft, luminous aurora orbs. Reused by the static backdrop and the
/// animated [EcAuroraBackground].
class EcAuroraPainter extends CustomPainter {
  const EcAuroraPainter({
    required this.t,
    required this.isDark,
    required this.colors,
    this.intensity = 0.5,
    this.pan = 0,
  });

  /// Looping phase in 0..1.
  final double t;
  final bool isDark;
  final List<Color> colors;
  final double intensity;

  /// Horizontal parallax in "page" units; orbs pan as the user advances.
  final double pan;

  // Relative center (x, y), radius factor, drift amount, color index, phase.
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
      // Each orb pans a slightly different amount → layered depth as you swipe.
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

enum EcGlassVariant { regular, elevated, tinted, subtle }

/// Frosted glass surface with specular border and depth shadow.
class EcGlassSurface extends StatelessWidget {
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
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final VoidCallback? onTap;
  final EcGlassVariant variant;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final glass = EcGlass.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fill = switch (variant) {
      EcGlassVariant.elevated => glass.fillElevated,
      EcGlassVariant.tinted => (tint ?? glass.tintBrand).withValues(
        alpha: isDark ? 0.18 : 0.14,
      ),
      EcGlassVariant.subtle => glass.fillSubtle,
      EcGlassVariant.regular => glass.fill,
    };

    final isElevated = variant == EcGlassVariant.elevated;
    final shadowOpacity = isElevated
        ? (isDark ? 0.42 : 0.20)
        : (isDark ? 0.24 : 0.12);

    Widget surface = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glass.shadowColor.withValues(alpha: shadowOpacity),
            blurRadius: isElevated ? 40 : 22,
            spreadRadius: isElevated ? -12 : -8,
            offset: Offset(0, isElevated ? 22 : 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: glass.border, width: 1),
              color: fill,
            ),
            child: Stack(
              children: [
                // Specular sheen — a soft top-left highlight that reads as a
                // light catch on the glass.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            glass.highlight
                                .withValues(alpha: isDark ? 0.10 : 0.45),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: glass.tintBrand.withValues(alpha: 0.12),
          highlightColor: glass.tintBrand.withValues(alpha: 0.06),
          child: surface,
        ),
      );
    }

    return surface;
  }
}

/// Frosted top bar — use inside tab pages or via [EcAppBar] on full screens.
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
        color: glass.navFill.withValues(alpha: isDark(context) ? 0.84 : 0.72),
        border: Border(
          bottom: BorderSide(color: glass.border.withValues(alpha: 0.55)),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: EcTokens.glassBlurLight,
            sigmaY: EcTokens.glassBlurLight,
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
                      style:
                          Theme.of(context).appBarTheme.titleTextStyle ??
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

bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// Tab content below the shell nav — no nested scaffold.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EcGlassHeader(title: title, showEmergency: showEmergency),
        Expanded(child: body),
      ],
    );
  }
}

/// Scaffold with liquid background and optional frosted app bar slot.
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

/// Frosted bottom navigation bar wrapper.
class EcGlassNavBar extends StatelessWidget {
  const EcGlassNavBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = EcGlass.of(context);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: EcTokens.glassBlurHeavy,
          sigmaY: EcTokens.glassBlurHeavy,
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

/// Premium glass FAB with solid brand fill.
class EcGlassFab extends StatelessWidget {
  const EcGlassFab({super.key, required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ec.accentBrand.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Ink(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ec.accentBrand,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass action chip for quick actions.
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
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
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

/// Primary CTA with glass sheen overlay.
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
    final ec = EcColors.of(context);
    final radius = BorderRadius.circular(EcTokens.radiusMd);

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
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
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
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: ec.accentBrand,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: ec.accentBrand.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
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

/// Premium gradient call-to-action — refined single-hue fill, soft outer glow,
/// a glass rim, a slow specular light-sweep and tactile press feedback. The
/// hero button of the design language.
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
    final colors = widget.gradient ?? EcTokens.gradientBrand;
    final glowColor = widget.glow ?? colors[colors.length ~/ 2];
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
              color: glowColor.withValues(alpha: 0.46),
              blurRadius: 40,
              spreadRadius: -8,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: glowColor.withValues(alpha: 0.22),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.26),
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: SizedBox(
                  height: widget.height,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // top sheen
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: widget.height * 0.5,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // slow specular light-sweep
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _sweep,
                            builder: (context, _) => LayoutBuilder(
                              builder: (context, c) {
                                final w = c.maxWidth;
                                final x = (-0.4 + 1.8 * _sweep.value) * w;
                                return Stack(
                                  children: [
                                    Positioned(
                                      left: x,
                                      top: 0,
                                      bottom: 0,
                                      width: w * 0.16,
                                      child: Transform.rotate(
                                        angle: 0.38,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withValues(alpha: 0),
                                                Colors.white.withValues(alpha: 0.20),
                                                Colors.white.withValues(alpha: 0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: widget.loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      if (widget.icon != null) ...[
                                        const SizedBox(width: 10),
                                        Icon(widget.icon,
                                            color: Colors.white, size: 20),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
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

/// Glass menu row used across profile, settings, and more screens.
class EcGlassListTile extends StatelessWidget {
  const EcGlassListTile({
    super.key,
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
    return EcGlassSurface(
      onTap: onTap,
      variant: EcGlassVariant.regular,
      borderRadius: EcTokens.radiusHero,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: (iconColor ?? ec.accentBrand).withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: iconColor ?? ec.accentBrand, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(color: ec.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, color: ec.textMuted),
        ],
      ),
    );
  }
}

/// Navigation destination for [EcGlassBottomNav].
class EcGlassNavDestination {
  const EcGlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Custom bottom nav with animated glass pill indicator.
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
    final ec = EcColors.of(context);
    final glass = EcGlass.of(context);

    return EcGlassNavBar(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / destinations.length;
              return SizedBox(
                height: 66,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositioned(
                      duration: EcTokens.motionBase,
                      curve: Curves.easeOutCubic,
                      left: itemWidth * selectedIndex + 6,
                      width: itemWidth - 12,
                      top: 4,
                      bottom: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: ec.accentBrand.withValues(alpha: 0.14),
                          border: Border.all(
                            color: glass.border.withValues(alpha: 0.7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ec.accentBrand.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(destinations.length, (i) {
                        final d = destinations[i];
                        final selected = i == selectedIndex;
                        return Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onSelected(i),
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedSwitcher(
                                    duration: EcTokens.motionFast,
                                    child: Icon(
                                      selected ? d.selectedIcon : d.icon,
                                      key: ValueKey(selected),
                                      size: selected ? 25 : 23,
                                      color: selected
                                          ? ec.accentBrand
                                          : ec.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: EcTokens.motionFast,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? ec.accentBrand
                                          : ec.textMuted,
                                      letterSpacing: -0.1,
                                    ),
                                    child: Text(d.label),
                                  ),
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
        ),
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
                color: EcTokens.statusCritical.withValues(alpha: 0.35),
                blurRadius: 24,
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

/// Standard scroll padding above bottom nav.
const kEcGlassListPadding = EdgeInsets.fromLTRB(16, 8, 16, 24);

/// List padding for screens inside the bottom tab shell (nav is outside).
const kEcGlassTabPadding = EdgeInsets.fromLTRB(16, 12, 16, 16);

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
          variant: EcGlassVariant.elevated,
          borderRadius: EcTokens.radiusHero,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
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
