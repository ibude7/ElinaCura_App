import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/design_system/ec_haptics.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_care_passport.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_guilloche.dart';
import '../../shared/widgets/ec_widgets.dart';

/// Medical ID passport for first responders (Rec #20).
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final overview = ref.watch(healthOverviewProvider);

    return EcGlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          l10n.emergencyTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _EmergencyBody(profile: null),
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
    final l10n = context.l10n;
    final top = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + kToolbarHeight + 12, 20, 40),
      children: [
        EcGlassEntrance(
          index: 0,
          child: _SOSButton(profile: profile),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.emergencyTip,
          style: TextStyle(
            fontSize: 12.5,
            color: EcColors.of(context).textSecondary,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (profile != null) ...[
          EcGlassEntrance(
            index: 1,
            child: EcGuillocheBackdrop(
              child: EcCarePassportCard(profile: profile!),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (profile?.emergencyContacts.isNotEmpty ?? false) ...[
          EcSectionTitle(title: l10n.emergencyContact),
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
        EcSectionTitle(title: l10n.emergencyTitle),
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
                    label: l10n.emergencyBloodType,
                    value: profile!.bloodType!,
                    icon: Icons.bloodtype_rounded,
                    color: EcTokens.statusCritical,
                  ),
                if (profile?.allergies.isNotEmpty ?? false)
                  _MedIdRow(
                    label: l10n.emergencyAllergies,
                    value: profile!.allergies.join(', '),
                    icon: Icons.warning_amber_rounded,
                    color: EcColors.of(context).accentAmberText,
                  ),
                if (profile?.conditions.isNotEmpty ?? false)
                  _MedIdRow(
                    label: l10n.emergencyConditions,
                    value: profile!.conditions.join(', '),
                    icon: Icons.monitor_heart_rounded,
                    color: EcTokens.categoryActivity,
                  ),
                if (profile?.medications.isNotEmpty ?? false)
                  _MedIdRow(
                    label: l10n.emergencyMedications,
                    value: profile!.medications.take(5).join(', '),
                    icon: Icons.medication_rounded,
                    color: EcTokens.categoryNutrition,
                    isLast: true,
                  ),
                if (profile == null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      l10n.emergencyNoProfile,
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
  const _SOSButton({this.profile});

  final HealthProfile? profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          EcGlassDangerButton(
            label: l10n.emergencyCall,
            icon: Icons.phone_rounded,
            onPressed: () async {
              await EcHaptics.sosEscalation();
              await launchUrl(Uri.parse('tel:911'));
            },
          ),
          const SizedBox(height: 12),
          EcGlassButton(
            label: 'Send emergency brief',
            icon: Icons.contact_emergency_rounded,
            onPressed: () => _sendBrief(context),
          ),
          const SizedBox(height: 12),
          EcGlassButton(
            label: l10n.emergencyTextServices,
            icon: Icons.message_rounded,
            outlined: true,
            onPressed: () => launchUrl(Uri.parse('sms:911')),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBrief(BuildContext context) async {
    await EcHaptics.safetyFlag();
    final brief = composeEmergencyBrief(profile);
    String? phone;
    for (final c in profile?.emergencyContacts ?? const <EmergencyContact>[]) {
      if (c.phone != null && c.phone!.isNotEmpty) {
        phone = c.phone;
        break;
      }
    }
    final smsUri = Uri(
      scheme: 'sms',
      path: phone ?? '',
      queryParameters: {'body': brief},
    );
    try {
      final ok = await launchUrl(smsUri);
      if (!ok) {
        await Share.share(brief, subject: 'Emergency medical brief');
      }
    } catch (_) {
      await Share.share(brief, subject: 'Emergency medical brief');
    }
  }
}

/// Builds an EMT-ready one-message brief from the user's medical profile.
String composeEmergencyBrief(HealthProfile? profile) {
  final b = StringBuffer('EMERGENCY MEDICAL BRIEF\n');
  b.writeln('Name: ${profile?.name ?? 'Unknown'}');
  if (profile?.bloodType != null) b.writeln('Blood type: ${profile!.bloodType}');
  if (profile?.allergies.isNotEmpty ?? false) {
    b.writeln('Allergies: ${profile!.allergies.join(', ')}');
  }
  if (profile?.conditions.isNotEmpty ?? false) {
    b.writeln('Conditions: ${profile!.conditions.join(', ')}');
  }
  if (profile?.medications.isNotEmpty ?? false) {
    b.writeln('Medications: ${profile!.medications.take(8).join(', ')}');
  }
  final contacts = profile?.emergencyContacts ?? const <EmergencyContact>[];
  if (contacts.isNotEmpty) {
    final list = contacts
        .map((c) => '${c.name}${c.phone != null ? ' (${c.phone})' : ''}')
        .join('; ');
    b.writeln('Emergency contacts: $list');
  }
  b.write('— Sent via ElinaCura');
  return b.toString();
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
