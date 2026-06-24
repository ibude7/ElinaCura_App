import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/ec_copy.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_widgets.dart';

/// Trust Center — PIPEDA, export, delete, sharing (Rec #46).
class TrustCenterScreen extends ConsumerWidget {
  const TrustCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Trust Center', showEmergency: false),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          EcPageHero(
            eyebrow: 'Privacy',
            title: 'Your data, your control',
            subtitle: EcCopy.trustCenter,
            icon: Icons.verified_user_rounded,
            accent: EcAccent.sky,
          ),
          const SizedBox(height: 16),
          EcGlassListTile(
            icon: Icons.policy_rounded,
            title: 'PIPEDA consent',
            subtitle: 'How we collect and use health information',
            onTap: () {},
          ),
          EcGlassListTile(
            icon: Icons.group_rounded,
            title: 'Who can see what',
            subtitle: 'Family circle and caregiver permissions',
            onTap: () => context.push('/family-circle'),
          ),
          EcGlassListTile(
            icon: Icons.download_rounded,
            title: 'Export my data',
            subtitle: 'Download a copy of your care record',
            onTap: () => context.push('/report'),
          ),
          EcGlassListTile(
            icon: Icons.delete_forever_rounded,
            title: 'Delete my account',
            subtitle: 'Permanently remove your profile and data',
            iconColor: EcTokens.statusCritical,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
