import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/design_system/ec_copy.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_theme_picker.dart';
import '../../shared/widgets/ec_widgets.dart';

/// App settings — appearance, security, account (Rec #26).
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
    final l10n = context.l10n;
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final biometric = ref.watch(biometricEnabledProvider);
    final consent = ref.watch(pipedaConsentProvider);
    final ec = EcColors.of(context);

    return EcGlassScaffold(
      appBar: EcAppBar(title: l10n.settingsTitle, showEmergency: false),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
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
                        Icon(
                          Icons.shield_rounded,
                          color: EcTokens.categoryActivity,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.settingsPrivacyTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: EcTokens.categoryActivity,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.settingsPrivacyBody,
                      style: TextStyle(
                        color: ec.textSecondary,
                        height: 1.5,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    EcGlassButton(
                      label: l10n.settingsConsentCta,
                      icon: Icons.check_rounded,
                      onPressed: () =>
                          ref.read(pipedaConsentProvider.notifier).state = true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          EcSectionTitle(title: l10n.settingsAppearanceTitle),
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
                    l10n.t('settingsPage.appearance.sub', fallback: 'Choose your theme'),
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
          EcSectionTitle(title: l10n.settingsSecurityTitle),
          EcGlassEntrance(
            index: 2,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.settingsBiometricTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                subtitle: Text(
                  l10n.settingsBiometricSub,
                  style: TextStyle(color: ec.textMuted, fontSize: 12.5),
                ),
                value: biometric,
                onChanged: (v) =>
                    ref.read(biometricEnabledProvider.notifier).state = v,
              ),
            ),
          ),
          const SizedBox(height: 20),
          EcSectionTitle(title: l10n.settingsAccountTitle),
          EcGlassEntrance(
            index: 3,
            child: EcGlassListTile(
              icon: Icons.verified_user_rounded,
              title: l10n.t('settingsPage.privacy.manageData', fallback: 'Trust Center'),
              subtitle: EcCopy.trustCenter,
              onTap: () => context.push('/trust-center'),
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
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.settingsDisplayName,
                      hintText: user?.displayName ?? l10n.settingsNameHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  EcGlassButton(
                    label: l10n.settingsUpdateName,
                    onPressed: () async {
                      await ref
                          .read(authServiceProvider)
                          .updateDisplayName(_nameController.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.settingsNameUpdated)),
                        );
                      }
                    },
                  ),
                  if (user != null &&
                      !user.emailVerified &&
                      !user.isAnonymous) ...[
                    const SizedBox(height: 10),
                    EcGlassButton(
                      label: l10n.settingsResendVerification,
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
            index: 5,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: l10n.settingsNewPassword,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  EcGlassButton(
                    label: l10n.settingsChangePassword,
                    outlined: true,
                    onPressed: () async {
                      await ref
                          .read(authServiceProvider)
                          .updatePassword(_passwordController.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.settingsPasswordUpdated)),
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
              label: l10n.settingsUpgradeAccount,
              icon: Icons.upgrade_rounded,
              onPressed: () => _showUpgradeDialog(context),
            ),
          ],
          const SizedBox(height: 28),
          EcGlassEntrance(
            index: 6,
            child: EcGlassButton(
              label: l10n.settingsSignOut,
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
    final l10n = context.l10n;
    final email = TextEditingController();
    final password = TextEditingController();
    await showEcGlassDialog(
      context: context,
      title: l10n.settingsUpgradeTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: email,
            decoration: InputDecoration(labelText: l10n.settingsEmail),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            decoration: InputDecoration(labelText: l10n.settingsNewPassword),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.settingsCancel),
        ),
        EcGlassButton(
          label: l10n.settingsUpgradeAction,
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
