import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/ec_tokens.dart';
import '../../core/theme/ec_theme.dart';

/// Clean, refined app backdrop — a soft neutral gradient with a gentle top
/// sheen for depth. No animated colour orbs, so glass and 3D surfaces read
/// calm and premium.
class EcLiquidBackground extends StatelessWidget {
  const EcLiquidBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.55, 1.0],
              colors: isDark
                  ? const [Color(0xFF0C1118), Color(0xFF080B11), Color(0xFF05070B)]
                  : const [Color(0xFFF7F4EF), Color(0xFFEFEBE3), Color(0xFFE7E2D9)],
            ),
          ),
        ),
        // Soft top sheen — adds quiet depth without any colour cast.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -1.05),
              radius: 1.25,
              stops: const [0.0, 0.65],
              colors: isDark
                  ? [Colors.white.withValues(alpha: 0.045), Colors.white.withValues(alpha: 0)]
                  : [Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0)],
            ),
          ),
        ),
        child,
      ],
    );
  }
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
      EcGlassVariant.tinted => (tint ?? glass.tintBrand).withValues(alpha: isDark ? 0.18 : 0.14),
      EcGlassVariant.subtle => glass.fillSubtle,
      EcGlassVariant.regular => glass.fill,
    };

    final shadowOpacity = variant == EcGlassVariant.elevated
        ? (isDark ? 0.45 : 0.10)
        : (isDark ? 0.30 : 0.06);

    Widget surface = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: variant == EcGlassVariant.elevated ? 32 : 20,
            offset: Offset(0, variant == EcGlassVariant.elevated ? 12 : 6),
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
              border: Border.all(color: glass.border, width: 1.2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  fill,
                  Color.alphaBlend(
                    isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.08),
                    fill,
                  ),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          glass.highlight,
                          Colors.transparent,
                        ],
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

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: EcTokens.glassBlurLight, sigmaY: EcTokens.glassBlurLight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: glass.navFill.withValues(alpha: 0.55),
            border: Border(bottom: BorderSide(color: glass.border.withValues(alpha: 0.6))),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: top),
            child: SizedBox(
              height: kToolbarHeight,
              child: NavigationToolbar(
                leading: showBack
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.maybePop(context),
                      )
                    : const SizedBox(width: 8),
                middle: Text(
                  title,
                  style: Theme.of(context).appBarTheme.titleTextStyle ??
                      Theme.of(context).textTheme.titleLarge,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...?actions,
                    if (showEmergency)
                      IconButton(
                        icon: const Icon(Icons.emergency_rounded, color: EcTokens.statusCritical),
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
    );
  }
}

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
        filter: ImageFilter.blur(sigmaX: EcTokens.glassBlurHeavy, sigmaY: EcTokens.glassBlurHeavy),
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

/// Premium glass FAB with brand gradient core.
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ec.accentBrand,
                      Color.lerp(ec.accentBrand, Colors.white, 0.15)!,
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
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
      variant: EcGlassVariant.subtle,
      borderRadius: EcTokens.radiusHero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 8)],
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ec.accentBrand, Color.lerp(ec.accentBrand, Colors.white, 0.12)!],
            ),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[Icon(icon, color: Colors.white, size: 22), const SizedBox(width: 8)],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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

/// Staggered fade/slide entrance for glass lists.
class EcGlassEntrance extends StatelessWidget {
  const EcGlassEntrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(duration: 320.ms, delay: (EcTokens.staggerItem.inMilliseconds * index).ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic, delay: (EcTokens.staggerItem.inMilliseconds * index).ms);
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
      variant: EcGlassVariant.subtle,
      borderRadius: EcTokens.radiusLg,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (iconColor ?? ec.accentBrand).withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: iconColor ?? ec.accentBrand, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(color: ec.textSecondary, fontSize: 12)),
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / destinations.length;
              return SizedBox(
                height: 64,
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
                          borderRadius: BorderRadius.circular(20),
                          color: ec.accentBrand.withValues(alpha: 0.14),
                          border: Border.all(color: glass.border.withValues(alpha: 0.7)),
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
                                      size: 24,
                                      color: selected ? ec.accentBrand : ec.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: EcTokens.motionFast,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      color: selected ? ec.accentBrand : ec.textMuted,
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDC2626), Color(0xFFBE123C)],
            ),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
Future<T?> showEcGlassSheet<T>(BuildContext context, {required List<Widget> children}) {
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
