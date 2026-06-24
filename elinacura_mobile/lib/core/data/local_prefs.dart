import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight local persistence mirroring the PWA `ec.pref.*` keys.
class LocalPrefs {
  LocalPrefs._();

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<T?> readJson<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final raw = (await _prefs).getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return fromJson(decoded);
    } catch (_) {}
    return null;
  }

  static Future<Map<String, bool>> readBoolMap(String key) async {
    final raw = (await _prefs).getString(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map(
          (k, v) => MapEntry(k.toString(), v == true),
        );
      }
    } catch (_) {}
    return {};
  }

  static Future<void> writeBoolMap(String key, Map<String, bool> value) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<List<Map<String, dynamic>>> readList(String key) async {
    final raw = (await _prefs).getString(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> writeList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<String?> readString(String key) async =>
      (await _prefs).getString(key);

  static Future<void> writeString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }
}
