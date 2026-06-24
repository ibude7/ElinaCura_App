import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/data/engagement_repository.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_engagement.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<ChatHistoryMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  static const _suggestions = [
    'What should I watch for with my medications?',
    'Help me plan a heart-healthy day',
    'Summarize my care priorities',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final profileId = activeProfileId(ref);
    if (profileId == null) {
      setState(() {
        _loading = false;
        _messages = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows =
          await ref.read(engagementRepositoryProvider).getChatHistory(profileId);
      if (mounted) {
        setState(() {
          _messages = rows;
          _loading = false;
        });
        _scrollToEnd();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = formatApiError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _send([String? preset]) async {
    final profileId = activeProfileId(ref);
    final text = (preset ?? _controller.text).trim();
    if (profileId == null || text.isEmpty || _sending) return;

    _controller.clear();
    setState(() {
      _sending = true;
      _error = null;
      _messages = [
        ..._messages,
        ChatHistoryMessage(id: 'local-u-${DateTime.now().millisecondsSinceEpoch}', role: 'user', content: text),
      ];
    });
    _scrollToEnd();

    try {
      final reply = await ref.read(engagementRepositoryProvider).sendChat(
            profileId: profileId,
            message: text,
          );
      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages,
          ChatHistoryMessage(
            id: 'local-a-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: reply.response,
          ),
        ];
        _sending = false;
      });
      if (reply.escalated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Safety guidance was triggered for this message.'),
          ),
        );
      }
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = formatApiError(e);
        _sending = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final profileId = activeProfileId(ref);
    if (profileId == null) return;
    await ref.read(engagementRepositoryProvider).clearChatHistory(profileId);
    if (mounted) {
      setState(() => _messages = []);
    }
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

  @override
  Widget build(BuildContext context) {
    final profileId = activeProfileId(ref);
    final ec = EcColors.of(context);

    return EcGlassScaffold(
      appBar: EcAppBar(
        title: 'Care AI',
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: profileId == null
          ? const EcEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Complete your profile',
              message: 'Care AI uses your health profile for personalized guidance.',
            )
          : Column(
              children: [
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          controller: _scroll,
                          padding: kEcGlassListPadding,
                          children: [
                            EcGlassEntrance(
                              index: 0,
                              child: EcEngagementHero(
                                title: 'Ask ElinaCura',
                                subtitle:
                                    'Profile-aware guidance for medications, nutrition, and daily care.',
                                icon: Icons.auto_awesome_rounded,
                                accent: ec.accentBrand,
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              EcErrorState(message: _error!, onRetry: _loadHistory),
                            ],
                            if (_messages.isEmpty && !_loading) ...[
                              const SizedBox(height: 16),
                              const EcEmptyState(
                                icon: Icons.forum_outlined,
                                title: 'Start a conversation',
                                message: 'Ask about medications, meals, or your care plan.',
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _suggestions
                                    .map(
                                      (s) => ActionChip(
                                        label: Text(s),
                                        onPressed: _sending ? null : () => _send(s),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                            ..._messages.map(_ChatBubble.new),
                            if (_sending)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                _Composer(
                  controller: _controller,
                  enabled: !_sending,
                  onSend: () => _send(),
                ),
              ],
            ),
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
          child: EcGlassSurface(
            variant: isAssistant ? EcGlassVariant.regular : EcGlassVariant.elevated,
            tint: isAssistant ? null : ec.accentBrand.withValues(alpha: 0.08),
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.45,
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
                  hintText: 'Ask about your care…',
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
