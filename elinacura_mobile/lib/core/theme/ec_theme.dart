import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ec_tokens.dart';

class EcTheme {
  EcTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: EcTokens.accentBrand,
      onPrimary: Colors.white,
      surface: EcTokens.bgAppLight,
      onSurface: EcTokens.textPrimaryLight,
      error: EcTokens.statusCritical,
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.dark(
      primary: EcTokens.accentBrandDark,
      onPrimary: Colors.white,
      secondary: EcTokens.accentBrandDark,
      surface: EcTokens.bgAppDark,
      onSurface: EcTokens.textPrimaryDark,
      surfaceContainerHighest: EcTokens.bgCardDark,
      error: EcTokens.statusCritical,
      onError: Colors.white,
    );
    return _base(scheme, Brightness.dark);
  }

  static TextTheme _textTheme(Brightness brightness) {
    final primary = brightness == Brightness.dark
        ? EcTokens.textPrimaryDark
        : EcTokens.textPrimaryLight;
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: primary,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primary,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: primary, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: primary, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: primary),
    );
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: Colors.transparent,
      textTheme: _textTheme(brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: (isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand)
            .withValues(alpha: isDark ? 0.22 : 0.14),
        elevation: 0,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand)
                : (isDark ? EcTokens.textMutedDark : EcTokens.textMutedLight),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.1,
            color: selected
                ? (isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand)
                : (isDark ? EcTokens.textMutedDark : EcTokens.textMutedLight),
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 52),
          side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.08)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.65),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          borderSide: BorderSide(
            color: (isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand).withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: TextStyle(
          color: isDark ? EcTokens.textSecondaryDark : EcTokens.textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xE6161D2A) : const Color(0xE6FDFBF7),
        contentTextStyle: TextStyle(
          color: isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand;
          }
          return isDark ? EcTokens.textMutedDark : EcTokens.textMutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return (isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand).withValues(alpha: 0.35);
          }
          return isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.12);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        thickness: 1,
      ),
    );
  }
}

/// Theme extension for EC semantic colors.
class EcColors extends ThemeExtension<EcColors> {
  const EcColors({
    required this.textSecondary,
    required this.textMuted,
    required this.textCritical,
    required this.bgCard,
    required this.bgRecessed,
    required this.accentBrand,
    required this.accentMintFill,
    required this.accentMintText,
    required this.accentBlushFill,
    required this.accentAmberFill,
    required this.accentAmberText,
    required this.accentSkyFill,
  });

  final Color textSecondary;
  final Color textMuted;
  final Color textCritical;
  final Color bgCard;
  final Color bgRecessed;
  final Color accentBrand;
  final Color accentMintFill;
  final Color accentMintText;
  final Color accentBlushFill;
  final Color accentAmberFill;
  final Color accentAmberText;
  final Color accentSkyFill;

  static EcColors of(BuildContext context) =>
      Theme.of(context).extension<EcColors>()!;

  static EcColors light = const EcColors(
    textSecondary: EcTokens.textSecondaryLight,
    textMuted: EcTokens.textMutedLight,
    textCritical: EcTokens.textCriticalLight,
    bgCard: EcTokens.bgCardLight,
    bgRecessed: EcTokens.bgRecessedLight,
    accentBrand: EcTokens.accentBrand,
    accentMintFill: EcTokens.accentMintFill,
    accentMintText: EcTokens.accentMintText,
    accentBlushFill: EcTokens.accentBlushFill,
    accentAmberFill: EcTokens.accentAmberFill,
    accentAmberText: EcTokens.accentAmberText,
    accentSkyFill: EcTokens.accentSkyFill,
  );

  static EcColors dark = const EcColors(
    textSecondary: EcTokens.textSecondaryDark,
    textMuted: EcTokens.textMutedDark,
    textCritical: EcTokens.textCriticalDark,
    bgCard: EcTokens.bgCardDark,
    bgRecessed: EcTokens.bgRecessedDark,
    accentBrand: EcTokens.accentBrandDark,
    accentMintFill: Color(0x2934D399),
    accentMintText: Color(0xFF6EE7B7),
    accentBlushFill: Color(0x29F472B6),
    accentAmberFill: Color(0x29F59E0B),
    accentAmberText: Color(0xFFFCD34D),
    accentSkyFill: Color(0x2960A5FA),
  );

  @override
  EcColors copyWith({
    Color? textSecondary,
    Color? textMuted,
    Color? textCritical,
    Color? bgCard,
    Color? bgRecessed,
    Color? accentBrand,
    Color? accentMintFill,
    Color? accentMintText,
    Color? accentBlushFill,
    Color? accentAmberFill,
    Color? accentAmberText,
    Color? accentSkyFill,
  }) {
    return EcColors(
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textCritical: textCritical ?? this.textCritical,
      bgCard: bgCard ?? this.bgCard,
      bgRecessed: bgRecessed ?? this.bgRecessed,
      accentBrand: accentBrand ?? this.accentBrand,
      accentMintFill: accentMintFill ?? this.accentMintFill,
      accentMintText: accentMintText ?? this.accentMintText,
      accentBlushFill: accentBlushFill ?? this.accentBlushFill,
      accentAmberFill: accentAmberFill ?? this.accentAmberFill,
      accentAmberText: accentAmberText ?? this.accentAmberText,
      accentSkyFill: accentSkyFill ?? this.accentSkyFill,
    );
  }

  @override
  EcColors lerp(ThemeExtension<EcColors>? other, double t) {
    if (other is! EcColors) return this;
    return EcColors(
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textCritical: Color.lerp(textCritical, other.textCritical, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgRecessed: Color.lerp(bgRecessed, other.bgRecessed, t)!,
      accentBrand: Color.lerp(accentBrand, other.accentBrand, t)!,
      accentMintFill: Color.lerp(accentMintFill, other.accentMintFill, t)!,
      accentMintText: Color.lerp(accentMintText, other.accentMintText, t)!,
      accentBlushFill: Color.lerp(accentBlushFill, other.accentBlushFill, t)!,
      accentAmberFill: Color.lerp(accentAmberFill, other.accentAmberFill, t)!,
      accentAmberText: Color.lerp(accentAmberText, other.accentAmberText, t)!,
      accentSkyFill: Color.lerp(accentSkyFill, other.accentSkyFill, t)!,
    );
  }
}

/// Glass surface tokens for liquid glass UI.
class EcGlass extends ThemeExtension<EcGlass> {
  const EcGlass({
    required this.fill,
    required this.fillElevated,
    required this.fillSubtle,
    required this.border,
    required this.highlight,
    required this.navFill,
    required this.tintBrand,
  });

  final Color fill;
  final Color fillElevated;
  final Color fillSubtle;
  final Color border;
  final Color highlight;
  final Color navFill;
  final Color tintBrand;

  static EcGlass of(BuildContext context) => Theme.of(context).extension<EcGlass>()!;

  static EcGlass light = EcGlass(
    fill: Colors.white.withValues(alpha: 0.58),
    fillElevated: Colors.white.withValues(alpha: 0.74),
    fillSubtle: Colors.white.withValues(alpha: 0.38),
    border: Colors.white.withValues(alpha: 0.82),
    highlight: Colors.white.withValues(alpha: 0.95),
    navFill: Colors.white.withValues(alpha: 0.62),
    tintBrand: EcTokens.accentBrand,
  );

  static EcGlass dark = EcGlass(
    fill: Colors.white.withValues(alpha: 0.10),
    fillElevated: Colors.white.withValues(alpha: 0.16),
    fillSubtle: Colors.white.withValues(alpha: 0.06),
    border: Colors.white.withValues(alpha: 0.20),
    highlight: Colors.white.withValues(alpha: 0.28),
    navFill: const Color(0xD90C1219),
    tintBrand: EcTokens.accentBrandDark,
  );

  @override
  EcGlass copyWith({
    Color? fill,
    Color? fillElevated,
    Color? fillSubtle,
    Color? border,
    Color? highlight,
    Color? navFill,
    Color? tintBrand,
  }) {
    return EcGlass(
      fill: fill ?? this.fill,
      fillElevated: fillElevated ?? this.fillElevated,
      fillSubtle: fillSubtle ?? this.fillSubtle,
      border: border ?? this.border,
      highlight: highlight ?? this.highlight,
      navFill: navFill ?? this.navFill,
      tintBrand: tintBrand ?? this.tintBrand,
    );
  }

  @override
  EcGlass lerp(ThemeExtension<EcGlass>? other, double t) {
    if (other is! EcGlass) return this;
    return EcGlass(
      fill: Color.lerp(fill, other.fill, t)!,
      fillElevated: Color.lerp(fillElevated, other.fillElevated, t)!,
      fillSubtle: Color.lerp(fillSubtle, other.fillSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      navFill: Color.lerp(navFill, other.navFill, t)!,
      tintBrand: Color.lerp(tintBrand, other.tintBrand, t)!,
    );
  }
}

ThemeData withEcExtensions(ThemeData theme, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return theme.copyWith(
    extensions: [
      isDark ? EcColors.dark : EcColors.light,
      isDark ? EcGlass.dark : EcGlass.light,
    ],
  );
}
