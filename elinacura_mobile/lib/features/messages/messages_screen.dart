import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/ec_copy.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_screen_header.dart';
import '../../shared/widgets/ec_widgets.dart';

/// Human care-circle messaging (extracted from social monolith, Rec #26).
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _resolveThreadId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'default';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final threadId = _resolveThreadId();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Column(
      children: [
        EcScreenHeader(
          variant: EcHeaderVariant.tab,
          eyebrow: l10n.t('nav.messages', fallback: 'Messages'),
          title: l10n.t('familyCircle.title', fallback: 'Care circle'),
          showBack: false,
        ),
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
                return EcEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No messages yet',
                  message: EcCopy.emptyInbox,
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
                    child: _MessageBubble(message: msg, isMine: isMine),
                  );
                },
              );
            },
          ),
        ),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

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
            borderRadius: 20,
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
                if (message.timestamp.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message.timestamp,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.65)
                          : ec.textMuted,
                    ),
                  ),
                ],
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
    final onAccent = Theme.of(context).brightness == Brightness.dark
        ? EcTokens.onAccentDark
        : EcTokens.onAccentLight;

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
                tooltip: 'Send message',
                icon: Icon(Icons.arrow_upward_rounded, color: onAccent, size: 20),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
