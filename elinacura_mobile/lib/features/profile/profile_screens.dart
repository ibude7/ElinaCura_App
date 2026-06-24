import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/health/vitals_store.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_sparkline.dart';
import '../../shared/widgets/ec_theme_picker.dart';
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
    final top = MediaQuery.paddingOf(context).top;
    final ec = EcColors.of(context);
    final trackedCount = vitalsNotifier.trackedCount;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(16, top + 16, 16, kEcNavBottomPadding + 72),
          children: [
            // ── Header row
            _HealthHeader(
              onLog: () => _logVitals(context, ref),
            ).animate().fadeIn(duration: 260.ms),
            const SizedBox(height: 16),

            // ── Health status badge (GH style)
            EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusCard,
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
                          'Health status',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          trackedCount == 0
                              ? 'No vitals logged yet'
                              : '$trackedCount of ${_displayTypes.length} vitals tracked',
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
            const SizedBox(height: 20),

            // ── Key metrics header
            Row(
              children: [
                Text(
                  'Key metrics',
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
                  child: const Text('+ Log'),
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
                'Conditions',
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
        ),

        // ── Floating log-vitals FAB
        Positioned(
          right: 16,
          bottom: kEcNavBottomPadding + 12,
          child: FloatingActionButton.extended(
            onPressed: () => _logVitals(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log vitals'),
          ).animate().fadeIn(delay: 200.ms),
        ),
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

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({required this.onLog});
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : EcTokens.textPrimaryLight;
    final ec = EcColors.of(context);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HEALTH',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: ec.textMuted,
                fontFamily: EcTokens.fontFamily,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Your vitals',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                color: textColor,
                fontFamily: EcTokens.fontFamily,
              ),
            ),
          ],
        ),
        const Spacer(),
        Semantics(
          label: 'Emergency ID',
          button: true,
          child: IconButton.filledTonal(
            icon: const Icon(
              Icons.emergency_rounded,
              color: EcTokens.statusCritical,
              size: 20,
            ),
            tooltip: 'Emergency ID',
            onPressed: () => context.push('/emergency'),
            style: IconButton.styleFrom(
              backgroundColor: EcTokens.statusCritical.withValues(alpha: 0.10),
            ),
          ),
        ),
      ],
    );
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
      data: (data) => _ProfileContent(profile: data.profile),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({this.profile});

  final HealthProfile? profile;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, kEcNavBottomPadding),
      children: [
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
                Icons.edit_rounded,
                color: EcColors.of(context).accentBrand,
                size: 18,
              ),
              onPressed: () => context.push('/settings'),
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
          child: EcGlassListTile(
            icon: Icons.medication_rounded,
            title: 'Medications & reminders',
            subtitle: profile == null
                ? 'Not set up'
                : '${profile!.medications.length} medications tracked',
            iconColor: EcTokens.categoryNutrition,
            onTap: () => context.push('/reminders'),
          ),
        ),
        EcGlassEntrance(
          index: 3,
          child: EcGlassListTile(
            icon: Icons.people_rounded,
            title: 'Family circle',
            subtitle: 'Members, moments, and privacy',
            onTap: () => context.push('/family-circle'),
          ),
        ),
        EcGlassEntrance(
          index: 4,
          child: EcGlassListTile(
            icon: Icons.link_rounded,
            title: 'Connections',
            subtitle: 'Manage caregiver access',
            onTap: () => context.push('/connections'),
          ),
        ),
        EcGlassEntrance(
          index: 5,
          child: EcGlassListTile(
            icon: Icons.emergency_rounded,
            title: 'Emergency ID',
            subtitle: 'Medical ID and emergency contacts',
            iconColor: EcTokens.statusCritical,
            onTap: () => context.push('/emergency'),
          ),
        ),
        EcGlassEntrance(
          index: 6,
          child: EcGlassListTile(
            icon: Icons.apps_rounded,
            title: 'More tools',
            subtitle: 'Chat, meals, travel, telehealth, and more',
            onTap: () => context.push('/more'),
          ),
        ),
        const SizedBox(height: 6),
        EcGlassEntrance(
          index: 7,
          child: EcGlassListTile(
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Theme, account, privacy',
            onTap: () => context.push('/settings'),
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

// ══════════════════════════════════════════════════════════ SETTINGS SCREEN ══

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final biometric = ref.watch(biometricEnabledProvider);
    final consent = ref.watch(pipedaConsentProvider);
    final ec = EcColors.of(context);

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Settings', showEmergency: false),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          // ── PIPEDA consent (if not given)
          if (!consent) ...[
            EcGlassEntrance(
              index: 0,
              child: EcGlassSurface(
                variant: EcGlassVariant.elevated,
                borderRadius: EcTokens.radiusGlass,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_rounded,
                            color: EcTokens.categoryActivity, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Privacy consent',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: EcTokens.categoryActivity,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ElinaCura collects personal health information to help manage your care under PIPEDA. You may request deletion at any time.',
                      style: TextStyle(
                        color: ec.textSecondary,
                        height: 1.5,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    EcGlassButton(
                      label: 'I consent',
                      icon: Icons.check_rounded,
                      onPressed: () =>
                          ref.read(pipedaConsentProvider.notifier).state =
                              true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Appearance
          EcSectionTitle(title: 'Appearance'),
          EcGlassEntrance(
            index: 1,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ec.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const EcThemePicker(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Security
          EcSectionTitle(title: 'Security'),
          EcGlassEntrance(
            index: 2,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Biometric unlock',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                subtitle: Text(
                  'Use Face ID or fingerprint to open the app',
                  style: TextStyle(
                    color: ec.textMuted,
                    fontSize: 12.5,
                  ),
                ),
                value: biometric,
                onChanged: (v) =>
                    ref.read(biometricEnabledProvider.notifier).state = v,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Account
          EcSectionTitle(title: 'Account'),
          EcGlassEntrance(
            index: 3,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Display name',
                      hintText: user?.displayName ?? 'Your name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  EcGlassButton(
                    label: 'Update name',
                    onPressed: () async {
                      await ref
                          .read(authServiceProvider)
                          .updateDisplayName(_nameController.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name updated')),
                        );
                      }
                    },
                  ),
                  if (user != null &&
                      !user.emailVerified &&
                      !user.isAnonymous) ...[
                    const SizedBox(height: 10),
                    EcGlassButton(
                      label: 'Resend verification email',
                      outlined: true,
                      onPressed: () => ref
                          .read(authServiceProvider)
                          .resendVerificationEmail(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          EcGlassEntrance(
            index: 4,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  EcGlassButton(
                    label: 'Change password',
                    outlined: true,
                    onPressed: () async {
                      await ref
                          .read(authServiceProvider)
                          .updatePassword(_passwordController.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password updated')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (user?.isAnonymous ?? false) ...[
            const SizedBox(height: 12),
            EcGlassButton(
              label: 'Create permanent account',
              icon: Icons.upgrade_rounded,
              onPressed: () => _showUpgradeDialog(context),
            ),
          ],
          const SizedBox(height: 28),

          // ── Sign out
          EcGlassEntrance(
            index: 5,
            child: EcGlassButton(
              label: 'Sign out',
              outlined: true,
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/auth');
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpgradeDialog(BuildContext context) async {
    final email = TextEditingController();
    final password = TextEditingController();
    await showEcGlassDialog(
      context: context,
      title: 'Upgrade account',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        EcGlassButton(
          label: 'Upgrade',
          onPressed: () async {
            await ref
                .read(authServiceProvider)
                .linkAnonymousWithEmail(email.text, password.text);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════ EMERGENCY SCREEN ══

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    return Stack(
      children: [
        // Red ambient overlay on top of void background
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _EmergencyScenePainter(),
            ),
          ),
        ),
        EcGlassScaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: const Text(
              'Emergency ID',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          body: overview.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, _) => _EmergencyBody(profile: null),
            data: (data) => _EmergencyBody(profile: data.profile),
          ),
        ),
      ],
    );
  }
}

class _EmergencyScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [
          EcTokens.statusCritical.withValues(alpha: 0.25),
          EcTokens.statusCritical.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.2),
          radius: size.width * 0.80,
        ),
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_EmergencyScenePainter _) => false;
}

class _EmergencyBody extends StatelessWidget {
  const _EmergencyBody({this.profile});

  final HealthProfile? profile;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + kToolbarHeight + 12, 20, 40),
      children: [
        // ── Massive SOS button
        EcGlassEntrance(
          index: 0,
          child: _SOSButton(),
        ),
        const SizedBox(height: 16),

        // ── Emergency contacts
        if (profile?.emergencyContacts.isNotEmpty ?? false) ...[
          EcSectionTitle(title: 'Emergency contacts'),
          ...profile!.emergencyContacts.asMap().entries.map(
            (e) => EcGlassEntrance(
              index: e.key + 1,
              child: EcGlassListTile(
                icon: Icons.person_rounded,
                title: e.value.name,
                subtitle: e.value.phone ?? e.value.relationship ?? '',
                iconColor: EcTokens.categoryNutrition,
                onTap: e.value.phone != null
                    ? () => launchUrl(Uri.parse('tel:${e.value.phone}'))
                    : null,
                trailing: e.value.phone != null
                    ? const Icon(Icons.phone_rounded, size: 18)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Medical ID
        EcSectionTitle(title: 'Medical ID'),
        EcGlassEntrance(
          index: 5,
          child: EcGlassSurface(
            variant: EcGlassVariant.elevated,
            borderRadius: EcTokens.radiusGlass,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (profile?.bloodType != null)
                  _MedIdRow(
                    label: 'Blood type',
                    value: profile!.bloodType!,
                    icon: Icons.bloodtype_rounded,
                    color: EcTokens.statusCritical,
                  ),
                if (profile?.allergies.isNotEmpty ?? false)
                  _MedIdRow(
                    label: 'Allergies',
                    value: profile!.allergies.join(', '),
                    icon: Icons.warning_amber_rounded,
                    color: EcColors.of(context).accentAmberText,
                  ),
                if (profile?.conditions.isNotEmpty ?? false)
                  _MedIdRow(
                    label: 'Conditions',
                    value: profile!.conditions.join(', '),
                    icon: Icons.monitor_heart_rounded,
                    color: EcTokens.categoryActivity,
                  ),
                if (profile?.medications.isNotEmpty ?? false)
                  _MedIdRow(
                    label: 'Medications',
                    value: profile!.medications.take(5).join(', '),
                    icon: Icons.medication_rounded,
                    color: EcTokens.categoryNutrition,
                    isLast: true,
                  ),
                if (profile == null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Complete your profile to populate your Emergency ID.',
                      style: TextStyle(
                        color: EcColors.of(context).textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SOSButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          EcGlassDangerButton(
            label: 'Call 911',
            icon: Icons.phone_rounded,
            onPressed: () => launchUrl(Uri.parse('tel:911')),
          ),
          const SizedBox(height: 12),
          EcGlassButton(
            label: 'Text emergency services',
            icon: Icons.message_rounded,
            outlined: true,
            onPressed: () => launchUrl(Uri.parse('sms:911')),
          ),
        ],
      ),
    );
  }
}

class _MedIdRow extends StatelessWidget {
  const _MedIdRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isLast = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: ec.textMuted,
                    letterSpacing: 0.8,
                    fontFamily: EcTokens.fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
