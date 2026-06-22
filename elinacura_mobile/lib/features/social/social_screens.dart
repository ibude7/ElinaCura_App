import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/utils/health_overview_builder.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _controller = TextEditingController();
  String? _threadId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _resolveThreadId() {
    final user = FirebaseAuth.instance.currentUser;
    return _threadId ?? user?.uid ?? 'default';
  }

  @override
  Widget build(BuildContext context) {
    final threadId = _resolveThreadId();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return EcTabPage(
      title: 'Messages',
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(threadId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return EcErrorState(
                    message: 'Could not load messages',
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const EcEmptyState(
                    icon: Icons.chat_bubble_rounded,
                    title: 'No messages yet',
                    message:
                        'Start a conversation with your care circle when something needs context.',
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final msg = ChatMessage.fromFirestore(
                      docs[i].id,
                      docs[i].data(),
                    );
                    final isMine = msg.senderId == userId;
                    return EcGlassEntrance(
                      index: i.clamp(0, 8),
                      child: Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: EcGlassSurface(
                          variant: isMine
                              ? EcGlassVariant.tinted
                              : EcGlassVariant.subtle,
                          tint: isMine
                              ? EcColors.of(context).accentBrand
                              : null,
                          borderRadius: 22,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(msg.text),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: EcGlassSurface(
                variant: EcGlassVariant.elevated,
                borderRadius: EcTokens.radiusHero,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message…',
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: () => _send(threadId, userId),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String threadId, String userId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(threadId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
  }
}

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        '/connections/invite',
        data: {'email': _emailController.text.trim()},
      );
      _emailController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invite sent')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invite failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Connections'),
      body: Padding(
        padding: kEcGlassTabPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EcGlassEntrance(
              index: 0,
              child: EcScreenHero(
                eyebrow: 'Care circle',
                title: 'Invite trusted support',
                subtitle:
                    'Caregiver access keeps the right people close without turning your profile into a shared account.',
                icon: Icons.people_rounded,
                trailing: const EcPill(
                  label: 'Private',
                  tone: EcPillTone.positive,
                ),
              ),
            ),
            const SizedBox(height: 14),
            EcGlassEntrance(
              index: 1,
              child: EcCard(
                elevated: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    EcGlassButton(
                      label: _loading ? 'Sending…' : 'Send invite',
                      loading: _loading,
                      onPressed: _loading ? null : _invite,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const EcSectionTitle(title: 'Active caregiver access'),
            Expanded(
              child: ref
                  .watch(caregiverAccessProvider)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => EcErrorState(
                      message: 'Could not load connections',
                      onRetry: () => ref.invalidate(caregiverAccessProvider),
                    ),
                    data: (entries) {
                      if (entries.isEmpty) {
                        return Center(
                          child: EcEmptyState(
                            icon: Icons.diversity_1_rounded,
                            title: 'No active caregiver links',
                            message:
                                'Invite a caregiver when you want someone to help monitor routines and appointments.',
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, i) => EcGlassEntrance(
                          index: i,
                          child: EcCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: EcColors.of(context).accentSkyFill,
                                  ),
                                  child: const Icon(Icons.people_rounded),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Caregiver link ${entries[i].id.substring(0, 8)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Profile: ${entries[i].profileId}',
                                        style: TextStyle(
                                          color: EcColors.of(
                                            context,
                                          ).textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class CaregiverDashboardScreen extends ConsumerWidget {
  const CaregiverDashboardScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(caregiverDashboardProvider(profileId));
    return EcTabPage(
      title: 'Caregiver dashboard',
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _CaregiverContent(
          data: const CaregiverDashboardData(profileId: '', missedDoseCount: 0),
          isSample: true,
          onRetry: () =>
              ref.read(caregiverDashboardProvider(profileId).notifier).retry(),
        ),
        data: (data) => _CaregiverContent(data: data, isSample: false),
      ),
    );
  }
}

class _CaregiverContent extends StatelessWidget {
  const _CaregiverContent({
    required this.data,
    this.isSample = false,
    this.onRetry,
  });

  final CaregiverDashboardData data;
  final bool isSample;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return ListView(
      padding: kEcGlassTabPadding,
      children: [
        if (isSample)
          EcGlassEntrance(
            index: 0,
            child: EcCard(
              variant: EcGlassVariant.tinted,
              tint: ec.accentAmberFill,
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: ec.accentAmberText),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Sample data — backend unreachable'),
                  ),
                  if (onRetry != null)
                    TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        if (isSample) const SizedBox(height: 16),
        EcGlassEntrance(
          index: 1,
          child: EcScreenHero(
            eyebrow: 'Caregiver view',
            title: 'Care signals at a glance',
            subtitle:
                'Monitor adherence, missed doses, safety events, and profile context for the selected patient.',
            icon: Icons.dashboard_rounded,
            trailing: EcPill(
              label: isSample ? 'Sample' : 'Live',
              tone: isSample ? EcPillTone.caution : EcPillTone.positive,
            ),
          ),
        ),
        const SizedBox(height: 16),
        EcGlassEntrance(
          index: 2,
          child: Row(
            children: [
              Expanded(
                child: EcMetricTile(
                  label: 'Adherence',
                  value: data.adherencePercent != null
                      ? '${data.adherencePercent}%'
                      : '—',
                  icon: Icons.check_circle_rounded,
                  tone: EcPillTone.positive,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EcMetricTile(
                  label: 'Missed doses',
                  value: '${data.missedDoseCount}',
                  icon: Icons.alarm_off_rounded,
                  tone: data.missedDoseCount > 0
                      ? EcPillTone.caution
                      : EcPillTone.positive,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EcGlassEntrance(
          index: 3,
          child: EcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EcSectionTitle(title: 'Active medications'),
                if (data.activeMedications.isEmpty)
                  Text('None', style: TextStyle(color: ec.textMuted))
                else
                  ...data.activeMedications.map(
                    (m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medication_rounded,
                            color: ec.accentBrand,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(m)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        EcGlassEntrance(
          index: 4,
          child: EcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EcSectionTitle(title: 'Safety alerts'),
                if (data.safetyEvents.isEmpty)
                  Text('No alerts', style: TextStyle(color: ec.textMuted))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.safetyEvents.map((e) {
                      final tone = riskTone(e.level);
                      return EcPill(
                        label: e.displayText,
                        tone: tone == 'critical'
                            ? EcPillTone.critical
                            : tone == 'caution'
                            ? EcPillTone.caution
                            : EcPillTone.neutral,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        if (data.clinicianSummary != null) ...[
          const SizedBox(height: 16),
          EcGlassEntrance(
            index: 5,
            child: EcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EcSectionTitle(title: 'Clinician summary'),
                  if (data.clinicianSummary!['conditions'] is List)
                    _SummaryList(
                      'Conditions',
                      (data.clinicianSummary!['conditions'] as List)
                          .cast<String>(),
                    ),
                  if (data.clinicianSummary!['allergies'] is List)
                    _SummaryList(
                      'Allergies',
                      (data.clinicianSummary!['allergies'] as List)
                          .cast<String>(),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        EcGlassEntrance(
          index: 6,
          child: Row(
            children: [
              Expanded(
                child: EcGlassButton(
                  label: 'Message',
                  icon: Icons.message_rounded,
                  onPressed: () => context.push('/messages'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EcGlassButton(
                  label: '911',
                  icon: Icons.phone_rounded,
                  onPressed: () => launchUrl(Uri.parse('tel:911')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList(this.title, this.items);

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(items.join(', ')),
        ],
      ),
    );
  }
}

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Reminders', Icons.alarm_rounded, '/reminders'),
      ('Refill calendar', Icons.calendar_month_rounded, '/refill'),
      ('Scan prescription', Icons.document_scanner_rounded, '/ocr'),
      ('Barcode scanner', Icons.qr_code_scanner_rounded, '/scanner'),
      ('Connections', Icons.people_rounded, '/connections'),
      ('Safety', Icons.shield_rounded, '/safety'),
      ('Settings', Icons.settings_rounded, '/settings'),
    ];
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'More'),
      body: ListView(
        padding: kEcGlassTabPadding,
        children: [
          const EcGlassEntrance(
            index: 0,
            child: EcScreenHero(
              eyebrow: 'Care tools',
              title: 'Everything else, organized',
              subtitle:
                  'Find planning, scanning, safety, and account tools without losing the calm care rhythm.',
              icon: Icons.apps_rounded,
            ),
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map(
            (e) => EcGlassEntrance(
              index: e.key + 1,
              child: EcGlassListTile(
                icon: e.value.$2,
                title: e.value.$1,
                onTap: () => context.push(e.value.$3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Safety'),
      body: ListView(
        padding: kEcGlassTabPadding,
        children: [
          EcGlassEntrance(
            index: 0,
            child: EcScreenHero(
              eyebrow: 'Safety monitoring',
              title: 'Risks stay visible',
              subtitle:
                  'Review medication interactions, missed-dose signals, and health anomalies from one focused safety hub.',
              icon: Icons.shield_rounded,
              trailing: const EcPill(label: 'Clear', tone: EcPillTone.positive),
            ),
          ),
          const SizedBox(height: 16),
          EcGlassEntrance(
            index: 1,
            child: EcGlassListTile(
              icon: Icons.warning_amber_rounded,
              title: 'Active alerts',
              subtitle: 'No critical alerts right now',
              iconColor: ec.accentAmberText,
              trailing: EcPill(label: 'Clear', tone: EcPillTone.positive),
              onTap: () {},
            ),
          ),
          EcGlassEntrance(
            index: 2,
            child: EcGlassListTile(
              icon: Icons.history_rounded,
              title: 'Event log',
              subtitle: 'Review past safety events',
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
