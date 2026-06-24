import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import '../api/api_client.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import '../domain/api_result.dart';
import '../health/care_rhythm.dart';
import '../health/dose_log.dart';

/// GET /api/care-timeline/{profileId} — unified patient timeline (Rec #31).
class CareTimelineEvent {
  const CareTimelineEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.route,
  });

  factory CareTimelineEvent.fromJson(Map<String, dynamic> json) {
    return CareTimelineEvent(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'event',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      route: json['route'] as String?,
    );
  }

  final String id;
  final String kind;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? route;
}

class CareTimelineRepository {
  CareTimelineRepository(this._api);

  final ApiClient _api;

  Future<ApiResult<List<CareTimelineEvent>>> fetch(
    String profileId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final data = await _api.get<List<dynamic>>(
        '/care-timeline/$profileId',
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      );
      final events = data
          .whereType<Map<String, dynamic>>()
          .map(CareTimelineEvent.fromJson)
          .toList();
      return ApiSuccess(events);
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  /// Local fallback when API unavailable — merges dose log + rhythm.
  List<CareTimelineEvent> buildLocal({
    required List<MedicationItem> meds,
    required Map<String, Set<String>> doseLog,
  }) {
    final rhythm = buildCareRhythm(medications: meds, doseLog: doseLog);
    return rhythm
        .map(
          (r) => CareTimelineEvent(
            id: 'rhythm-${r.time}-${r.label}',
            kind: 'rhythm',
            title: r.label,
            subtitle: r.done ? 'Completed' : 'Scheduled ${r.time}',
            timestamp: DateTime.now(),
            route: '/reminders',
          ),
        )
        .toList();
  }
}

final careTimelineRepositoryProvider = Provider<CareTimelineRepository>(
  (ref) => CareTimelineRepository(ref.watch(apiClientProvider)),
);

final careTimelineProvider =
    FutureProvider.family<ApiResult<List<CareTimelineEvent>>, String>(
  (ref, profileId) async {
    final repo = ref.watch(careTimelineRepositoryProvider);
    final result = await repo.fetch(profileId);
    if (result.isSuccess) return result;
    final overview = ref.watch(healthOverviewProvider).valueOrNull;
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
    return ApiSuccess(
      repo.buildLocal(meds: overview?.medications ?? const [], doseLog: log),
    );
  },
);
