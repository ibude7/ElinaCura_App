import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';
import '../../shared/widgets/ec_page_kit.dart';

/// Full-screen safety escalation when Care AI detects elevated risk.
Future<void> showSafetyEscalationSheet(
  BuildContext context, {
  required String message,
  String? riskLevel,
  VoidCallback? onEmergency,
}) {
  return showEcGlassSheet(
    context,
    children: [
      EcPageHero(
        eyebrow: 'Safety',
        title: 'We noticed something important',
        subtitle: message,
        icon: Icons.shield_moon_rounded,
        accent: EcAccent.blush,
        layer: EcSurfaceLayer.solidContent,
        trailing: riskLevel != null
            ? EcPill(
                label: riskLevel.toUpperCase(),
                tone: EcPillTone.critical,
              )
            : null,
      ),
      const SizedBox(height: 16),
      Text(
        'ElinaCura flagged this for your safety. If you are in immediate danger, use Emergency ID or call local emergency services.',
        style: TextStyle(
          color: EcColors.of(context).textSecondary,
          height: 1.45,
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            if (onEmergency != null) {
              onEmergency();
            } else {
              context.push('/emergency');
            }
          },
          icon: const Icon(Icons.emergency_rounded),
          label: const Text('Open Emergency ID'),
          style: FilledButton.styleFrom(
            backgroundColor: EcTokens.statusCritical,
          ),
        ),
      ),
    ],
  );
}
