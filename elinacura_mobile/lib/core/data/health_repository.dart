import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import '../../shared/utils/health_overview_builder.dart';
import '../api/api_client.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import '../domain/api_result.dart';
import '../network/offline_queue.dart';
import 'local_profile_store.dart';

/// Data access for health profiles, vitals sync, and caregiver dashboards.
class HealthRepository {
  HealthRepository(this._api, this._queue);

  final ApiClient _api;
  final OfflineQueueNotifier _queue;

  Future<List<HealthProfile>> getProfiles() async {
    try {
      final raw = await _api.get<dynamic>('/profiles');
      final remote = normalizeProfiles(raw);
      if (remote.isNotEmpty) {
        await LocalProfileStore.saveAll(remote);
        return remote;
      }
    } catch (_) {
      // Fall through to local cache.
    }
    return LocalProfileStore.readAll();
  }

  Future<ApiResult<HealthProfile>> createProfile({
    required String name,
    String? primaryGoal,
    String? bloodType,
    List<String> conditions = const [],
    List<String> medications = const [],
    List<String> allergies = const [],
    EmergencyContact? emergencyContact,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      if (primaryGoal != null && primaryGoal.trim().isNotEmpty)
        'primary_goal': primaryGoal.trim(),
      if (bloodType != null && bloodType.trim().isNotEmpty)
        'blood_type': bloodType.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'conditions': conditions,
      'medications': medications,
      'allergies': allergies,
      if (emergencyContact != null && emergencyContact.name.trim().isNotEmpty)
        'emergency_contacts': [emergencyContact.toJson()],
    };

    try {
      final data = await _api.post<Map<String, dynamic>>('/profiles', data: body);
      final profile = HealthProfile.fromJson(data);
      await LocalProfileStore.upsert(profile);
      return ApiSuccess(profile);
    } catch (e) {
      final local = HealthProfile(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}',
        name: name.trim(),
        email: email,
        primaryGoal: primaryGoal?.trim(),
        bloodType: bloodType?.trim(),
        conditions: conditions,
        medications: medications,
        allergies: allergies,
        emergencyContacts:
            emergencyContact != null && emergencyContact.name.trim().isNotEmpty
                ? [emergencyContact]
                : const [],
      );
      await LocalProfileStore.upsert(local);
      await _queue.enqueue(
        method: 'POST',
        path: '/profiles',
        body: body,
      );
      return ApiSuccess(local);
    }
  }

  Future<CaregiverDashboardData> getCaregiverDashboard(String profileId) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/caregiver-dashboard/$profileId',
    );
    return CaregiverDashboardData.fromJson(data);
  }

  /// Push a vital reading to the backend; queues offline when the call fails.
  Future<ApiResult<void>> syncVitalObservation(
    String profileId,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/health-observations/$profileId',
        data: payload,
      );
      return const ApiSuccess(null);
    } catch (e) {
      await _queue.enqueue(
        method: 'POST',
        path: '/health-observations/$profileId',
        body: payload,
      );
      return ApiFailure(formatApiError(e), e);
    }
  }
}

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepository(
    ref.watch(apiClientProvider),
    ref.read(offlineQueueProvider.notifier),
  ),
);
