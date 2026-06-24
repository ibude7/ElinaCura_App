import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/feature_flags.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';
import 'ec_widgets.dart';

/// PWA-style grouped More menu (Rec #12).
class EcGroupedMoreSheet {
  static Future<void> show(BuildContext context, {FeatureFlags? flags}) {
    final f = flags ?? const FeatureFlags();
    return showEcGlassSheet(
      context,
      children: [
        Text('More', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _group(context, 'Overview', [
          if (f.digestEnabled)
            _tile(context, Icons.newspaper_rounded, 'Weekly digest', '/digest'),
          _tile(context, Icons.summarize_rounded, 'Health report', '/report'),
        ]),
        _group(context, 'Daily Care', [
          _tile(context, Icons.restaurant_rounded, 'Meals', '/meals'),
          _tile(context, Icons.local_grocery_store_rounded, 'Grocery', '/grocery'),
          if (f.shoppingEnabled)
            _tile(context, Icons.checklist_rounded, 'Shopping list', '/shopping-list'),
          _tile(context, Icons.alarm_rounded, 'Reminders', '/reminders'),
          _tile(context, Icons.calendar_month_rounded, 'Refill calendar', '/refill'),
        ]),
        _group(context, 'Safety', [
          _tile(context, Icons.shield_rounded, 'Safety monitoring', '/safety'),
          _tile(context, Icons.emergency_rounded, 'Emergency ID', '/emergency',
              color: EcTokens.statusCritical),
          if (f.travelEnabled)
            _tile(context, Icons.flight_takeoff_rounded, 'Travel mode', '/travel-mode'),
          if (f.telehealthEnabled)
            _tile(context, Icons.video_call_rounded, 'Telehealth', '/telehealth'),
        ]),
        _group(context, 'Engage', [
          if (f.chatEnabled)
            _tile(context, Icons.auto_awesome_rounded, 'Care AI', '/chat'),
          if (f.voiceEnabled)
            _tile(context, Icons.mic_rounded, 'Voice', '/voice'),
          if (f.momentsEnabled)
            _tile(context, Icons.auto_stories_rounded, 'Moments', '/moments'),
        ]),
        _group(context, 'Care Network', [
          if (f.circlesEnabled) ...[
            _tile(context, Icons.family_restroom_rounded, 'Family circle', '/family-circle'),
            _tile(context, Icons.link_rounded, 'Connections', '/connections'),
          ],
        ]),
      ],
    );
  }

  static Widget _group(BuildContext context, String title, List<Widget> tiles) {
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EcSectionTitle(title: title),
          ...tiles,
        ],
      ),
    );
  }

  static Widget _tile(
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
