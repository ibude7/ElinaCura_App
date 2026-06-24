/// Events emitted by [EngagementRepository.streamChat].
sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

final class ChatStreamDelta extends ChatStreamEvent {
  const ChatStreamDelta(this.text);
  final String text;
}

final class ChatStreamDone extends ChatStreamEvent {
  const ChatStreamDone({
    this.escalated = false,
    this.riskLevel,
    this.mode,
  });

  final bool escalated;
  final String? riskLevel;
  final String? mode;
}
