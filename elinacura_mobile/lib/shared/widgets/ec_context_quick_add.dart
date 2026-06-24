import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/data/care_schedule_repository.dart';
import '../../core/design_system/ec_copy.dart';
import '../../core/design_system/ec_haptics.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';
import 'ec_obsidian_kit.dart';

/// Context-aware quick-add presented as a command palette — a double-width
/// "Ask Care AI" tile (pulsing gold shimmer) above a 2×2 grid of glass tiles.
class EcContextQuickAdd {
  static void show(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final schedule = ref.read(careScheduleProvider(
      ref.read(healthOverviewProvider).valueOrNull?.profile?.id ?? '',
    ));
    final items = schedule.valueOrNull?.where((i) => !i.done).toList() ?? [];
    final next = items.isNotEmpty ? items.first : null;
    final primary = _primaryAction(hour, next);

    showEcGlassSheet(
      context,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick add',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  primary.subtitle,
                  style: TextStyle(
                    color: EcColors.of(context).textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _AiPaletteTile(
            onTap: () {
              Navigator.pop(context);
              context.push('/chat');
            },
          ),
        ).animate().fadeIn(duration: 280.ms).slideY(
              begin: 0.14,
              end: 0,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: _PaletteTile(
                  icon: Icons.medication_rounded,
                  label: 'Log dose',
                  color: EcTokens.accentGold,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/reminders');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PaletteTile(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Log vitals',
                  color: EcTokens.accentJade,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/health');
                  },
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 70.ms, duration: 280.ms).slideY(
              begin: 0.14,
              end: 0,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: _PaletteTile(
                  icon: Icons.document_scanner_rounded,
                  label: 'Scan label',
                  color: EcTokens.accentGold,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/ocr');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PaletteTile(
                  icon: Icons.sos_rounded,
                  label: 'Emergency',
                  color: EcTokens.statusCritical,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/emergency');
                  },
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 140.ms, duration: 280.ms).slideY(
              begin: 0.14,
              end: 0,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 4),
      ],
    );
  }

  static _QuickAction _primaryAction(int hour, CareScheduleItem? next) {
    if (next != null) {
      return _QuickAction(
        label: 'Log ${next.label}',
        subtitle: '${EcCopy.nextDose} at ${next.time}',
        icon: Icons.medication_rounded,
        route: '/reminders',
      );
    }
    if (hour < 12) {
      return const _QuickAction(
        label: 'Morning dose check',
        subtitle: 'Start your day with adherence on track.',
        icon: Icons.wb_sunny_rounded,
        route: '/reminders',
      );
    }
    if (hour < 17) {
      return const _QuickAction(
        label: 'Log vitals',
        subtitle: 'Midday check-in keeps your rhythm accurate.',
        icon: Icons.monitor_heart_rounded,
        route: '/health',
      );
    }
    return const _QuickAction(
      label: 'Evening care review',
      subtitle: 'Review today\'s doses and vitals before bed.',
      icon: Icons.nightlight_rounded,
      route: '/dashboard',
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
}

/// Double-width "Ask Care AI" tile with a pulsing gold shimmer border.
class _AiPaletteTile extends StatelessWidget {
  const _AiPaletteTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight;
    return EcShimmerGoldBorder(
      borderRadius: EcTokens.radiusCard,
      child: EcGlassSurface(
        onTap: () {
          EcHaptics.lightTap();
          onTap();
        },
        variant: EcGlassVariant.float,
        borderRadius: EcTokens.radiusCard,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EcTokens.accentGold.withValues(alpha: 0.16),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: EcTokens.accentGold, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask Care AI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Plan your day, meds, meals & more',
                    style: TextStyle(color: ec.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: EcTokens.accentGold, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Square command-palette tile.
class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight;
    return EcGlassSurface(
      onTap: () {
        EcHaptics.lightTap();
        onTap();
      },
      variant: EcGlassVariant.regular,
      borderRadius: EcTokens.radiusCard,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
