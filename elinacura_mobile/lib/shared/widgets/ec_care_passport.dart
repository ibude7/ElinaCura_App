import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import 'ec_glass.dart';
import 'ec_guilloche.dart';
import 'ec_page_kit.dart';

/// Shareable Care Passport — guilloché security pattern, QR, PDF share (Rec #39).
class EcCarePassportCard extends StatelessWidget {
  const EcCarePassportCard({super.key, required this.profile});

  final HealthProfile profile;

  String get _payload => [
        'ELINACURA-PASSPORT',
        'id:${profile.id}',
        if (profile.name != null) 'name:${profile.name}',
        if (profile.bloodType != null) 'blood:${profile.bloodType}',
        if (profile.allergies.isNotEmpty) 'allergies:${profile.allergies.join('|')}',
        if (profile.conditions.isNotEmpty) 'conditions:${profile.conditions.join('|')}',
        if (profile.medications.isNotEmpty) 'meds:${profile.medications.take(8).join('|')}',
      ].join(';');

  String get _textSummary {
    final lines = <String>[
      'ElinaCura Care Passport',
      if (profile.name != null) 'Name: ${profile.name}',
      if (profile.bloodType != null) 'Blood type: ${profile.bloodType}',
      if (profile.allergies.isNotEmpty) 'Allergies: ${profile.allergies.join(', ')}',
      if (profile.conditions.isNotEmpty)
        'Conditions: ${profile.conditions.join(', ')}',
      if (profile.medications.isNotEmpty)
        'Medications: ${profile.medications.join(', ')}',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(EcTokens.radiusGlass),
              child: EcGuillocheBackdrop(
                opacity: 0.06,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EcMedallion(
                      icon: Icons.badge_rounded,
                      accent: EcAccent.blush,
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Care Passport',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Responder-ready medical identity',
                            style: TextStyle(
                              color: ec.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy passport',
                      onPressed: () => _copy(context),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                    IconButton(
                      tooltip: 'Share passport',
                      onPressed: () => Share.share(_textSummary),
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ec.textMuted.withValues(alpha: 0.2)),
                    ),
                    child: QrImageView(
                      data: _payload,
                      size: 120,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (profile.bloodType != null)
                  _PassportRow(label: 'Blood type', value: profile.bloodType!),
                if (profile.allergies.isNotEmpty)
                  _PassportRow(
                    label: 'Allergies',
                    value: profile.allergies.join(', '),
                    critical: true,
                  ),
                if (profile.conditions.isNotEmpty)
                  _PassportRow(
                    label: 'Conditions',
                    value: profile.conditions.join(', '),
                  ),
                if (profile.medications.isNotEmpty)
                  _PassportRow(
                    label: 'Medications',
                    value: profile.medications.take(6).join(', '),
                  ),
                if (profile.emergencyContacts.isNotEmpty)
                  _PassportRow(
                    label: 'Emergency contact',
                    value:
                        '${profile.emergencyContacts.first.name}'
                        '${profile.emergencyContacts.first.phone != null ? ' · ${profile.emergencyContacts.first.phone}' : ''}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _textSummary));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Care Passport copied to clipboard')),
    );
  }
}

class _PassportRow extends StatelessWidget {
  const _PassportRow({
    required this.label,
    required this.value,
    this.critical = false,
  });

  final String label;
  final String value;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            critical ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 16,
            color: critical ? EcTokens.statusCritical : ec.textMuted,
          ),
          const SizedBox(width: 10),
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
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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
