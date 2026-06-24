import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/design_system/ec_copy.dart';
import '../../core/data/care_repository.dart';
import '../../core/data/engagement_repository.dart';
import '../../core/data/unified_care_repository.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/ec_motion.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_screen_header.dart';
import '../../shared/widgets/ec_widgets.dart';
import '../chat/chat_screen.dart';

/// Unified Care inbox — messages, AI, digest, moments, safety.
class CareInboxScreen extends ConsumerStatefulWidget {
  const CareInboxScreen({super.key});

  @override
  ConsumerState<CareInboxScreen> createState() => _CareInboxScreenState();
}

class _CareInboxScreenState extends ConsumerState<CareInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileId = activeProfileId(ref);
    final inbox = profileId == null
        ? const AsyncValue<List<CareInboxItem>>.data([])
        : ref.watch(unifiedInboxProvider(profileId));
    final ec = EcColors.of(context);

    return Column(
      children: [
        EcScreenHeader(
          variant: EcHeaderVariant.tab,
          eyebrow: l10n.careInboxEyebrow,
          title: l10n.careInboxTitle,
          subtitle: l10n.careInboxSubtitle,
          showBack: false,
          actions: [
            IconButton(
              tooltip: l10n.careVoiceTooltip,
              onPressed: () => context.push('/voice'),
              icon: const Icon(Icons.mic_rounded),
            ),
            IconButton(
              tooltip: l10n.chatTitle,
              onPressed: () => context.push('/chat'),
              icon: const Icon(Icons.auto_awesome_rounded),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: EcGlassSurface(
            variant: EcGlassVariant.subtle,
            borderRadius: EcTokens.radiusFull,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(EcTokens.radiusFull),
                color: ec.accentBrand.withValues(alpha: 0.14),
              ),
              labelColor: ec.accentBrand,
              unselectedLabelColor: ec.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: -0.1,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: l10n.careInboxTabInbox),
                Tab(text: l10n.careInboxTabAi),
                Tab(text: l10n.careInboxTabPeople),
                Tab(text: l10n.careInboxTabAlerts),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _InboxList(inbox: inbox, profileId: profileId),
              const ChatScreen(embedded: true),
              const _PeopleHub(),
              const _AlertsHub(),
            ],
          ),
        ),
      ],
    );
  }
}

class _InboxList extends ConsumerWidget {
  const _InboxList({required this.inbox, this.profileId});

  final AsyncValue<List<CareInboxItem>> inbox;
  final String? profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return inbox.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(formatApiError(e))),
      data: (items) {
        if (items.isEmpty) {
          return EcEmptyState(
            icon: Icons.inbox_rounded,
            title: l10n.careInboxEmptyTitle,
            message: EcCopy.emptyInbox,
            action: FilledButton(
              onPressed: () => context.push('/chat'),
              child: Text(l10n.careInboxEmptyCta),
            ),
          );
        }
        return ListView.builder(
          padding: kEcGlassListPadding,
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return EcMotionEntrance(
              index: i,
              child: EcGlassListTile(
                icon: _iconFor(item.kind),
                title: item.title,
                subtitle: item.subtitle,
                onTap: item.route == null ? null : () => context.push(item.route!),
                trailing: item.unread
                    ? EcPill(label: l10n.careInboxNew, tone: EcPillTone.info)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconFor(CareInboxKind kind) => switch (kind) {
        CareInboxKind.message => Icons.chat_bubble_rounded,
        CareInboxKind.ai => Icons.auto_awesome_rounded,
        CareInboxKind.alert => Icons.notifications_rounded,
        CareInboxKind.digest => Icons.newspaper_rounded,
        CareInboxKind.moment => Icons.auto_stories_rounded,
        CareInboxKind.safety => Icons.shield_rounded,
      };
}

class _PeopleHub extends StatelessWidget {
  const _PeopleHub();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: kEcGlassListPadding,
      children: [
        EcPageHero(
          eyebrow: l10n.carePeopleEyebrow,
          title: l10n.carePeopleTitle,
          subtitle: l10n.carePeopleSubtitle,
          icon: Icons.people_rounded,
          accent: EcAccent.sky,
        ),
        const SizedBox(height: 12),
        EcGlassListGroup(
          tiles: [
            EcGlassListTile(
              icon: Icons.chat_bubble_rounded,
              title: l10n.carePeopleMessages,
              subtitle: l10n.carePeopleMessagesSub,
              onTap: () => context.push('/messages'),
            ),
            EcGlassListTile(
              icon: Icons.family_restroom_rounded,
              title: l10n.carePeopleCircle,
              onTap: () => context.push('/family-circle'),
            ),
            EcGlassListTile(
              icon: Icons.link_rounded,
              title: l10n.carePeopleConnections,
              onTap: () => context.push('/connections'),
            ),
            EcGlassListTile(
              icon: Icons.auto_stories_rounded,
              title: l10n.carePeopleMoments,
              onTap: () => context.push('/moments'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlertsHub extends StatelessWidget {
  const _AlertsHub();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: kEcGlassListPadding,
      children: [
        EcPageHero(
          eyebrow: l10n.careAlertsEyebrow,
          title: l10n.careAlertsTitle,
          subtitle: l10n.careAlertsSubtitle,
          icon: Icons.shield_moon_rounded,
          accent: EcAccent.amber,
        ),
        const SizedBox(height: 12),
        EcGlassListGroup(
          tiles: [
            EcGlassListTile(
              icon: Icons.shield_rounded,
              title: l10n.careAlertsSafety,
              onTap: () => context.push('/safety'),
            ),
            EcGlassListTile(
              icon: Icons.emergency_rounded,
              title: l10n.careAlertsEmergency,
              iconColor: EcTokens.statusCritical,
              onTap: () => context.push('/emergency'),
            ),
            EcGlassListTile(
              icon: Icons.flight_takeoff_rounded,
              title: l10n.careAlertsTravel,
              onTap: () => context.push('/travel-mode'),
            ),
            EcGlassListTile(
              icon: Icons.video_call_rounded,
              title: l10n.careAlertsTelehealth,
              onTap: () => context.push('/telehealth'),
            ),
          ],
        ),
      ],
    );
  }
}
