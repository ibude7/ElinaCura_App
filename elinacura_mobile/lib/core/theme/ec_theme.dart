import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ec_tokens.dart';

/// ElinaCura theme — Google-Health-inspired health OS.
/// Light: soft blue-white canvas, solid white cards, category semantic colors.
/// Dark: deep navy canvas, frosted glass surfaces.
class EcTheme {
  EcTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: EcTokens.accentBrand,
      onPrimary: EcTokens.onAccentLight,
      secondary: EcTokens.categoryActivity,
      onSecondary: Colors.white,
      tertiary: EcTokens.categorySleep,
      surface: EcTokens.bgVoidLight,
      onSurface: EcTokens.textPrimaryLight,
      surfaceContainerHighest: EcTokens.bgCardLight,
      error: EcTokens.statusCritical,
      onError: Colors.white,
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: EcTokens.accentBrandDark,
      onPrimary: EcTokens.onAccentDark,
      secondary: EcTokens.categoryActivity,
      onSecondary: Colors.white,
      tertiary: EcTokens.categorySleep,
      surface: EcTokens.bgVoid,
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
      displayLarge: TextStyle(
        fontSize: 46, fontWeight: FontWeight.w800,
        letterSpacing: -1.8, color: primary, height: 1.0,
      ),
      displayMedium: TextStyle(
        fontSize: 37, fontWeight: FontWeight.w800,
        letterSpacing: -1.3, color: primary, height: 1.04,
      ),
      displaySmall: TextStyle(
        fontSize: 30, fontWeight: FontWeight.w800,
        letterSpacing: -1.0, color: primary, height: 1.08,
      ),
      headlineLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w800,
        letterSpacing: -1.0, color: primary, height: 1.10,
      ),
      headlineMedium: TextStyle(
        fontSize: 22, fontWeight: FontWeight.w800,
        letterSpacing: -0.7, color: primary, height: 1.16,
      ),
      headlineSmall: TextStyle(
        fontSize: 19, fontWeight: FontWeight.w700,
        letterSpacing: -0.4, color: primary, height: 1.20,
      ),
      titleLarge: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w700,
        letterSpacing: -0.3, color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600,
        letterSpacing: -0.2, color: primary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400, color: primary, height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.5, fontWeight: FontWeight.w400, color: primary, height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 13.5, fontWeight: FontWeight.w600,
        letterSpacing: -0.1, color: primary,
      ),
    ).apply(fontFamily: EcTokens.fontFamily);
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final accent = isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand;
    final onAccent = isDark ? EcTokens.onAccentDark : EcTokens.onAccentLight;
    final muted = isDark ? EcTokens.textMutedDark : EcTokens.textMutedLight;
    final primaryText = isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight;

    return ThemeData(
      useMaterial3: true,
      fontFamily: EcTokens.fontFamily,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: Colors.transparent,
      splashColor: accent.withValues(alpha: 0.08),
      highlightColor: accent.withValues(alpha: 0.04),
      textTheme: _textTheme(brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: EcTokens.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: primaryText,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: isDark ? 0.14 : 0.10),
        elevation: 0,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? accent : muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: EcTokens.fontFamily,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.1,
            color: selected ? accent : muted,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          minimumSize: const Size(88, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: EcTokens.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontFamily: EcTokens.fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryText,
          minimumSize: const Size(88, 54),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.08),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          borderSide: BorderSide(
            color: accent.withValues(alpha: 0.7),
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        labelStyle: TextStyle(
          fontFamily: EcTokens.fontFamily,
          color: isDark ? EcTokens.textSecondaryDark : EcTokens.textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(fontFamily: EcTokens.fontFamily, color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xF016181B) : const Color(0xF0FFFFFF),
        contentTextStyle: TextStyle(
          fontFamily: EcTokens.fontFamily,
          color: primaryText,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return isDark ? EcTokens.textMutedDark : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.40);
          }
          return isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.12);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: accent.withValues(alpha: 0.18),
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: accent.withValues(alpha: 0.16),
        circularTrackColor: accent.withValues(alpha: 0.16),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.05),
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: primaryText),
    );
  }
}

// ─────────────────────────────────────────────── EcColors extension ──

class EcColors extends ThemeExtension<EcColors> {
  const EcColors({
    required this.textSecondary,
    required this.textMuted,
    required this.textCritical,
    required this.bgCard,
    required this.bgRecessed,
    required this.accentBrand,
    required this.accentMint,
    required this.accentSky,
    required this.accentCoral,
    required this.accentPlum,
    required this.accentMintFill,
    required this.accentMintText,
    required this.accentBlushFill,
    required this.accentBlushText,
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
  final Color accentMint;
  final Color accentSky;
  final Color accentCoral;
  final Color accentPlum;
  final Color accentMintFill;
  final Color accentMintText;
  final Color accentBlushFill;
  final Color accentBlushText;
  final Color accentAmberFill;
  final Color accentAmberText;
  final Color accentSkyFill;

  static EcColors of(BuildContext context) =>
      Theme.of(context).extension<EcColors>()!;

  static const EcColors light = EcColors(
    textSecondary: EcTokens.textSecondaryLight,
    textMuted: EcTokens.textMutedLight,
    textCritical: EcTokens.textCriticalLight,
    bgCard: EcTokens.bgCardLight,
    bgRecessed: EcTokens.bgRecessedLight,
    accentBrand: EcTokens.accentBrand,
    accentMint: EcTokens.categoryNutrition,
    accentSky: EcTokens.categoryActivity,
    accentCoral: EcTokens.accentCoral,
    accentPlum: EcTokens.categorySleep,
    accentMintFill: EcTokens.categoryNutritionLight,
    accentMintText: Color(0xFF166534),
    accentBlushFill: EcTokens.statusCriticalLight,
    accentBlushText: Color(0xFFA33A3A),
    accentAmberFill: EcTokens.accentAmberFill,
    accentAmberText: EcTokens.accentAmberText,
    accentSkyFill: EcTokens.categoryActivityLight,
  );

  static const EcColors dark = EcColors(
    textSecondary: EcTokens.textSecondaryDark,
    textMuted: EcTokens.textMutedDark,
    textCritical: EcTokens.textCriticalDark,
    bgCard: EcTokens.bgCardDark,
    bgRecessed: EcTokens.bgRecessedDark,
    accentBrand: EcTokens.accentBrandDark,
    accentMint: EcTokens.accentMintDark,
    accentSky: Color(0xFF8AA6C8),
    accentCoral: EcTokens.accentCoral,
    accentPlum: EcTokens.accentPlum,
    accentMintFill: Color(0x223F9E7C),
    accentMintText: Color(0xFF7FD0B0),
    accentBlushFill: Color(0x22C56B6B),
    accentBlushText: Color(0xFFE2A1A1),
    accentAmberFill: Color(0x22C79A3E),
    accentAmberText: Color(0xFFE0C07A),
    accentSkyFill: Color(0x225A7DA8),
  );

  @override
  EcColors copyWith({
    Color? textSecondary, Color? textMuted, Color? textCritical,
    Color? bgCard, Color? bgRecessed, Color? accentBrand,
    Color? accentMint, Color? accentSky, Color? accentCoral, Color? accentPlum,
    Color? accentMintFill, Color? accentMintText, Color? accentBlushFill,
    Color? accentBlushText, Color? accentAmberFill, Color? accentAmberText,
    Color? accentSkyFill,
  }) {
    return EcColors(
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textCritical: textCritical ?? this.textCritical,
      bgCard: bgCard ?? this.bgCard,
      bgRecessed: bgRecessed ?? this.bgRecessed,
      accentBrand: accentBrand ?? this.accentBrand,
      accentMint: accentMint ?? this.accentMint,
      accentSky: accentSky ?? this.accentSky,
      accentCoral: accentCoral ?? this.accentCoral,
      accentPlum: accentPlum ?? this.accentPlum,
      accentMintFill: accentMintFill ?? this.accentMintFill,
      accentMintText: accentMintText ?? this.accentMintText,
      accentBlushFill: accentBlushFill ?? this.accentBlushFill,
      accentBlushText: accentBlushText ?? this.accentBlushText,
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
      accentMint: Color.lerp(accentMint, other.accentMint, t)!,
      accentSky: Color.lerp(accentSky, other.accentSky, t)!,
      accentCoral: Color.lerp(accentCoral, other.accentCoral, t)!,
      accentPlum: Color.lerp(accentPlum, other.accentPlum, t)!,
      accentMintFill: Color.lerp(accentMintFill, other.accentMintFill, t)!,
      accentMintText: Color.lerp(accentMintText, other.accentMintText, t)!,
      accentBlushFill: Color.lerp(accentBlushFill, other.accentBlushFill, t)!,
      accentBlushText: Color.lerp(accentBlushText, other.accentBlushText, t)!,
      accentAmberFill: Color.lerp(accentAmberFill, other.accentAmberFill, t)!,
      accentAmberText: Color.lerp(accentAmberText, other.accentAmberText, t)!,
      accentSkyFill: Color.lerp(accentSkyFill, other.accentSkyFill, t)!,
    );
  }
}

// ─────────────────────────────────────── EcGlass surface tokens ──

class EcGlass extends ThemeExtension<EcGlass> {
  const EcGlass({
    required this.fill, required this.fillElevated, required this.fillSubtle,
    required this.fillFloat, required this.border, required this.borderStrong,
    required this.specularTop, required this.specularSide, required this.navFill,
    required this.tintBrand, required this.shadowColor,
  });

  final Color fill;
  final Color fillElevated;
  final Color fillSubtle;
  final Color fillFloat;
  final Color border;
  final Color borderStrong;
  final Color specularTop;
  final Color specularSide;
  final Color navFill;
  final Color tintBrand;
  final Color shadowColor;

  static EcGlass of(BuildContext context) =>
      Theme.of(context).extension<EcGlass>()!;

  /// Light mode: solid white cards with very subtle border — matches GH.
  static final EcGlass light = EcGlass(
    fill: const Color(0xFFFFFFFF),
    fillElevated: const Color(0xFFFFFFFF),
    fillSubtle: const Color(0xFFF8FAFF),
    fillFloat: const Color(0xFFFFFFFF),
    border: Colors.black.withValues(alpha: 0.06),
    borderStrong: Colors.black.withValues(alpha: 0.10),
    specularTop: Colors.white,
    specularSide: Colors.white.withValues(alpha: 0.60),
    navFill: Colors.white.withValues(alpha: 0.95),
    tintBrand: EcTokens.accentBrand,
    shadowColor: const Color(0xFF1A1C2E),
  );

  /// Dark mode: frosted glass on deep navy.
  static final EcGlass dark = EcGlass(
    fill: Colors.white.withValues(alpha: EcTokens.glassZ2Opacity),
    fillElevated: Colors.white.withValues(alpha: EcTokens.glassZ3Opacity),
    fillSubtle: Colors.white.withValues(alpha: 0.04),
    fillFloat: Colors.white.withValues(alpha: EcTokens.glassZ4Opacity),
    border: Colors.white.withValues(alpha: EcTokens.glassBorderOpacity),
    borderStrong: Colors.white.withValues(alpha: 0.20),
    specularTop: Colors.white.withValues(alpha: EcTokens.glassSpecularTopOpacity),
    specularSide: Colors.white.withValues(alpha: EcTokens.glassSpecularSideOpacity),
    navFill: Colors.white.withValues(alpha: EcTokens.glassZ4Opacity),
    tintBrand: EcTokens.accentBrandDark,
    shadowColor: Colors.black,
  );

  @override
  EcGlass copyWith({
    Color? fill, Color? fillElevated, Color? fillSubtle, Color? fillFloat,
    Color? border, Color? borderStrong, Color? specularTop, Color? specularSide,
    Color? navFill, Color? tintBrand, Color? shadowColor,
  }) {
    return EcGlass(
      fill: fill ?? this.fill,
      fillElevated: fillElevated ?? this.fillElevated,
      fillSubtle: fillSubtle ?? this.fillSubtle,
      fillFloat: fillFloat ?? this.fillFloat,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      specularTop: specularTop ?? this.specularTop,
      specularSide: specularSide ?? this.specularSide,
      navFill: navFill ?? this.navFill,
      tintBrand: tintBrand ?? this.tintBrand,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  EcGlass lerp(ThemeExtension<EcGlass>? other, double t) {
    if (other is! EcGlass) return this;
    return EcGlass(
      fill: Color.lerp(fill, other.fill, t)!,
      fillElevated: Color.lerp(fillElevated, other.fillElevated, t)!,
      fillSubtle: Color.lerp(fillSubtle, other.fillSubtle, t)!,
      fillFloat: Color.lerp(fillFloat, other.fillFloat, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      specularTop: Color.lerp(specularTop, other.specularTop, t)!,
      specularSide: Color.lerp(specularSide, other.specularSide, t)!,
      navFill: Color.lerp(navFill, other.navFill, t)!,
      tintBrand: Color.lerp(tintBrand, other.tintBrand, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
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
