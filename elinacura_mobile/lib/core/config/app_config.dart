import 'package:flutter/foundation.dart';

/// Runtime configuration for API and feature flags.
class AppConfig {
  AppConfig._();

  /// Set at build time via `--dart-define=BACKEND_URL=...`.
  /// When empty in debug builds, defaults to the local FastAPI dev server.
  static const String _backendUrlFromEnv = String.fromEnvironment('BACKEND_URL');

  static String get backendUrl {
    if (_backendUrlFromEnv.isNotEmpty) return _backendUrlFromEnv;
    if (kDebugMode) return 'http://127.0.0.1:8000';
    return 'https://app.elinacura.com';
  }

  static String get apiBase => '${backendUrl.replaceAll(RegExp(r'/$'), '')}/api';

  static const String appName = 'ElinaCura';
  static const String bundleId = 'com.elinacura.app';
}

String formatApiError(Object error) {
  final message = error.toString();
  if (message.contains('SocketException') ||
      message.contains('Failed host lookup') ||
      message.contains('Connection refused') ||
      message.contains('Network is unreachable')) {
    return 'Cannot reach the server at ${AppConfig.backendUrl}. '
        'Start the backend locally or check your connection.';
  }
  if (message.contains('401') || message.contains('unauthorized')) {
    return 'Your session expired. Sign out and sign in again.';
  }
  if (message.contains('403')) {
    return 'Access denied. Verify your email or account permissions.';
  }
  if (kDebugMode) return message;
  return 'Something went wrong loading your data. Pull to retry.';
}
