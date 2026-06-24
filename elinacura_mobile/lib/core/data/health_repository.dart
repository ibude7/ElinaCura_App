import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import '../../shared/utils/health_overview_builder.dart';
import '../api/api_client.dart';
import '../auth/auth_providers.dart';

/// Data access for health profiles and caregiver dashboards. Screens and
/// providers depend on this intent-level API rather than the raw transport,
/// which keeps endpoint shapes and parsing in one place.
class HealthRepository {
  HealthRepository(this._api);

  final ApiClient _api;

  Future<List<HealthProfile>> getProfiles() async {
    final raw = await _api.get<dynamic>('/profiles');
    return normalizeProfiles(raw);
  }

  Future<CaregiverDashboardData> getCaregiverDashboard(String profileId) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/caregiver-dashboard/$profileId',
    );
    return CaregiverDashboardData.fromJson(data);
  }
}

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepository(ref.watch(apiClientProvider)),
);
