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
      borderRadius: elevated ? EcTokens.radiusGlass : EcTokens.radiusHero,
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
      EcPillTone.neutral => (
        ec.bgRecessed.withValues(alpha: 0.5),
        ec.textSecondary,
      ),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(EcTokens.radiusHero),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(EcTokens.radiusHero),
            border: Border.all(
              color: EcGlass.of(context).border.withValues(alpha: 0.62),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

enum EcPillTone { neutral, critical, caution, positive, info }

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: color.withValues(alpha: 0.14),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 7),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: ec.textSecondary,
              fontSize: 14.5,
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final (bg, fg) = switch (tone) {
      EcPillTone.critical => (ec.accentBlushFill, ec.textCritical),
      EcPillTone.caution => (ec.accentAmberFill, ec.accentAmberText),
      EcPillTone.positive => (ec.accentMintFill, ec.accentMintText),
      EcPillTone.info => (ec.accentSkyFill, EcTokens.accentSkyText),
      EcPillTone.neutral => (
        ec.bgRecessed.withValues(alpha: 0.56),
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
              borderRadius: BorderRadius.circular(13),
              color: bg,
            ),
            child: Icon(icon, color: fg, size: 19),
          ),
          const SizedBox(height: 12),
          EcStat(label: label, value: value, subtitle: subtitle),
        ],
      ),
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ec.accentAmberFill,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 30,
                  color: ec.accentAmberText,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Something needs attention',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                onPressed: onRetry,
              ),
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
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ec.accentMintFill,
                ),
                child: Icon(icon, color: ec.accentMintText, size: 28),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          ?action,
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
    return AppBar(
      automaticallyImplyLeading: showBack,
      title: Text(title),
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: EcTokens.glassBlurLight,
            sigmaY: EcTokens.glassBlurLight,
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
  final dark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: glass.navFill.withValues(alpha: dark ? 0.88 : 0.76),
    border: Border(
      bottom: BorderSide(color: glass.border.withValues(alpha: 0.55)),
    ),
  );
}
