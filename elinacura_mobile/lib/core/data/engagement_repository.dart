import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import '../api/api_client.dart';
import '../auth/auth_providers.dart';

/// API access for engagement features migrated from the PWA.
class EngagementRepository {
  EngagementRepository(this._api);

  final ApiClient _api;

  Future<List<ChatHistoryMessage>> getChatHistory(String profileId) async {
    final rows = await _api.get<List<dynamic>>('/chat/history/$profileId');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ChatHistoryMessage.fromJson)
        .toList();
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

  Future<void> clearChatHistory(String profileId) async {
    await _api.delete<Map<String, dynamic>>('/chat/history/$profileId');
  }

  Future<WeeklyDigest?> getCurrentDigest(String profileId) async {
    try {
      final data = await _api.get<Map<String, dynamic>>(
        '/digest/$profileId/current',
      );
      return WeeklyDigest.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<ShoppingListItem>> getShoppingList(String profileId) async {
    try {
      final data = await _api.get<Map<String, dynamic>>(
        '/shopping-list/$profileId',
      );
      final rows = data['items'] as List? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(ShoppingListItem.fromJson)
          .toList();
    } catch (_) {
      return [];
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

  Future<List<MomentFeedItem>> getMomentsFeed({String? cursor}) async {
    try {
      final data = await _api.get<Map<String, dynamic>>(
        '/moments/feed',
        queryParameters: cursor == null ? null : {'cursor': cursor},
      );
      final rows = data['moments'] as List? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(MomentFeedItem.fromJson)
          .toList();
    } catch (_) {
      return [];
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

  Future<FamilyCirclesData> listCircles() async {
    try {
      final data = await _api.get<Map<String, dynamic>>('/circles');
      return FamilyCirclesData.fromJson(data);
    } catch (_) {
      return const FamilyCirclesData();
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

  Future<List<TelehealthPartner>> getTelehealthPartners() async {
    try {
      final data = await _api.get<Map<String, dynamic>>('/telehealth/partners');
      final rows = data['partners'] as List? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(TelehealthPartner.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final engagementRepositoryProvider = Provider<EngagementRepository>(
  (ref) => EngagementRepository(ref.watch(apiClientProvider)),
);

String? activeProfileId(WidgetRef ref) =>
    ref.watch(healthOverviewProvider).valueOrNull?.profile?.id;
