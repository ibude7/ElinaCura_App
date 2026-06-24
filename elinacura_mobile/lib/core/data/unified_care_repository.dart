import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../domain/api_result.dart';
import 'care_repository.dart';
import 'engagement_repository.dart';

/// Unified inbox — Firestore human threads + REST AI/safety/digest (Rec #28).
class UnifiedCareRepository {
  UnifiedCareRepository(this._engagement, this._firestore);

  final EngagementRepository _engagement;
  final FirebaseFirestore _firestore;

  Stream<List<CareInboxItem>> watchHumanThreads(String profileId) {
    return _firestore
        .collection('messages')
        .where('profile_id', isEqualTo: profileId)
        .orderBy('updated_at', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            return CareInboxItem(
              id: doc.id,
              kind: CareInboxKind.message,
              title: d['title'] as String? ?? 'Message',
              subtitle: d['preview'] as String? ?? '',
              timestamp: (d['updated_at'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              route: '/messages',
              unread: d['unread'] as bool? ?? false,
            );
          }).toList(),
        );
  }

  Future<ApiResult<List<CareInboxItem>>> loadAiAndSystem(String profileId) async {
    try {
      final items = <CareInboxItem>[];

      final history =
          await _engagement.getChatHistoryResult(profileId);
      if (history.isSuccess && (history.valueOrNull?.isNotEmpty ?? false)) {
        final last = history.valueOrNull!.last;
        items.add(
          CareInboxItem(
            id: 'ai-${last.id}',
            kind: CareInboxKind.ai,
            title: 'Care AI',
            subtitle: last.content.length > 80
                ? '${last.content.substring(0, 80)}…'
                : last.content,
            timestamp: DateTime.now(),
            route: '/chat',
          ),
        );
      }

      final digest = await _engagement.getCurrentDigestResult(profileId);
      if (digest.isSuccess && digest.valueOrNull != null) {
        final d = digest.valueOrNull!;
        items.add(
          CareInboxItem(
            id: 'digest-${d.id}',
            kind: CareInboxKind.digest,
            title: 'Weekly digest',
            subtitle: d.summary,
            timestamp: DateTime.now(),
            route: '/digest',
          ),
        );
      }

      return ApiSuccess(items);
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }
}

final unifiedCareRepositoryProvider = Provider<UnifiedCareRepository>(
  (ref) => UnifiedCareRepository(
    ref.watch(engagementRepositoryProvider),
    FirebaseFirestore.instance,
  ),
);

final unifiedInboxProvider =
    StreamProvider.family<List<CareInboxItem>, String>((ref, profileId) async* {
  final repo = ref.watch(unifiedCareRepositoryProvider);
  final aiItems = await repo.loadAiAndSystem(profileId);
  final ai = aiItems.valueOrNull ?? [];

  await for (final human in repo.watchHumanThreads(profileId)) {
    final merged = [...human, ...ai];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    yield merged;
  }
});
