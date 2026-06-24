import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_screen_header.dart';
import '../../shared/widgets/ec_widgets.dart';

/// Caregiver Command Center — alert feed, heatmap, proof gallery (Rec #43).
class CaregiverCommandCenter extends ConsumerWidget {
  const CaregiverCommandCenter({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(caregiverDashboardProvider(profileId));

    return dashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EcErrorState(message: '$e', onRetry: () {}),
      data: (data) => ListView(
        padding: kEcGlassListPadding,
        children: [
          EcScreenHeader(
            variant: EcHeaderVariant.tab,
            eyebrow: 'Command center',
            title: 'Patient ${data.profileId}',
            subtitle: 'Alerts, adherence, and proof at a glance',
            showBack: false,
          ),
          const SizedBox(height: 12),
          EcPageHero(
            eyebrow: 'Adherence',
            title: '${data.adherencePercent ?? 0}%',
            subtitle: '7-day medication adherence',
            icon: Icons.task_alt_rounded,
            accent: EcAccent.mint,
            trailing: EcRingProgress(
              value: (data.adherenceRate7d ?? 0),
              label: '7d',
              size: 64,
              color: EcTokens.categoryNutrition,
            ),
          ),
          const SizedBox(height: 16),
          EcSectionTitle(title: 'Safety alerts'),
          if (data.safetyEvents.isEmpty)
            const EcEmptyState(
              icon: Icons.shield_rounded,
              title: 'No active alerts',
              message: 'Safety events from your patient appear here.',
            )
          else
            ...data.safetyEvents.map(
              (e) => EcGlassListTile(
                icon: Icons.warning_amber_rounded,
                title: e.summary ?? 'Safety event',
                subtitle: e.level ?? '',
                onTap: () {},
              ),
            ),
          const SizedBox(height: 16),
          EcSectionTitle(title: 'Quick actions'),
          Row(
            children: [
              Expanded(
                child: EcGlassButton(
                  label: 'Message',
                  icon: Icons.chat_rounded,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EcGlassButton(
                  label: 'Proof gallery',
                  icon: Icons.photo_camera_rounded,
                  outlined: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
