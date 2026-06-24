import 'package:flutter/services.dart';

/// Premium haptic feedback patterns (Rec #23).
class EcHaptics {
  EcHaptics._();

  static Future<void> doseConfirmed() => HapticFeedback.mediumImpact();

  static Future<void> navSelected() => HapticFeedback.selectionClick();

  static Future<void> safetyFlag() => HapticFeedback.heavyImpact();

  static Future<void> lightTap() => HapticFeedback.lightImpact();

  /// Escalating SOS long-press pattern.
  static Future<void> sosEscalation() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  static Future<void> error() => HapticFeedback.heavyImpact();
}
