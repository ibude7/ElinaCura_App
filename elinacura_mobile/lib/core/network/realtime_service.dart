import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_providers.dart';

/// SSE / realtime events for chat, safety, caregiver alerts (Rec #34).
sealed class RealtimeEvent {
  const RealtimeEvent();
}

final class RealtimeChatDelta extends RealtimeEvent {
  const RealtimeChatDelta(this.text);
  final String text;
}

final class RealtimeSafetyFlag extends RealtimeEvent {
  const RealtimeSafetyFlag({required this.message, this.level});
  final String message;
  final String? level;
}

final class RealtimeCaregiverAlert extends RealtimeEvent {
  const RealtimeCaregiverAlert({required this.title, required this.body});
  final String title;
  final String body;
}

class RealtimeService {
  RealtimeService(this._api);

  final ApiClient _api;
  CancelToken? _token;

  Stream<RealtimeEvent> connect(String profileId) async* {
    _token?.cancel();
    _token = CancelToken();
    try {
      await for (final obj in _api.postNdjsonStream(
        '/realtime/$profileId',
        data: {'profile_id': profileId},
        cancelToken: _token,
      )) {
        final type = obj['type'] as String?;
        switch (type) {
          case 'chat_delta':
            yield RealtimeChatDelta(obj['text'] as String? ?? '');
          case 'safety_flag':
            yield RealtimeSafetyFlag(
              message: obj['message'] as String? ?? '',
              level: obj['level'] as String?,
            );
          case 'caregiver_alert':
            yield RealtimeCaregiverAlert(
              title: obj['title'] as String? ?? '',
              body: obj['body'] as String? ?? '',
            );
        }
      }
    } catch (_) {
      // Realtime is best-effort; FCM handles push when SSE unavailable.
    }
  }

  void disconnect() => _token?.cancel();
}

final realtimeServiceProvider = Provider<RealtimeService>(
  (ref) => RealtimeService(ref.watch(apiClientProvider)),
);

final realtimeEventsProvider =
    StreamProvider.family<RealtimeEvent, String>((ref, profileId) {
  final service = ref.watch(realtimeServiceProvider);
  ref.onDispose(service.disconnect);
  return service.connect(profileId);
});
