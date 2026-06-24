import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/design_system/ec_copy.dart';
import '../../core/health/health_connect_service.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/health/vitals_store.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_screen_header.dart';
import '../../shared/widgets/ec_sparkline.dart';
import '../../shared/widgets/ec_widgets.dart';

// ═══════════════════════════════════════════════════════════ HEALTH SCREEN ══

/// Google-Health-style health dashboard: health-status badge, key-metrics
/// 2-column grid with sparkline cards, conditions, and goals.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    final vitals = ref.watch(vitalsProvider);
    final vitalsNotifier = ref.read(vitalsProvider.notifier);
    final top = MediaQuery.paddingOf(context).top;

    return overview.when(
      loading: () => _HealthSkeleton(top: top),
      error: (e, _) => Center(
        child: EcErrorState(
          message: formatApiError(e),
          onRetry: () => ref.read(healthOverviewProvider.notifier).retry(),
        ),
      ),
      data: (data) => _HealthContent(
        data: data,
        vitalsNotifier: vitalsNotifier,
        vitalsLoaded: vitals.valueOrNull != null,
      ),
    );
  }
}

class _HealthSkeleton extends StatelessWidget {
  const _HealthSkeleton({required this.top});
  final double top;

  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.fromLTRB(16, top + 16, 16, kEcNavBottomPadding),
        children: const [
          EcSkeleton(height: 72, radius: 22),
          SizedBox(height: 20),
          EcSkeleton(height: 16, radius: 8),
          SizedBox(height: 12),
          EcSkeleton(height: 160, radius: 20),
          SizedBox(height: 12),
          EcSkeleton(height: 160, radius: 20),
        ],
      );
}

class _HealthContent extends ConsumerWidget {
  const _HealthContent({
    required this.data,
    required this.vitalsNotifier,
    required this.vitalsLoaded,
  });

  final HealthOverview data;
  final VitalsNotifier vitalsNotifier;
  final bool vitalsLoaded;

  static const _displayTypes = [
    VitalType.heartRate,
    VitalType.bloodPressureSystolic,
    VitalType.bloodOxygen,
    VitalType.weight,
    VitalType.restingHR,
    VitalType.hrv,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    final ec = EcColors.of(context);
    final trackedCount = vitalsNotifier.trackedCount;

    return ListView(
          padding: EdgeInsets.fromLTRB(16, top + 16, 16, kEcNavBottomPadding),
          children: [
            // ── Header row
            EcScreenHeader(
              variant: EcHeaderVariant.tab,
              eyebrow: l10n.healthEyebrow,
              title: l10n.healthVitalsTitle,
              showBack: false,
              actions: [
                IconButton.filledTonal(
                  icon: const Icon(
                    Icons.emergency_rounded,
                    color: EcTokens.statusCritical,
                    size: 20,
                  ),
                  tooltip: l10n.healthEmergencyTooltip,
                  onPressed: () => context.push('/emergency'),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        EcTokens.statusCritical.withValues(alpha: 0.10),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 260.ms),
            const SizedBox(height: 16),

            // ── Health status badge (GH style)
            EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusCard,
              categoryFill: EcTokens.washHeart,
              tint: EcTokens.categoryHeart,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: trackedCount > 0
                          ? EcTokens.statusPositiveLight
                          : EcTokens.categoryActivityLight,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      trackedCount > 0
                          ? Icons.check_circle_rounded
                          : Icons.favorite_rounded,
                      color: trackedCount > 0
                          ? EcTokens.statusPositive
                          : EcTokens.categoryHeart,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.healthStatusTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          trackedCount == 0
                              ? l10n.healthNoVitals
                              : l10n.healthTrackedCount(
                                  trackedCount,
                                  _displayTypes.length,
                                ),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: ec.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trackedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: EcTokens.statusPositiveLight,
                        borderRadius: BorderRadius.circular(EcTokens.radiusFull),
                      ),
                      child: Text(
                        '$trackedCount / ${_displayTypes.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: EcTokens.statusPositive,
                          fontFamily: EcTokens.fontFamily,
                        ),
                      ),
                    ),
                ],
              ),
            ).animate().fadeIn(delay: 60.ms, duration: 260.ms),
            const SizedBox(height: 12),

            // ── Apple Health / Health Connect (Rec #44)
            EcGlassListTile(
              icon: Icons.favorite_rounded,
              title: l10n.healthConnectTitle,
              subtitle: EcCopy.healthConnect,
              onTap: () async {
                final ok = await ref
                    .read(healthConnectServiceProvider)
                    .requestAuthorization();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? l10n.healthConnected : l10n.healthConnectFailed,
                    ),
                  ),
                );
              },
            ),
            EcGlassListTile(
              icon: Icons.picture_as_pdf_rounded,
              title: l10n.healthClinicianReport,
              subtitle: EcCopy.clinicianShare,
              onTap: () => context.push('/report'),
            ),
            const SizedBox(height: 20),

            // ── Anomaly highlights (Rec #16)
            if (vitalsNotifier.anomalies.isNotEmpty) ...[
              Text(
                l10n.healthNeedsAttention,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: EcTokens.fontFamily,
                ),
              ),
              const SizedBox(height: 10),
              ...vitalsNotifier.anomalies.map(
                (a) => EcGlassListTile(
                  icon: Icons.flag_rounded,
                  title: a.title,
                  subtitle: a.detail,
                  iconColor: EcTokens.statusCaution,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Key metrics header
            Row(
              children: [
                Text(
                  l10n.healthKeyMetrics,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: EcTokens.fontFamily,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _logVitals(context, ref),
                  child: Text(l10n.healthLogButton),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── 2-column sparkline metric grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.90,
              ),
              itemCount: _displayTypes.length,
              itemBuilder: (context, i) {
                final type = _displayTypes[i];
                return EcGlassEntrance(
                  index: i,
                  child: EcSparklineCard(
                    type: type,
                    latestEntry: vitalsNotifier.latest(type),
                    sparkValues: vitalsNotifier
                        .lastN(type)
                        .map((e) => e.value)
                        .toList(),
                    onTap: () => _logSingleVital(context, ref, type),
                  ),
                );
              },
            ),

            // ── Conditions
            if (data.conditions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.healthConditionsTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: EcTokens.fontFamily,
                ),
              ),
              const SizedBox(height: 10),
              EcGlassSurface(
                variant: EcGlassVariant.elevated,
                borderRadius: EcTokens.radiusCard,
                categoryFill: EcTokens.washHeart,
                tint: EcTokens.categoryHeart,
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.conditions.map((c) {
                    final tone = switch (c.status.toLowerCase()) {
                      'managed' => EcPillTone.positive,
                      'monitoring' => EcPillTone.caution,
                      'active' => EcPillTone.info,
                      _ => EcPillTone.neutral,
                    };
                    return EcPill(label: c.name, tone: tone);
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 80.ms),
            ],
          ],
        );
  }

  Future<void> _logVitals(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<VitalType, double>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EcLogVitalsSheet(types: _displayTypes),
    );
    if (result == null || !context.mounted) return;
    final notifier = ref.read(vitalsProvider.notifier);
    for (final entry in result.entries) {
      await notifier.log(entry.key, entry.value);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${result.length} reading${result.length == 1 ? '' : 's'}')),
      );
    }
  }

  Future<void> _logSingleVital(
    BuildContext context,
    WidgetRef ref,
    VitalType type,
  ) async {
    final result = await showModalBottomSheet<Map<VitalType, double>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EcLogVitalsSheet(types: [type]),
    );
    if (result == null || !context.mounted) return;
    final notifier = ref.read(vitalsProvider.notifier);
    for (final entry in result.entries) {
      await notifier.log(entry.key, entry.value);
    }
  }
}

// ═══════════════════════════════════════════════════════════ PROFILE SCREEN ══

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    return overview.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: EcErrorState(
          message: formatApiError(e),
          onRetry: () => ref.read(healthOverviewProvider.notifier).retry(),
        ),
      ),
      data: (data) => _ProfileContent(
        profile: data.profile,
        hasProfile: data.hasProfile,
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({this.profile, required this.hasProfile});

  final HealthProfile? profile;
  final bool hasProfile;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final l10n = context.l10n;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, kEcNavBottomPadding),
      children: [
        if (!hasProfile) ...[
          EcGlassSurface(
            variant: EcGlassVariant.float,
            borderRadius: EcTokens.radiusHero,
            categoryFill: EcTokens.washRecovery,
            tint: EcTokens.categoryRecovery,
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
          ),
          const SizedBox(height: 20),
        ],
        // ── ID card
        EcGlassEntrance(
          index: 0,
          child: EcGlassIDCard(
            name: profile?.name ?? 'Your Profile',
            subtitle: profile?.email ??
                'Tap to complete your care profile',
            bloodType: profile?.bloodType,
            trailing: IconButton(
              icon: Icon(
                hasProfile ? Icons.edit_rounded : Icons.add_rounded,
                color: EcColors.of(context).accentBrand,
                size: 18,
              ),
              onPressed: () => context.push(
                hasProfile ? '/settings' : '/profile/create',
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Location / condition summary
        if (profile != null) ...[
          EcGlassEntrance(
            index: 1,
            child: _ProfileSummaryRow(profile: profile!),
          ),
          const SizedBox(height: 20),
        ],

        // ── Navigation tiles
        EcSectionTitle(title: 'Manage'),
        EcGlassEntrance(
          index: 2,
          child: EcGlassListGroup(
            tiles: [
              EcGlassListTile(
                icon: Icons.medication_rounded,
                title: 'Medications & reminders',
                subtitle: profile == null
                    ? 'Not set up'
                    : '${profile!.medications.length} medications tracked',
                iconColor: EcTokens.categoryNutrition,
                onTap: () => context.push('/reminders'),
              ),
              EcGlassListTile(
                icon: Icons.people_rounded,
                title: 'Family circle',
                subtitle: 'Members, moments, and privacy',
                onTap: () => context.push('/family-circle'),
              ),
              EcGlassListTile(
                icon: Icons.link_rounded,
                title: 'Connections',
                subtitle: 'Manage caregiver access',
                onTap: () => context.push('/connections'),
              ),
              EcGlassListTile(
                icon: Icons.emergency_rounded,
                title: 'Emergency ID',
                subtitle: 'Medical ID and emergency contacts',
                iconColor: EcTokens.statusCritical,
                onTap: () => context.push('/emergency'),
              ),
              EcGlassListTile(
                icon: Icons.verified_user_rounded,
                title: 'Trust Center',
                subtitle: EcCopy.trustCenter,
                onTap: () => context.push('/trust-center'),
              ),
              EcGlassListTile(
                icon: Icons.apps_rounded,
                title: 'More tools',
                subtitle: 'Chat, meals, travel, telehealth, and more',
                onTap: () => context.push('/more'),
              ),
              EcGlassListTile(
                icon: Icons.settings_rounded,
                title: 'Settings',
                subtitle: 'Theme, account, privacy',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSummaryRow extends StatelessWidget {
  const _ProfileSummaryRow({required this.profile});

  final HealthProfile profile;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final items = <_SummaryItem>[
      if (profile.conditions.isNotEmpty)
        _SummaryItem(
          icon: Icons.monitor_heart_rounded,
          label: '${profile.conditions.length} conditions',
          color: EcTokens.categoryActivity,
        ),
      if (profile.medications.isNotEmpty)
        _SummaryItem(
          icon: Icons.medication_rounded,
          label: '${profile.medications.length} meds',
          color: EcTokens.categoryNutrition,
        ),
      if (profile.allergies.isNotEmpty)
        _SummaryItem(
          icon: Icons.warning_amber_rounded,
          label: '${profile.allergies.length} allergies',
          color: ec.accentAmberText,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _SummaryChip(item: item),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return EcGlassSurface(
      variant: EcGlassVariant.regular,
      borderRadius: EcTokens.radiusCard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(item.icon, size: 15, color: item.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: item.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
