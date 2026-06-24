import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import '../domain/api_result.dart';

/// Remote feature manifest from GET /api/config (Rec #37).
class FeatureFlags {
  const FeatureFlags({
    this.chatEnabled = true,
    this.digestEnabled = true,
    this.momentsEnabled = true,
    this.voiceEnabled = true,
    this.travelEnabled = true,
    this.telehealthEnabled = true,
    this.medicationProofEnabled = true,
    this.healthObservationsEnabled = true,
    this.shoppingEnabled = true,
    this.circlesEnabled = true,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    final flags = json['flags'] as Map<String, dynamic>? ?? json;
    bool on(String key, {bool defaultValue = true}) =>
        flags[key] as bool? ?? defaultValue;
    return FeatureFlags(
      chatEnabled: on('engagement_chat_enabled'),
      digestEnabled: on('engagement_digest_enabled'),
      momentsEnabled: on('engagement_moments_enabled'),
      voiceEnabled: on('engagement_voice_enabled'),
      travelEnabled: on('engagement_travel_enabled'),
      telehealthEnabled: on('engagement_telehealth_enabled'),
      medicationProofEnabled: on('medication_proof_enabled'),
      healthObservationsEnabled: on('health_observations_enabled'),
      shoppingEnabled: on('engagement_shopping_enabled'),
      circlesEnabled: on('connections_enabled'),
    );
  }

  final bool chatEnabled;
  final bool digestEnabled;
  final bool momentsEnabled;
  final bool voiceEnabled;
  final bool travelEnabled;
  final bool telehealthEnabled;
  final bool medicationProofEnabled;
  final bool healthObservationsEnabled;
  final bool shoppingEnabled;
  final bool circlesEnabled;

  bool routeEnabled(String route) {
    if (route.startsWith('/chat')) return chatEnabled;
    if (route.startsWith('/digest')) return digestEnabled;
    if (route.startsWith('/moments')) return momentsEnabled;
    if (route.startsWith('/voice')) return voiceEnabled;
    if (route.startsWith('/travel')) return travelEnabled;
    if (route.startsWith('/telehealth')) return telehealthEnabled;
    if (route.startsWith('/shopping')) return shoppingEnabled;
    if (route.startsWith('/family-circle') || route.startsWith('/connections')) {
      return circlesEnabled;
    }
    return true;
  }
}

class FeatureFlagsRepository {
  FeatureFlagsRepository(this._api);

  final ApiClient _api;

  Future<ApiResult<FeatureFlags>> fetch() async {
    try {
      final data = await _api.get<Map<String, dynamic>>('/config');
      return ApiSuccess(FeatureFlags.fromJson(data));
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }
}

final featureFlagsRepositoryProvider = Provider<FeatureFlagsRepository>(
  (ref) => FeatureFlagsRepository(ref.watch(apiClientProvider)),
);

final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) async {
  final result = await ref.watch(featureFlagsRepositoryProvider).fetch();
  return result.valueOrNull ?? const FeatureFlags();
});
