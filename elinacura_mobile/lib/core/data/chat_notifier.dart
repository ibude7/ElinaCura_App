import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import '../connectivity/connectivity_provider.dart';
import '../network/offline_queue.dart';
import 'chat_stream.dart';
import 'engagement_repository.dart';

/// Riverpod chat state (Rec #27) with offline queue (Rec #29).
class ChatState {
  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.streamingAssistant = '',
    this.error,
    this.queuedOffline = false,
  });

  final List<ChatHistoryMessage> messages;
  final bool loading;
  final bool sending;
  final String streamingAssistant;
  final String? error;
  final bool queuedOffline;

  ChatState copyWith({
    List<ChatHistoryMessage>? messages,
    bool? loading,
    bool? sending,
    String? streamingAssistant,
    String? error,
    bool? queuedOffline,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      streamingAssistant: streamingAssistant ?? this.streamingAssistant,
      error: clearError ? null : (error ?? this.error),
      queuedOffline: queuedOffline ?? this.queuedOffline,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._repo, this._ref) : super(const ChatState());

  final EngagementRepository _repo;
  final Ref _ref;

  Future<void> load(String profileId) async {
    state = state.copyWith(loading: true, clearError: true);
    final result = await _repo.getChatHistoryResult(profileId);
    result.when(
      success: (rows) =>
          state = state.copyWith(messages: rows, loading: false),
      failure: (msg, _) =>
          state = state.copyWith(loading: false, error: msg),
    );
  }

  Future<ChatStreamDone?> send({
    required String profileId,
    required String text,
    String offlineMessage =
        'Your message is queued and will send when you\'re back online.',
  }) async {
    if (text.trim().isEmpty || state.sending) return null;

    final online = _ref.read(connectivityProvider).valueOrNull ?? true;

    state = state.copyWith(
      sending: true,
      clearError: true,
      streamingAssistant: '',
      queuedOffline: false,
      messages: [
        ...state.messages,
        ChatHistoryMessage(
          id: 'local-u-${DateTime.now().millisecondsSinceEpoch}',
          role: 'user',
          content: text.trim(),
        ),
      ],
    );

    if (!online) {
      await _ref.read(offlineQueueProvider.notifier).enqueue(
            method: 'POST',
            path: '/chat',
            body: {
              'profile_id': profileId,
              'message': text.trim(),
            },
          );
      state = state.copyWith(
        sending: false,
        queuedOffline: true,
        messages: [
          ...state.messages,
          ChatHistoryMessage(
            id: 'local-offline-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: offlineMessage,
          ),
        ],
      );
      return null;
    }

    try {
      var assistantText = '';
      ChatStreamDone? done;

      await for (final event in _repo.streamChat(
        profileId: profileId,
        message: text.trim(),
      )) {
        switch (event) {
          case ChatStreamDelta(:final text):
            assistantText += text;
            state = state.copyWith(streamingAssistant: assistantText);
          case ChatStreamDone():
            done = event;
        }
      }

      final finalText = assistantText.isNotEmpty
          ? assistantText
          : 'I could not generate a response right now. Please try again.';

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatHistoryMessage(
            id: 'local-a-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: finalText,
          ),
        ],
        streamingAssistant: '',
        sending: false,
      );
      return done;
    } catch (e) {
      try {
        final reply = await _repo.sendChat(
          profileId: profileId,
          message: text.trim(),
        );
        state = state.copyWith(
          messages: [
            ...state.messages,
            ChatHistoryMessage(
              id: 'local-a-${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              content: reply.response,
            ),
          ],
          streamingAssistant: '',
          sending: false,
          clearError: true,
        );
        return ChatStreamDone(
          escalated: reply.escalated,
          riskLevel: reply.riskLevel,
        );
      } catch (_) {
        await _ref.read(offlineQueueProvider.notifier).enqueue(
              method: 'POST',
              path: '/chat',
              body: {
                'profile_id': profileId,
                'message': text.trim(),
              },
            );
        state = state.copyWith(
          sending: false,
          streamingAssistant: '',
          queuedOffline: true,
          messages: [
            ...state.messages,
            ChatHistoryMessage(
              id: 'local-offline-${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              content: offlineMessage,
            ),
          ],
        );
        return null;
      }
    }
  }

  Future<void> clear(String profileId) async {
    await _repo.clearChatHistory(profileId);
    state = const ChatState();
  }
}

final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, profileId) {
    final notifier = ChatNotifier(
      ref.watch(engagementRepositoryProvider),
      ref,
    );
    notifier.load(profileId);
    return notifier;
  },
);
