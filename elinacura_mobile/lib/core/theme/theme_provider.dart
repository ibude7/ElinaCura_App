import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EcThemePreference { system, light, dark }

extension EcThemePreferenceX on EcThemePreference {
  ThemeMode get themeMode => switch (this) {
        EcThemePreference.system => ThemeMode.system,
        EcThemePreference.light => ThemeMode.light,
        EcThemePreference.dark => ThemeMode.dark,
      };

  String get label => switch (this) {
        EcThemePreference.system => 'System',
        EcThemePreference.light => 'Light',
        EcThemePreference.dark => 'Dark',
      };

  IconData get icon => switch (this) {
        EcThemePreference.system => Icons.brightness_auto_rounded,
        EcThemePreference.light => Icons.light_mode_rounded,
        EcThemePreference.dark => Icons.dark_mode_rounded,
      };
}

class ThemePreferenceNotifier extends StateNotifier<EcThemePreference> {
  ThemePreferenceNotifier() : super(EcThemePreference.system) {
    _load();
  }

  static const _key = 'ec.theme_preference';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    for (final option in EcThemePreference.values) {
      if (option.name == raw) {
        state = option;
        return;
      }
    }
  }

  Future<void> set(EcThemePreference preference) async {
    state = preference;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, preference.name);
  }
}

final themePreferenceProvider =
    StateNotifierProvider<ThemePreferenceNotifier, EcThemePreference>(
  (ref) => ThemePreferenceNotifier(),
);

/// Resolved brightness for widgets that need explicit light/dark styling.
final resolvedBrightnessProvider = Provider<Brightness>((ref) {
  final preference = ref.watch(themePreferenceProvider);
  return switch (preference) {
    EcThemePreference.light => Brightness.light,
    EcThemePreference.dark => Brightness.dark,
    EcThemePreference.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
  };
});

final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(resolvedBrightnessProvider) == Brightness.dark;
});
