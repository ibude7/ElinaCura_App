import 'package:flutter/material.dart';

import '../theme/ec_tokens.dart';

/// Glass accessibility rules (Rec #47).
class EcA11y {
  EcA11y._();

  /// Minimum text contrast on glass — add tint when needed.
  static Color glassTextBackdrop({
    required BuildContext context,
    double opacity = 0.18,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? Colors.black : Colors.white).withValues(alpha: opacity);
  }

  /// Whether user prefers reduced transparency (solid fallback).
  static bool prefersReducedTransparency(BuildContext context) {
    return MediaQuery.of(context).highContrast ||
        MediaQuery.disableAnimationsOf(context);
  }

  /// Hairline border required on all glass surfaces for separation.
  static Border glassHairline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Border.all(
      color: (isDark ? Colors.white : Colors.black).withValues(
        alpha: isDark ? 0.12 : 0.08,
      ),
      width: 1,
    );
  }

  /// Specular top edge highlight for liquid glass.
  static BoxDecoration liquidGlassRim(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      border: Border(
        top: BorderSide(
          color: (isDark ? Colors.white : EcTokens.textPrimaryLight)
              .withValues(alpha: isDark ? 0.14 : 0.06),
        ),
      ),
    );
  }
}
