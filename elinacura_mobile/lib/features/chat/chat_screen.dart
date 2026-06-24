import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/ec_copy.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/data/chat_notifier.dart';
import '../../core/data/engagement_repository.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_outcome_hero.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_widgets.dart';
import '../safety/safety_escalation_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  static const _suggestions = [
    'What should I watch for with my medications?',
    'Help me plan a heart-healthy day',
    'Summarize my care priorities',
  ];

  static const _topics = [
    ('Medications', 'Review my medication schedule and interactions'),
    ('Nutrition', 'What should I eat today given my conditions?'),
    ('Symptoms', 'I have a new symptom — what should I track?'),
    ('Care plan', 'Summarize my priorities for this week'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String profileId, [String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.clear();
    final l10n = context.l10n;
    final done = await ref.read(chatNotifierProvider(profileId).notifier).send(
          profileId: profileId,
          text: text,
          offlineMessage: l10n.chatOfflineQueued,
        );
    _scrollToEnd();
    if (!mounted || done == null) return;
    if (done.escalated) {
      final chat = ref.read(chatNotifierProvider(profileId));
      final lastAssistant = chat.messages.lastWhere(
        (m) => m.isAssistant,
        orElse: () => const ChatHistoryMessage(
          id: '',
          role: 'assistant',
          content: '',
        ),
      );
      await showSafetyEscalationSheet(
        context,
        message: lastAssistant.content,
        riskLevel: done.riskLevel,
        onEmergency: () => context.push('/emergency'),
      );
    }
  }

  Future<void> _clearHistory(String profileId) async {
    await ref.read(chatNotifierProvider(profileId).notifier).clear(profileId);
  }

  List<Widget> _messagesWithSeparators(
    BuildContext context,
    List<ChatHistoryMessage> messages,
  ) {
    final ec = EcColors.of(context);
    final out = <Widget>[];
    String? lastDay;
    for (final msg in messages) {
      final parsed =
          msg.createdAt != null ? DateTime.tryParse(msg.createdAt!) : null;
      final day = parsed != null
          ? MaterialLocalizations.of(context).formatMediumDate(parsed)
          : 'Today';
      if (day != lastDay) {
        lastDay = day;
        out.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ec.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        );
      }
      out.add(_ChatBubble(msg));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final profileId = activeProfileId(ref);

    if (profileId != null) {
      ref.listen(chatNotifierProvider(profileId), (prev, next) {
        if (prev?.streamingAssistant != next.streamingAssistant ||
            prev?.messages.length != next.messages.length) {
          _scrollToEnd();
        }
      });
    }

    final body = profileId == null
        ? EcEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: context.l10n.t('chatPage.noProfile', fallback: 'Complete your profile'),
            message: EcCopy.noProfile,
          )
        : Builder(
            builder: (context) {
              final l10n = context.l10n;
              final chat = ref.watch(chatNotifierProvider(profileId));
              final sending = chat.sending;

              return Column(
                children: [
                  Expanded(
                    child: chat.loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            controller: _scroll,
                            padding: kEcGlassListPadding,
                            children: [
                              if (!widget.embedded) ...[
                                EcGlassEntrance(
                                  index: 0,
                                  child: EcOutcomeHero(
                                    eyebrow: l10n.chatEyebrow,
                                    title: l10n.chatHeroHeadline,
                                    subtitle: l10n.chatSubtitle,
                                    icon: Icons.auto_awesome_rounded,
                                    accent: EcAccent.brand,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _topics
                                        .map(
                                          (t) => Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: ActionChip(
                                              label: Text(t.$1),
                                              onPressed: sending
                                                  ? null
                                                  : () => _send(
                                                        profileId,
                                                        t.$2,
                                                      ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                              if (chat.error != null) ...[
                                const SizedBox(height: 12),
                                EcErrorState(
                                  message: chat.error!,
                                  onRetry: () => ref
                                      .read(
                                        chatNotifierProvider(profileId)
                                            .notifier,
                                      )
                                      .load(profileId),
                                ),
                              ],
                              if (chat.messages.isEmpty && !chat.loading) ...[
                                const SizedBox(height: 16),
                                EcEmptyState(
                                  icon: Icons.forum_outlined,
                                  title: l10n.chatWelcomeTitle,
                                  message: l10n.chatWelcomeSub,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _suggestions
                                      .map(
                                        (s) => ActionChip(
                                          label: Text(s),
                                          onPressed: sending
                                              ? null
                                              : () => _send(profileId, s),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 12),
                              ..._messagesWithSeparators(
                                context,
                                chat.messages,
                              ),
                              if (chat.streamingAssistant.isNotEmpty)
                                _ChatBubble(
                                  ChatHistoryMessage(
                                    id: 'stream',
                                    role: 'assistant',
                                    content: chat.streamingAssistant,
                                  ),
                                ),
                              if (sending && chat.streamingAssistant.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  _Composer(
                    controller: _controller,
                    enabled: !sending,
                    onSend: () => _send(profileId),
                  ),
                ],
              );
            },
          );

    if (widget.embedded) return body;

    final hasMessages = profileId != null &&
        ref.watch(chatNotifierProvider(profileId)).messages.isNotEmpty;

    return EcGlassScaffold(
      appBar: EcAppBar(
        title: context.l10n.chatTitle,
        actions: [
          if (hasMessages)
            IconButton(
              tooltip: 'Clear history',
              onPressed: () => _clearHistory(profileId),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble(this.message);

  final ChatHistoryMessage message;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isAssistant = message.isAssistant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isAssistant ? Alignment.centerLeft : Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          child: GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: message.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: EcGlassSurface(
              variant: isAssistant
                  ? EcGlassVariant.regular
                  : EcGlassVariant.elevated,
              tint: isAssistant
                  ? null
                  : ec.accentBrand.withValues(alpha: 0.08),
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                message.content,
                style: const TextStyle(fontSize: 14.5, height: 1.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
                decoration: InputDecoration(
                  hintText: context.l10n.chatPlaceholder,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
