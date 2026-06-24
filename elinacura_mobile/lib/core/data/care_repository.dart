import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/domain/api_result.dart';
import '../api/api_client.dart';
import '../auth/auth_providers.dart';
import 'engagement_repository.dart';

/// Unified care data — timeline events, rhythm, inbox items.
class CareRepository {
  CareRepository(this._api, this._engagement);

  final ApiClient _api;
  final EngagementRepository _engagement;

  Future<ApiResult<List<CareTimelineEvent>>> getTimeline(String profileId) async {
    try {
      final data = await _api.get<List<dynamic>>(
        '/health-observations/$profileId',
      );
      final events = data
          .whereType<Map<String, dynamic>>()
          .map(CareTimelineEvent.fromObservation)
          .toList();
      return ApiSuccess(events);
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  Future<ApiResult<List<CareInboxItem>>> loadInbox(String profileId) async {
    try {
      final items = <CareInboxItem>[];

      final digest = await _engagement.getCurrentDigest(profileId);
      if (digest != null) {
        items.add(
          CareInboxItem(
            id: 'digest-${digest.id}',
            kind: CareInboxKind.digest,
            title: 'Weekly digest',
            subtitle: digest.summary.isNotEmpty
                ? digest.summary
                : 'Your rhythm summary is ready',
            timestamp: DateTime.now(),
            route: '/digest',
          ),
        );
      }

      final moments = await _engagement.getMomentsFeed();
      for (final m in moments.take(3)) {
        items.add(
          CareInboxItem(
            id: 'moment-${m.id}',
            kind: CareInboxKind.moment,
            title: m.authorName,
            subtitle: m.caption,
            timestamp: DateTime.tryParse(m.createdAt ?? '') ?? DateTime.now(),
            route: '/moments',
          ),
        );
      }

      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return ApiSuccess(items);
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }
}

class CareTimelineEvent {
  const CareTimelineEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  factory CareTimelineEvent.fromObservation(Map<String, dynamic> json) {
    return CareTimelineEvent(
      id: json['id'] as String? ?? '',
      title: json['type'] as String? ?? 'Observation',
      subtitle: '${json['value'] ?? ''} ${json['unit'] ?? ''}'.trim(),
      timestamp: DateTime.tryParse(json['recorded_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
}

enum CareInboxKind { message, ai, alert, digest, moment, safety }

class CareInboxItem {
  const CareInboxItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.route,
    this.unread = false,
  });

  final String id;
  final CareInboxKind kind;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? route;
  final bool unread;
}

final careRepositoryProvider = Provider<CareRepository>((ref) {
  return CareRepository(
    ref.watch(apiClientProvider),
    ref.watch(engagementRepositoryProvider),
  );
});

final careInboxProvider =
    FutureProvider.family<ApiResult<List<CareInboxItem>>, String>(
  (ref, profileId) async {
    return ref.read(careRepositoryProvider).loadInbox(profileId);
  },
);
