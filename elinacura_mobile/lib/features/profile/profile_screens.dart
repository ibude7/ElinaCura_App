import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_theme_picker.dart';
import '../../shared/widgets/ec_widgets.dart';

// ═══════════════════════════════════════════════════════════ HEALTH SCREEN ══

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    return overview.when(
      loading: () => const _HealthSkeleton(),
      error: (e, _) => Center(
        child: EcErrorState(
          message: formatApiError(e),
          onRetry: () => ref.read(healthOverviewProvider.notifier).retry(),
        ),
      ),
      data: (data) => _HealthContent(data: data),
    );
  }
}

class _HealthSkeleton extends StatelessWidget {
  const _HealthSkeleton();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, kEcNavBottomPadding),
      children: const [
        EcSkeleton(height: 200, radius: 999),
        SizedBox(height: 24),
        EcSkeleton(height: 100, radius: 28),
        SizedBox(height: 16),
        EcSkeleton(height: 180, radius: 28),
      ],
    );
  }
}

class _HealthContent extends StatelessWidget {
  const _HealthContent({required this.data});

  final HealthOverview data;

  double get _healthScore {
    int score = 50;
    if (data.medications.isNotEmpty) score += 20;
    if (data.conditions.isNotEmpty) score += 10;
    if (data.keyVitals.isNotEmpty) score += 20;
    return (score / 100).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, kEcNavBottomPadding),
      children: [
        // ── Screen header
        _HealthHeader(),
        const SizedBox(height: 28),

        // ── Health ring
        Center(
          child: EcHealthRing(
            score: _healthScore,
            size: 180,
            label: 'Health',
            accentColor: ec.accentMint,
          ),
        ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.88, 0.88),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 28),

        // ── Vitals grid
        if (data.keyVitals.isNotEmpty) ...[
          EcSectionTitle(title: 'Vitals'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemCount: data.keyVitals.length.clamp(0, 6),
            itemBuilder: (context, i) {
              final v = data.keyVitals[i];
              return EcGlassEntrance(
                index: i,
                child: _VitalCard(
                  label: v['label'] ?? '',
                  value: v['value'] ?? '—',
                  unit: v['unit'],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],

        // ── Conditions
        if (data.conditions.isNotEmpty) ...[
          EcSectionTitle(title: 'Conditions'),
          EcGlassSurface(
            variant: EcGlassVariant.elevated,
            borderRadius: EcTokens.radiusGlass,
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.conditions.map((c) {
                return EcPill(
                  label: c.name,
                  tone: _conditionTone(c.status),
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 120.ms),
          const SizedBox(height: 20),
        ],

        // ── Goals
        if (data.goals.isNotEmpty) ...[
          EcSectionTitle(title: 'Goals'),
          EcGlassSurface(
            variant: EcGlassVariant.elevated,
            borderRadius: EcTokens.radiusGlass,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: data.goals.asMap().entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: e.key < data.goals.length - 1 ? 14 : 0,
                  ),
                  child: EcGlassProgressBar(
                    label: e.value.label,
                    value: e.value.priority == 'high'
                        ? 0.72
                        : e.value.priority == 'medium'
                            ? 0.48
                            : 0.25,
                    color: ec.accentBrand,
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 160.ms),
          const SizedBox(height: 20),
        ],

        // ── Empty state
        if (data.keyVitals.isEmpty &&
            data.conditions.isEmpty &&
            data.goals.isEmpty)
          EcEmptyState(
            icon: Icons.favorite_rounded,
            title: 'No health data yet',
            message:
                'Add vitals, conditions, and goals through your care profile to see them here.',
            action: EcGlassButton(
              label: 'Set up profile',
              onPressed: () => context.push('/profile'),
            ),
          ),
      ],
    );
  }

  EcPillTone _conditionTone(String status) {
    switch (status.toLowerCase()) {
      case 'managed':
        return EcPillTone.positive;
      case 'monitoring':
        return EcPillTone.caution;
      case 'active':
        return EcPillTone.info;
      default:
        return EcPillTone.neutral;
    }
  }
}

class _HealthHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? Colors.white : EcTokens.textPrimaryLight;
    final ec = EcColors.of(context);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VITALS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: ec.textMuted,
                fontFamily: EcTokens.fontFamily,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Health',
              style: TextStyle(
                fontSize: EcTokens.fontSizeDisplayLg * 0.7,
                fontWeight: FontWeight.w800,
                letterSpacing: -2.0,
                color: textColor,
                fontFamily: EcTokens.fontFamily,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton.filledTonal(
          icon: const Icon(
            Icons.emergency_rounded,
            color: EcTokens.statusCritical,
            size: 20,
          ),
          onPressed: () => context.push('/emergency'),
          style: IconButton.styleFrom(
            backgroundColor:
                EcTokens.statusCritical.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({
    required this.label,
    required this.value,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusCard,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: ec.textMuted,
              fontFamily: EcTokens.fontFamily,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      letterSpacing: -1.0,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 11,
                      color: ec.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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
            iconColor: EcColors.of(context).accentMint,
            onTap: () => context.push('/reminders'),
          ),
        ),
        EcGlassEntrance(
          index: 3,
          child: EcGlassListTile(
            icon: Icons.people_rounded,
            title: 'Care circle',
            subtitle: 'Invite and manage caregivers',
            onTap: () => context.push('/connections'),
          ),
        ),
        EcGlassEntrance(
          index: 4,
          child: EcGlassListTile(
            icon: Icons.emergency_rounded,
            title: 'Emergency ID',
            subtitle: 'Medical ID and emergency contacts',
            iconColor: EcTokens.statusCritical,
            onTap: () => context.push('/emergency'),
          ),
        ),
        EcGlassEntrance(
          index: 5,
          child: EcGlassListTile(
            icon: Icons.apps_rounded,
            title: 'More tools',
            subtitle: 'Scanner, refill calendar, safety',
            onTap: () => context.push('/more'),
          ),
        ),
        const SizedBox(height: 6),
        EcGlassEntrance(
          index: 6,
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
          color: ec.accentSky,
        ),
      if (profile.medications.isNotEmpty)
        _SummaryItem(
          icon: Icons.medication_rounded,
          label: '${profile.medications.length} meds',
          color: ec.accentMint,
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
                            color: ec.accentSky, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Privacy consent',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: ec.accentSky,
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
                iconColor: EcColors.of(context).accentMint,
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
                    color: EcColors.of(context).accentSky,
                  ),
                if (profile?.medications.isNotEmpty ?? false)
                  _MedIdRow(
                    label: 'Medications',
                    value: profile!.medications.take(5).join(', '),
                    icon: Icons.medication_rounded,
                    color: EcColors.of(context).accentMint,
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
