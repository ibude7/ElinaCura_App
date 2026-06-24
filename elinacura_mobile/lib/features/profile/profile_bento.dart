import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/design_system/ec_haptics.dart';
import '../../core/health/dose_log.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../core/theme/ec_type.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_obsidian_kit.dart';

String _initials(String? name) {
  if (name == null || name.trim().isEmpty) return 'You';
  final parts = name.trim().split(RegExp(r'\s+'));
  final a = parts.first.isNotEmpty ? parts.first[0] : '';
  final b = parts.length > 1 && parts.last.isNotEmpty
      ? parts.last[0]
      : (parts.first.length > 1 ? parts.first[1] : '');
  return (a + b).toUpperCase();
}

/// Profile body — ring-avatar header (adherence wrapped around initials) above
/// a bento grid of feature blocks, with a red-tinted Emergency ID at the base.
class ProfileBentoBody extends ConsumerWidget {
  const ProfileBentoBody({
    super.key,
    required this.profile,
    required this.hasProfile,
  });

  final HealthProfile? profile;
  final bool hasProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    final overview = ref.watch(healthOverviewProvider).valueOrNull;
    final meds = overview?.medications ?? const [];
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
    final adherence = computeAdherence(log, meds);
    final progress = adherence.hasSchedule ? adherence.todayRatio : 0.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, kEcNavBottomPadding),
      children: [
        if (!hasProfile) ...[
          _CreateProfileCard(l10n: l10n),
          const SizedBox(height: 20),
        ],
        _ProfileHeader(
          profile: profile,
          progress: progress,
          adherence: adherence,
        ),
        const SizedBox(height: 26),
        _ProfileBento(profile: profile, medCount: meds.length),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.progress,
    required this.adherence,
  });

  final HealthProfile? profile;
  final double progress;
  final AdherenceData adherence;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final percent = adherence.hasSchedule ? adherence.todayPercent : 0;
    return Row(
      children: [
        EcRingAvatar(
          initials: _initials(profile?.name),
          progress: progress,
          size: 92,
          ringWidth: 5,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.name ?? 'Your Profile',
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                profile?.email ?? 'Complete your care profile',
                style: TextStyle(color: ec.textSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.shield_moon_rounded,
                      size: 14, color: EcTokens.accentGold),
                  const SizedBox(width: 5),
                  Text(
                    adherence.hasSchedule
                        ? '$percent% adherence today'
                        : 'No schedule yet',
                    style: EcType.mono(color: ec.textMuted, size: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileBento extends StatelessWidget {
  const _ProfileBento({required this.profile, required this.medCount});

  final HealthProfile? profile;
  final int medCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileBlock(
          icon: Icons.medication_rounded,
          title: 'Medications & reminders',
          subtitle: profile == null
              ? 'Not set up yet'
              : '$medCount tracked',
          color: EcTokens.accentGold,
          large: true,
          animatedPill: true,
          onTap: () => context.push('/reminders'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ProfileBlock(
                  icon: Icons.people_rounded,
                  title: 'Family circle',
                  subtitle: 'Members & moments',
                  color: EcTokens.accentJade,
                  onTap: () => context.push('/family-circle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileBlock(
                  icon: Icons.link_rounded,
                  title: 'Connections',
                  subtitle: 'Caregiver access',
                  color: EcTokens.accentJade,
                  onTap: () => context.push('/connections'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ProfileBlock(
                  icon: Icons.apps_rounded,
                  title: 'More tools',
                  subtitle: 'Chat, meals, travel',
                  color: EcTokens.accentJade,
                  onTap: () => context.push('/more'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileBlock(
                  icon: Icons.verified_user_rounded,
                  title: 'Trust Center',
                  subtitle: 'Privacy & data',
                  color: EcTokens.accentJade,
                  onTap: () => context.push('/trust-center'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ProfileBlock(
          icon: Icons.settings_rounded,
          title: 'Settings',
          subtitle: 'Theme, account, privacy',
          color: EcTokens.accentJade,
          onTap: () => context.push('/settings'),
        ),
        const SizedBox(height: 12),
        _ProfileBlock(
          icon: Icons.emergency_rounded,
          title: 'Emergency ID',
          subtitle: 'Medical ID & emergency contacts',
          color: EcTokens.statusCritical,
          tinted: true,
          onTap: () => context.push('/emergency'),
        ),
      ],
    );
  }
}

class _ProfileBlock extends StatelessWidget {
  const _ProfileBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.large = false,
    this.tinted = false,
    this.animatedPill = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool large;
  final bool tinted;
  final bool animatedPill;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight;

    Widget iconBadge = Container(
      width: large ? 52 : 40,
      height: large ? 52 : 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
      ),
      child: Icon(icon, color: color, size: large ? 26 : 20),
    );
    if (animatedPill) {
      iconBadge = iconBadge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1, end: 1.08, duration: 1500.ms, curve: Curves.easeInOut);
    }

    final titleStyle = TextStyle(
      fontSize: large ? 17 : 14,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: primary,
    );
    final subStyle = TextStyle(fontSize: 12, color: ec.textSecondary);

    final child = large
        ? Row(
            children: [
              iconBadge,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: titleStyle),
                    const SizedBox(height: 3),
                    Text(subtitle, style: subStyle),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ec.textMuted),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              iconBadge,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: subStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          );

    return EcGlassSurface(
      onTap: () {
        EcHaptics.lightTap();
        onTap();
      },
      variant: tinted
          ? EcGlassVariant.tinted
          : (large ? EcGlassVariant.elevated : EcGlassVariant.regular),
      tint: tinted ? EcTokens.statusCritical : null,
      borderRadius: EcTokens.radiusCard,
      padding: EdgeInsets.all(large ? 20 : 16),
      child: child,
    );
  }
}

class _CreateProfileCard extends StatelessWidget {
  const _CreateProfileCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return EcGlassSurface(
      variant: EcGlassVariant.float,
      borderRadius: EcTokens.radiusHero,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileCreateHeading,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileCreateLead,
            style: TextStyle(
              color: EcColors.of(context).textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          EcGlassButton(
            label: l10n.profileCreateSubmit,
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.push('/profile/create'),
          ),
        ],
      ),
    );
  }
}
