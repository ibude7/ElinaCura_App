import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    return EcTabPage(
      title: 'Health',
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EcErrorState(
          message: formatApiError(e),
          onRetry: () => ref.read(healthOverviewProvider.notifier).retry(),
        ),
        data: (data) => ListView(
          padding: kEcGlassTabPadding,
          children: [
            EcGlassEntrance(
              index: 0,
              child: EcScreenHero(
                eyebrow: 'Health record',
                title: 'Your care context',
                subtitle: data.keyVitals.isEmpty
                    ? 'Start logging vitals and goals to build a clearer care picture over time.'
                    : 'Vitals, conditions, and goals are grouped into one calm overview.',
                icon: Icons.monitor_heart_rounded,
                trailing: EcPill(
                  label: '${data.keyVitals.length} vitals',
                  tone: EcPillTone.info,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (data.keyVitals.isNotEmpty) ...[
              const EcSectionTitle(title: 'Key vitals'),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.keyVitals.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final v = data.keyVitals[i];
                    return EcGlassEntrance(
                      index: i,
                      child: SizedBox(
                        width: 148,
                        child: EcMetricTile(
                          label: v['label'] ?? '',
                          value: '${v['value'] ?? ''} ${v['unit'] ?? ''}'
                              .trim(),
                          icon: Icons.favorite_rounded,
                          tone: EcPillTone.positive,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            const EcSectionTitle(title: 'Conditions'),
            EcGlassEntrance(
              index: 1,
              child: data.conditions.isEmpty
                  ? EcEmptyState(
                      icon: Icons.assignment_rounded,
                      title: 'No conditions recorded',
                      message:
                          'Add conditions in your profile to help personalize medication and food safety guidance.',
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.conditions
                          .map((c) => EcPill(label: c.name))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 20),
            const EcSectionTitle(title: 'Goals'),
            if (data.goals.isEmpty)
              EcGlassEntrance(
                index: 2,
                child: EcCard(
                  child: Text(
                    'No goals set yet. Add a wellness target to turn tracking into a routine.',
                    style: TextStyle(color: EcColors.of(context).textSecondary),
                  ),
                ),
              )
            else
              ...data.goals.asMap().entries.map(
                (e) => EcGlassEntrance(
                  index: e.key + 2,
                  child: EcCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: EcColors.of(context).accentMintFill,
                          ),
                          child: Icon(
                            Icons.flag_rounded,
                            color: EcColors.of(context).accentMintText,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.value.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        EcPill(
                          label: e.value.priority,
                          tone: EcPillTone.positive,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    return EcTabPage(
      title: 'Profile',
      body: ListView(
        padding: kEcGlassTabPadding,
        children: [
          EcGlassEntrance(
            index: 0,
            child: EcScreenHero(
              eyebrow: user?.isAnonymous ?? false
                  ? 'Guest profile'
                  : 'Member profile',
              title: user?.displayName ?? 'Your care profile',
              subtitle:
                  user?.email ??
                  'Guest account. Create a permanent account when you are ready to sync your care data.',
              icon: Icons.person_rounded,
              trailing: EcPill(label: 'Private', tone: EcPillTone.positive),
            ),
          ),
          const SizedBox(height: 12),
          overview.when(
            loading: () => const EcSkeleton(height: 80),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (data) {
              if (data.profile == null) return const SizedBox.shrink();
              return EcGlassEntrance(
                index: 1,
                child: EcCard(
                  child: Column(
                    children: [
                      if (data.profile!.location != null)
                        _ProfileInfoRow(
                          icon: Icons.location_on_rounded,
                          text: data.profile!.location!,
                        ),
                      if (data.profile!.bloodType != null)
                        _ProfileInfoRow(
                          icon: Icons.bloodtype_rounded,
                          text: 'Blood type: ${data.profile!.bloodType}',
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          EcGlassEntrance(
            index: 2,
            child: EcGlassListTile(
              icon: Icons.settings_rounded,
              title: 'Settings',
              onTap: () => context.push('/settings'),
            ),
          ),
          EcGlassEntrance(
            index: 3,
            child: EcGlassListTile(
              icon: Icons.people_rounded,
              title: 'Connections',
              onTap: () => context.push('/connections'),
            ),
          ),
          EcGlassEntrance(
            index: 4,
            child: EcGlassListTile(
              icon: Icons.apps_rounded,
              title: 'More',
              onTap: () => context.push('/more'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ec.accentBrand),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

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

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Settings'),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          EcGlassEntrance(
            index: 0,
            child: EcScreenHero(
              eyebrow: 'Preferences',
              title: 'Tune your care space',
              subtitle:
                  'Manage appearance, privacy, account security, and access for this device.',
              icon: Icons.tune_rounded,
              trailing: EcPill(
                label: biometric ? 'Protected' : 'Optional',
                tone: biometric ? EcPillTone.positive : EcPillTone.neutral,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (!consent)
            EcGlassEntrance(
              index: 1,
              child: EcCard(
                variant: EcGlassVariant.tinted,
                tint: EcColors.of(context).accentSkyFill,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Health data consent (PIPEDA)',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ElinaCura collects personal health information to help you manage your care. You may request deletion at any time.',
                    ),
                    const SizedBox(height: 16),
                    EcGlassButton(
                      label: 'I consent',
                      onPressed: () =>
                          ref.read(pipedaConsentProvider.notifier).state = true,
                    ),
                  ],
                ),
              ),
            ),
          if (!consent) const SizedBox(height: 16),
          const EcSectionTitle(title: 'Appearance'),
          EcGlassEntrance(
            index: 2,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: EcColors.of(context).textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose light, dark, or match your device.',
                    style: TextStyle(
                      fontSize: 12,
                      color: EcColors.of(context).textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const EcThemePicker(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const EcSectionTitle(title: 'Account'),
          EcGlassEntrance(
            index: 3,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Display name',
                      hintText: user?.displayName,
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
          const SizedBox(height: 16),
          EcGlassEntrance(
            index: 4,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
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
            const SizedBox(height: 16),
            const EcSectionTitle(title: 'Upgrade guest account'),
            EcGlassButton(
              label: 'Create permanent account',
              onPressed: () => _showUpgradeDialog(context),
            ),
          ],
          const SizedBox(height: 16),
          EcGlassEntrance(
            index: 5,
            child: EcGlassSurface(
              variant: EcGlassVariant.subtle,
              borderRadius: EcTokens.radiusLg,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Biometric unlock',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Optional — use Face ID or fingerprint'),
                value: biometric,
                onChanged: (v) =>
                    ref.read(biometricEnabledProvider.notifier).state = v,
              ),
            ),
          ),
          const SizedBox(height: 24),
          EcGlassButton(
            label: 'Sign out',
            outlined: true,
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/auth');
            },
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

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Emergency', showEmergency: false),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _EmergencyBody(profile: null),
        data: (data) => _EmergencyBody(profile: data.profile),
      ),
    );
  }
}

class _EmergencyBody extends StatelessWidget {
  const _EmergencyBody({this.profile});

  final HealthProfile? profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: kEcGlassListPadding,
      children: [
        EcGlassEntrance(
          index: 0,
          child: EcScreenHero(
            eyebrow: 'Medical ID',
            title: 'Emergency essentials',
            subtitle:
                'Fast access to critical details and contacts. Keep this screen ready before you need it.',
            icon: Icons.emergency_rounded,
            accent: EcColors.of(context).textCritical,
            trailing: EcPill(label: 'Critical', tone: EcPillTone.critical),
          ),
        ),
        const SizedBox(height: 16),
        EcGlassEntrance(
          index: 1,
          child: EcGlassDangerButton(
            label: 'Call 911',
            onPressed: () => launchUrl(Uri.parse('tel:911')),
          ),
        ),
        const SizedBox(height: 24),
        const EcSectionTitle(title: 'Medical ID'),
        EcGlassEntrance(
          index: 2,
          child: EcCard(
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile?.bloodType != null)
                  _InfoRow('Blood type', profile!.bloodType!),
                if (profile?.allergies.isNotEmpty ?? false)
                  _InfoRow('Allergies', profile!.allergies.join(', ')),
                if (profile?.conditions.isNotEmpty ?? false)
                  _InfoRow('Conditions', profile!.conditions.join(', ')),
                if (profile?.medications.isNotEmpty ?? false)
                  _InfoRow(
                    'Medications',
                    profile!.medications.take(5).join(', '),
                  ),
                if (profile == null)
                  const Text(
                    'Sign in and complete your profile for medical info.',
                  ),
              ],
            ),
          ),
        ),
        if (profile?.emergencyContacts.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          const EcSectionTitle(title: 'Emergency contacts'),
          ...profile!.emergencyContacts.asMap().entries.map(
            (e) => EcGlassEntrance(
              index: e.key + 3,
              child: EcCard(
                onTap: e.value.phone != null
                    ? () => launchUrl(Uri.parse('tel:${e.value.phone}'))
                    : null,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EcColors.of(context).accentMintFill,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: EcColors.of(context).accentMintText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            e.value.phone ?? e.value.relationship ?? '',
                            style: TextStyle(
                              color: EcColors.of(context).textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (e.value.phone != null) const Icon(Icons.phone_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
