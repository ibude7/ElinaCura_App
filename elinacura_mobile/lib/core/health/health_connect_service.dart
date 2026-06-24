import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Apple Health / Health Connect interoperability (Rec #44).
class HealthConnectService {
  const HealthConnectService();

  static const _channel = MethodChannel('com.elinacura/health_connect');

  Future<bool> get isAvailable async {
    try {
      final ok = await _channel.invokeMethod<bool>('isAvailable');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestAuthorization() async {
    try {
      final ok = await _channel.invokeMethod<bool>('requestAuthorization');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, double>> readLatestVitals() async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'readLatestVitals',
      );
      if (raw == null) return const {};
      return raw.map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<void> syncToElinaCura(String profileId) async {
    try {
      await _channel.invokeMethod<void>('syncToElinaCura', {
        'profile_id': profileId,
      });
    } catch (_) {}
  }
}

final healthConnectServiceProvider = Provider<HealthConnectService>(
  (_) => const HealthConnectService(),
);

final healthConnectAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(healthConnectServiceProvider).isAvailable,
);
