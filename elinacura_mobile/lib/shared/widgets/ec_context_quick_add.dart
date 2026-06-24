import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/data/care_schedule_repository.dart';
import '../../core/design_system/ec_copy.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';

/// Context-aware quick-add — time-of-day + next dose (Rec #13).
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
        Text('Quick add', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          primary.subtitle,
          style: TextStyle(color: EcColors.of(context).textSecondary),
        ),
        const SizedBox(height: 16),
        EcGlassButton(
          label: primary.label,
          icon: primary.icon,
          onPressed: () {
            Navigator.pop(context);
            context.push(primary.route);
          },
        ),
        const SizedBox(height: 12),
        Text('All actions', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _row(context, Icons.medication_rounded, 'Log dose', '/reminders',
            color: EcTokens.categoryNutrition),
        _row(context, Icons.monitor_heart_rounded, 'Log vitals', '/health',
            color: EcTokens.categoryHeart),
        _row(context, Icons.auto_awesome_rounded, 'Ask Care AI', '/chat',
            color: EcTokens.categorySleep),
        _row(context, Icons.document_scanner_rounded, 'Scan label', '/ocr',
            color: EcTokens.categoryBreathing),
        _row(context, Icons.emergency_rounded, 'Emergency', '/emergency',
            color: EcTokens.statusCritical),
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

  static Widget _row(
    BuildContext context,
    IconData icon,
    String label,
    String route, {
    Color? color,
  }) {
    return EcGlassListTile(
      icon: icon,
      title: label,
      iconColor: color,
      onTap: () {
        Navigator.pop(context);
        context.push(route);
      },
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
