import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/ec_copy.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../core/theme/ec_type.dart';
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
                  child: _CareCircleError(onRetry: () => setState(() {})),
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
    const radius = 18.0;

    Widget bubble = EcGlassSurface(
      // Sent = L1 (Frosted) · Received = L2 (Deep Frost) + gold hairline.
      variant: isMine ? EcGlassVariant.regular : EcGlassVariant.elevated,
      borderRadius: radius,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: const TextStyle(fontSize: 14.5, height: 1.4),
          ),
          if (message.timestamp.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              message.timestamp,
              style: EcType.mono(
                color: isMine ? ec.textMuted : EcTokens.accentGold,
                size: 10,
              ),
            ),
          ],
        ],
      ),
    );

    if (!isMine) {
      bubble = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: EcTokens.accentGold.withValues(alpha: 0.5),
            width: 0.6,
          ),
        ),
        child: bubble,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          ),
          child: bubble,
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

/// Beautiful connection-error state: two hands passing a note, with a warm
/// reassuring line and a gold retry — never a cold cloud icon.
class _CareCircleError extends StatelessWidget {
  const _CareCircleError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 120,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        EcTokens.accentGold.withValues(alpha: 0.16),
                        EcTokens.accentGold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  child: Transform.rotate(
                    angle: 0.32,
                    child: Icon(Icons.front_hand_rounded,
                        size: 48, color: EcTokens.accentJade.withValues(alpha: 0.85)),
                  ),
                ),
                Positioned(
                  right: 6,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14159)..rotateZ(0.32),
                    child: Icon(Icons.front_hand_rounded,
                        size: 48, color: EcTokens.accentJade.withValues(alpha: 0.85)),
                  ),
                ),
                Icon(Icons.sticky_note_2_rounded,
                        size: 40, color: EcTokens.accentGold)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -5, end: 5, duration: 1800.ms, curve: Curves.easeInOut),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Your care circle is waiting',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: TextStyle(color: ec.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          EcGlassButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
