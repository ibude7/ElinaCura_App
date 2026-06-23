import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

// ═══════════════════════════════════════════════════════ MESSAGES SCREEN ══

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

    return Column(
      children: [
        // ── Header
        _MessagesHeader(),

        // ── Message list
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .doc(threadId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(60)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: EcErrorState(
                    message: 'Could not load messages',
                    onRetry: () => setState(() {}),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const EcEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No messages yet',
                  message:
                      'Start a conversation with your care circle. Keep each other in the loop.',
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
                    child: _ChatBubble(message: msg, isMine: isMine),
                  );
                },
              );
            },
          ),
        ),

        // ── Composer
        _MessageComposer(
          controller: _controller,
          onSend: () => _send(threadId, userId),
        ),
      ],
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

class _MessagesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : EcTokens.textPrimaryLight;
    final ec = EcColors.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: EcTokens.glassBlurZ3,
          sigmaY: EcTokens.glassBlurZ3,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, top + 14, 20, 14),
          decoration: BoxDecoration(
            color: EcGlass.of(context).fillFloat,
            border: Border(
              bottom: BorderSide(
                color: EcGlass.of(context).border,
              ),
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MESSAGES',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: ec.textMuted,
                      fontFamily: EcTokens.fontFamily,
                    ),
                  ),
                  Text(
                    'Care circle',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: textColor,
                      fontFamily: EcTokens.fontFamily,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          ),
          child: EcGlassSurface(
            variant: isMine ? EcGlassVariant.tinted : EcGlassVariant.regular,
            tint: isMine ? ec.accentBrand : null,
            borderRadius: isMine ? 20 : 20,
            blur: EcTokens.glassBlurZ3,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    color: isMine ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.timestamp.isNotEmpty)
                      Text(
                        message.timestamp,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.65)
                              : ec.textMuted,
                        ),
                      ),
                    if (isMine && message.read) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final ec = EcColors.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 6, 12, bottom + 10 + kEcNavBottomPadding - 60),
      child: EcGlassSurface(
        variant: EcGlassVariant.float,
        borderRadius: EcTokens.radiusHero,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Send a message…',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ec.accentBrand,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.white, size: 20),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════ CONNECTIONS SCREEN ══

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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invite sent')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invite failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Care circle'),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          EcGlassEntrance(
            index: 0,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EcColors.of(context)
                              .accentBrand
                              .withValues(alpha: 0.14),
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          color: EcColors.of(context).accentBrand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite a caregiver',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'They get limited read access to your care data.',
                              style: TextStyle(
                                fontSize: 12,
                                color: EcColors.of(context).textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Caregiver email address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  EcGlassButton(
                    label: _loading ? 'Sending…' : 'Send invite',
                    loading: _loading,
                    icon: Icons.send_rounded,
                    onPressed: _loading ? null : _invite,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          EcSectionTitle(title: 'Active caregivers'),
          ref.watch(caregiverAccessProvider).when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => EcErrorState(
              message: 'Could not load connections',
              onRetry: () => ref.invalidate(caregiverAccessProvider),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return EcEmptyState(
                  icon: Icons.diversity_1_rounded,
                  title: 'No caregivers yet',
                  message:
                      'Invite someone you trust to help monitor your care routines.',
                );
              }
              return Column(
                children: entries.asMap().entries.map((e) {
                  return EcGlassEntrance(
                    index: e.key,
                    child: EcGlassListTile(
                      icon: Icons.person_rounded,
                      title: e.value.profileId,
                      subtitle: e.value.status,
                      iconColor: e.value.status == 'active'
                          ? EcColors.of(context).accentMint
                          : EcColors.of(context).accentAmberText,
                      trailing: EcPill(
                        label: e.value.status,
                        tone: e.value.status == 'active'
                            ? EcPillTone.positive
                            : EcPillTone.caution,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════ CAREGIVER DASHBOARD SCREEN ══

class CaregiverDashboardScreen extends ConsumerWidget {
  const CaregiverDashboardScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(caregiverDashboardProvider(profileId));
    final top = MediaQuery.paddingOf(context).top;

    return dashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: EcErrorState(
          message: 'Could not load caregiver view',
          onRetry: () => ref.invalidate(caregiverDashboardProvider(profileId)),
        ),
      ),
      data: (data) => ListView(
        padding: EdgeInsets.fromLTRB(20, top + 16, 20, kEcNavBottomPadding),
        children: [
          // ── Header
          _CaregiverHeader(),
          const SizedBox(height: 24),

          // ── Adherence ring
          Center(
            child: EcHealthRing(
              score: (data.adherenceRate7d ?? 0.0) / 100,
              size: 160,
              label: '7-day adherence',
              accentColor: EcColors.of(context).accentBrand,
            ),
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.88, 0.88),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 24),

          // ── Metric strip
          Row(
            children: [
              Expanded(
                child: EcMetricTile(
                  label: 'Active meds',
                  value: '${data.activeMedications.length}',
                  icon: Icons.medication_rounded,
                  tone: EcPillTone.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EcMetricTile(
                  label: 'Missed (7d)',
                  value: '${data.missedDoseCount}',
                  icon: Icons.warning_amber_rounded,
                  tone: data.missedDoseCount > 0
                      ? EcPillTone.caution
                      : EcPillTone.positive,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EcMetricTile(
                  label: 'Events',
                  value: '${data.safetyEvents.length}',
                  icon: Icons.shield_rounded,
                  tone: data.safetyEvents.isNotEmpty
                      ? EcPillTone.critical
                      : EcPillTone.positive,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 20),

          // ── Clinician summary
          if (data.clinicianSummary != null && data.clinicianSummary!.isNotEmpty) ...[
            EcSectionTitle(title: 'Clinician summary'),
            EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.all(18),
              child: Text(
                data.clinicianSummary!['text']?.toString() ??
                    data.clinicianSummary!.values.join(' '),
                style: TextStyle(
                  color: EcColors.of(context).textSecondary,
                  height: 1.55,
                ),
              ),
            ).animate().fadeIn(delay: 120.ms),
            const SizedBox(height: 20),
          ],

          // ── Safety events
          if (data.safetyEvents.isNotEmpty) ...[
            EcSectionTitle(title: 'Safety events'),
            ...data.safetyEvents.asMap().entries.map(
              (e) => EcGlassEntrance(
                index: e.key,
                child: _SafetyEventTile(event: e.value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CaregiverHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : EcTokens.textPrimaryLight;
    final ec = EcColors.of(context);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CAREGIVER VIEW',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: ec.textMuted,
                fontFamily: EcTokens.fontFamily,
              ),
            ),
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: textColor,
                fontFamily: EcTokens.fontFamily,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton.filledTonal(
          icon: const Icon(Icons.emergency_rounded,
              color: EcTokens.statusCritical, size: 20),
          onPressed: () => context.push('/emergency'),
          style: IconButton.styleFrom(
            backgroundColor:
                EcTokens.statusCritical.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}

class _SafetyEventTile extends StatelessWidget {
  const _SafetyEventTile({required this.event});

  final SafetyEvent event;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final level = event.level ?? 'info';
    final (tone, color) = switch (level) {
      'critical' => (EcPillTone.critical, ec.textCritical),
      'warning' => (EcPillTone.caution, ec.accentAmberText),
      _ => (EcPillTone.info, ec.accentSky),
    };

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusCard,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(
              level == 'critical'
                  ? Icons.emergency_rounded
                  : Icons.warning_amber_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.displayText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (event.source != null && event.source!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.source!,
                    style: TextStyle(fontSize: 12, color: ec.textMuted),
                  ),
                ],
              ],
            ),
          ),
          EcPill(label: level, tone: tone),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════ MORE MENU SCREEN ══

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'More'),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          EcGlassEntrance(
            index: 0,
            child: EcGlassListTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Barcode scanner',
              subtitle: 'Check product safety labels',
              onTap: () => context.push('/scanner'),
            ),
          ),
          EcGlassEntrance(
            index: 1,
            child: EcGlassListTile(
              icon: Icons.calendar_today_rounded,
              title: 'Refill calendar',
              subtitle: 'Upcoming medication refills',
              iconColor: EcColors.of(context).accentMint,
              onTap: () => context.push('/refill'),
            ),
          ),
          EcGlassEntrance(
            index: 2,
            child: EcGlassListTile(
              icon: Icons.shield_moon_rounded,
              title: 'Safety monitoring',
              subtitle: 'Review safety events and alerts',
              iconColor: EcColors.of(context).accentAmberText,
              onTap: () => context.push('/safety'),
            ),
          ),
          EcGlassEntrance(
            index: 3,
            child: EcGlassListTile(
              icon: Icons.document_scanner_rounded,
              title: 'Medication OCR',
              subtitle: 'Scan and capture medication labels',
              iconColor: EcColors.of(context).accentPlum,
              onTap: () => context.push('/ocr'),
            ),
          ),
          EcGlassEntrance(
            index: 4,
            child: EcGlassListTile(
              icon: Icons.people_rounded,
              title: 'Care circle',
              subtitle: 'Manage caregiver connections',
              onTap: () => context.push('/connections'),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════ SAFETY SCREEN ══

class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ec = EcColors.of(context);

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Safety'),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          // ── Status card
          EcGlassEntrance(
            index: 0,
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ec.accentMint.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: ec.accentMint,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All clear',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No safety events detected in the past 7 days.',
                          style: TextStyle(
                            color: ec.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  EcPill(label: 'Safe', tone: EcPillTone.positive),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Monitoring features
          EcSectionTitle(title: 'Active monitoring'),
          EcGlassEntrance(
            index: 1,
            child: EcGlassListTile(
              icon: Icons.medication_rounded,
              title: 'Medication adherence',
              subtitle: 'Tracks daily dose completion',
              iconColor: ec.accentMint,
              trailing: EcPill(label: 'Active', tone: EcPillTone.positive),
            ),
          ),
          EcGlassEntrance(
            index: 2,
            child: EcGlassListTile(
              icon: Icons.notifications_rounded,
              title: 'Missed-dose alerts',
              subtitle: 'Notifies caregiver on 2+ missed doses',
              iconColor: ec.accentAmberText,
              trailing: EcPill(label: 'Active', tone: EcPillTone.positive),
            ),
          ),
          EcGlassEntrance(
            index: 3,
            child: EcGlassListTile(
              icon: Icons.emergency_rounded,
              title: 'Emergency access',
              subtitle: 'Your Medical ID is always accessible',
              iconColor: EcTokens.statusCritical,
              onTap: () => context.push('/emergency'),
            ),
          ),

          const SizedBox(height: 20),
          EcSectionTitle(title: 'Coming soon'),
          EcGlassEntrance(
            index: 4,
            child: EcGlassSurface(
              variant: EcGlassVariant.subtle,
              borderRadius: EcTokens.radiusCard,
              padding: const EdgeInsets.all(16),
              child: Text(
                'Fall detection, wearable integration, and advanced pattern monitoring are in development.',
                style: TextStyle(
                  color: ec.textSecondary,
                  height: 1.5,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
