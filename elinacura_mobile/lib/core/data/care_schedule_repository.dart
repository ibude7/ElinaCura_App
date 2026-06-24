import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import '../api/api_client.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import '../domain/api_result.dart';
import '../health/care_rhythm.dart';
import '../health/dose_log.dart';

/// GET /api/care-rhythm/{profileId} — live 24h schedule (Rec #32).
class CareScheduleItem {
  const CareScheduleItem({
    required this.time,
    required this.label,
    required this.kind,
    this.done = false,
    this.slotKey,
  });

  factory CareScheduleItem.fromJson(Map<String, dynamic> json) {
    return CareScheduleItem(
      time: json['time'] as String? ?? '',
      label: json['label'] as String? ?? '',
      kind: json['kind'] as String? ?? 'medication',
      done: json['done'] as bool? ?? false,
      slotKey: json['slot_key'] as String?,
    );
  }

  final String time;
  final String label;
  final String kind;
  final bool done;
  final String? slotKey;
}

class CareScheduleRepository {
  CareScheduleRepository(this._api);

  final ApiClient _api;

  Future<ApiResult<List<CareScheduleItem>>> fetch(String profileId) async {
    try {
      final data = await _api.get<Map<String, dynamic>>(
        '/care-rhythm/$profileId',
      );
      final rows = data['items'] as List? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map(CareScheduleItem.fromJson)
          .toList();
      return ApiSuccess(items);
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  List<CareScheduleItem> fromLocal({
    required List<MedicationItem> meds,
    required Map<String, Set<String>> doseLog,
  }) {
    return buildCareRhythm(medications: meds, doseLog: doseLog)
        .map(
          (r) => CareScheduleItem(
            time: r.time,
            label: r.label,
            kind: r.icon,
            done: r.done,
            slotKey: r.slotKey,
          ),
        )
        .toList();
  }
}

final careScheduleRepositoryProvider = Provider<CareScheduleRepository>(
  (ref) => CareScheduleRepository(ref.watch(apiClientProvider)),
);

final careScheduleProvider =
    FutureProvider.family<List<CareScheduleItem>, String>((ref, profileId) async {
  final repo = ref.watch(careScheduleRepositoryProvider);
  final result = await repo.fetch(profileId);
  if (result.isSuccess) return result.valueOrNull ?? [];
  final overview = ref.watch(healthOverviewProvider).valueOrNull;
  final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
  return repo.fromLocal(meds: overview?.medications ?? const [], doseLog: log);
});
