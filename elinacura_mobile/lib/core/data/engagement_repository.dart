import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import '../api/api_client.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import '../domain/api_result.dart';
import 'chat_stream.dart';

/// API access for engagement features migrated from the PWA.
class EngagementRepository {
  EngagementRepository(this._api);

  final ApiClient _api;

  Future<ApiResult<List<ChatHistoryMessage>>> getChatHistoryResult(
    String profileId,
  ) async {
    try {
      final rows = await _api.get<List<dynamic>>('/chat/history/$profileId');
      final messages = rows
          .whereType<Map<String, dynamic>>()
          .map(ChatHistoryMessage.fromJson)
          .toList();
      return ApiSuccess(messages);
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  Future<List<ChatHistoryMessage>> getChatHistory(String profileId) async {
    final result = await getChatHistoryResult(profileId);
    return result.valueOrNull ?? [];
  }

  Future<ChatReply> sendChat({
    required String profileId,
    required String message,
    List<String> acknowledgedWarnings = const [],
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/chat',
      data: {
        'profile_id': profileId,
        'message': message,
        if (acknowledgedWarnings.isNotEmpty)
          'acknowledged_warnings': acknowledgedWarnings,
      },
    );
    return ChatReply.fromJson(data);
  }

  /// Stream a Care AI reply via POST /chat/stream (newline-delimited JSON).
  Stream<ChatStreamEvent> streamChat({
    required String profileId,
    required String message,
    List<String> acknowledgedWarnings = const [],
    CancelToken? cancelToken,
  }) async* {
    try {
      await for (final obj in _api.postNdjsonStream(
        '/chat/stream',
        data: {
          'profile_id': profileId,
          'message': message,
          if (acknowledgedWarnings.isNotEmpty)
            'acknowledged_warnings': acknowledgedWarnings,
        },
        cancelToken: cancelToken,
      )) {
        final type = obj['type'] as String?;
        if (type == 'delta') {
          final text = obj['text'] as String? ?? '';
          if (text.isNotEmpty) yield ChatStreamDelta(text);
        } else if (type == 'done') {
          final risk = obj['risk'] as Map<String, dynamic>?;
          yield ChatStreamDone(
            escalated: obj['escalated'] as bool? ?? false,
            riskLevel: risk?['level'] as String?,
            mode: obj['mode'] as String?,
          );
        }
      }
    } on DioException catch (e) {
      throw Exception(formatApiError(e));
    }
  }

  Future<void> clearChatHistory(String profileId) async {
    await _api.delete<Map<String, dynamic>>('/chat/history/$profileId');
  }

  Future<ApiResult<WeeklyDigest?>> getCurrentDigestResult(String profileId) async {
    try {
      final data = await _api.get<Map<String, dynamic>>(
        '/digest/$profileId/current',
      );
      return ApiSuccess(WeeklyDigest.fromJson(data));
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  Future<WeeklyDigest?> getCurrentDigest(String profileId) async {
    final result = await getCurrentDigestResult(profileId);
    return result.valueOrNull;
  }

  Future<ApiResult<List<ShoppingListItem>>> getShoppingListResult(
    String profileId,
  ) async {
    try {
      final data = await _api.get<Map<String, dynamic>>(
        '/shopping-list/$profileId',
      );
      final rows = data['items'] as List? ?? [];
      return ApiSuccess(
        rows
            .whereType<Map<String, dynamic>>()
            .map(ShoppingListItem.fromJson)
            .toList(),
      );
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  Future<ShoppingListItem?> addShoppingItem(
    String profileId,
    String name,
  ) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/shopping-list/$profileId/items',
      data: {'name': name},
    );
    return ShoppingListItem.fromJson(data);
  }

  Future<void> setShoppingItemPurchased(String itemId, bool purchased) async {
    await _api.patch<Map<String, dynamic>>(
      '/shopping-list/items/$itemId',
      data: {'purchased': purchased},
    );
  }

  Future<void> deleteShoppingItem(String itemId) async {
    await _api.delete<Map<String, dynamic>>('/shopping-list/items/$itemId');
  }

  Future<List<ShoppingListItem>> getShoppingList(String profileId) async {
    final result = await getShoppingListResult(profileId);
    return result.valueOrNull ?? [];
  }

  Future<ApiResult<List<MomentFeedItem>>> getMomentsFeedResult({
    String? cursor,
  }) async {
    try {
      final data = await _api.get<Map<String, dynamic>>(
        '/moments/feed',
        queryParameters: cursor == null ? null : {'cursor': cursor},
      );
      final rows = data['moments'] as List? ?? [];
      return ApiSuccess(
        rows
            .whereType<Map<String, dynamic>>()
            .map(MomentFeedItem.fromJson)
            .toList(),
      );
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  Future<void> setMomentReaction(String momentId, {required bool liked}) async {
    if (liked) {
      await _api.put<Map<String, dynamic>>(
        '/moments/$momentId/reaction',
        data: {'reaction': 'heart'},
      );
    } else {
      await _api.delete<Map<String, dynamic>>('/moments/$momentId/reaction');
    }
  }

  Future<List<MomentFeedItem>> getMomentsFeed({String? cursor}) async {
    final result = await getMomentsFeedResult(cursor: cursor);
    return result.valueOrNull ?? [];
  }

  Future<ApiResult<FamilyCirclesData>> listCirclesResult() async {
    try {
      final data = await _api.get<Map<String, dynamic>>('/circles');
      return ApiSuccess(FamilyCirclesData.fromJson(data));
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  Future<VoiceIntentResult> resolveVoiceIntent({
    required String profileId,
    required String transcript,
    double confidence = 0.92,
    bool persistConsent = false,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/voice/intent',
      data: {
        'profile_id': profileId,
        'transcript': transcript,
        'confidence': confidence,
        'persist_consent': persistConsent,
      },
    );
    return VoiceIntentResult.fromJson(data);
  }

  Future<Map<String, dynamic>> getTravelPlan({
    required String profileId,
    required String originTz,
    required String destinationTz,
    int days = 5,
  }) async {
    return _api.get<Map<String, dynamic>>(
      '/travel-mode/$profileId',
      queryParameters: {
        'origin_tz': originTz,
        'destination_tz': destinationTz,
        'days': days,
      },
    );
  }

  Future<FamilyCirclesData> listCircles() async {
    final result = await listCirclesResult();
    return result.valueOrNull ?? const FamilyCirclesData();
  }

  Future<ApiResult<List<TelehealthPartner>>> getTelehealthPartnersResult() async {
    try {
      final data = await _api.get<Map<String, dynamic>>('/telehealth/partners');
      final rows = data['partners'] as List? ?? [];
      return ApiSuccess(
        rows
            .whereType<Map<String, dynamic>>()
            .map(TelehealthPartner.fromJson)
            .toList(),
      );
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  Future<List<TelehealthPartner>> getTelehealthPartners() async {
    final result = await getTelehealthPartnersResult();
    return result.valueOrNull ?? [];
  }
}

final engagementRepositoryProvider = Provider<EngagementRepository>(
  (ref) => EngagementRepository(ref.watch(apiClientProvider)),
);

String? activeProfileId(WidgetRef ref) =>
    ref.watch(healthOverviewProvider).valueOrNull?.profile?.id;
