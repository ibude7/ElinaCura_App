import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';

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
      borderRadius: EcTokens.radiusGlass,
      child: child,
    );
  }
}

class EcPill extends StatelessWidget {
  const EcPill({
    super.key,
    required this.label,
    this.tone = EcPillTone.neutral,
  });

  final String label;
  final EcPillTone tone;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final (bg, fg) = switch (tone) {
      EcPillTone.critical => (ec.accentBlushFill, ec.textCritical),
      EcPillTone.caution => (ec.accentAmberFill, ec.accentAmberText),
      EcPillTone.positive => (ec.accentMintFill, ec.accentMintText),
      EcPillTone.info => (ec.accentSkyFill, EcTokens.accentSkyText),
      EcPillTone.neutral => (ec.bgRecessed.withValues(alpha: 0.5), ec.textSecondary),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(EcTokens.radiusHero),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(EcTokens.radiusHero),
            border: Border.all(color: EcGlass.of(context).border.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

enum EcPillTone { neutral, critical, caution, positive, info }

class EcStat extends StatelessWidget {
  const EcStat({super.key, required this.label, required this.value, this.subtitle});

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: ec.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
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
          Text(subtitle!, style: TextStyle(color: ec.textSecondary, fontSize: 11)),
        ],
      ],
    );
  }
}

class EcSkeleton extends StatelessWidget {
  const EcSkeleton({super.key, this.height = 16, this.width, this.radius = 8});

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
              Icon(Icons.cloud_off_rounded, size: 48, color: ec.textMuted),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              EcGlassButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: onRetry),
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
    return EcGlassSurface(
      variant: EcGlassVariant.subtle,
      borderRadius: EcTokens.radiusSm,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.all(12),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text('You are offline. Showing cached data.')),
        ],
      ),
    );
  }
}

class EcSectionTitle extends StatelessWidget {
  const EcSectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

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
    final glass = EcGlass.of(context);
    return AppBar(
      automaticallyImplyLeading: showBack,
      title: Text(title),
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: EcTokens.glassBlurLight, sigmaY: EcTokens.glassBlurLight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: glass.navFill.withValues(alpha: 0.55),
              border: Border(bottom: BorderSide(color: glass.border.withValues(alpha: 0.6))),
            ),
          ),
        ),
      ),
      actions: [
        ...?actions,
        if (showEmergency)
          IconButton(
            icon: const Icon(Icons.emergency_rounded, color: EcTokens.statusCritical),
            tooltip: 'Emergency',
            onPressed: () => context.push('/emergency'),
          ),
      ],
    );
  }
}
