import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ec_tokens.dart';

/// ElinaCura "Aurora" theme — premium liquid-glass health & fitness UI.
class EcTheme {
  EcTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: EcTokens.accentBrand,
      onPrimary: Colors.white,
      secondary: EcTokens.accentMint,
      onSecondary: Colors.white,
      tertiary: EcTokens.accentCoral,
      surface: EcTokens.bgAppLight,
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
      onPrimary: Color(0xFF130B33),
      secondary: EcTokens.accentMintDark,
      onSecondary: Color(0xFF06231B),
      tertiary: EcTokens.accentCoral,
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
      // Display — onboarding / marketing heroes.
      displayLarge: TextStyle(
        fontSize: 46,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
        color: primary,
        height: 1.0,
      ),
      displayMedium: TextStyle(
        fontSize: 37,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.3,
        color: primary,
        height: 1.04,
      ),
      displaySmall: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: primary,
        height: 1.08,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        color: primary,
        height: 1.06,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: primary,
        height: 1.14,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
        height: 1.18,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: primary,
      ),
    ).apply(fontFamily: EcTokens.fontFamily);
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final accent = isDark ? EcTokens.accentBrandDark : EcTokens.accentBrand;
    final muted = isDark ? EcTokens.textMutedDark : EcTokens.textMutedLight;
    final primaryText =
        isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight;

    return ThemeData(
      useMaterial3: true,
      fontFamily: EcTokens.fontFamily,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: Colors.transparent,
      splashColor: accent.withValues(alpha: 0.10),
      highlightColor: accent.withValues(alpha: 0.05),
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
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: primaryText,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: isDark ? 0.24 : 0.14),
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
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusLg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
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
                ? Colors.white.withValues(alpha: 0.18)
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
            : Colors.white.withValues(alpha: 0.70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.80),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.7), width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        labelStyle: TextStyle(
          fontFamily: EcTokens.fontFamily,
          color: isDark
              ? EcTokens.textSecondaryDark
              : EcTokens.textSecondaryLight,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(fontFamily: EcTokens.fontFamily, color: muted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xF0141A2B)
            : const Color(0xF0FFFFFF),
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
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: primaryText),
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
    accentMint: EcTokens.accentMint,
    accentSky: EcTokens.accentSky,
    accentCoral: EcTokens.accentCoral,
    accentPlum: EcTokens.accentPlum,
    accentMintFill: EcTokens.accentMintFill,
    accentMintText: EcTokens.accentMintText,
    accentBlushFill: EcTokens.accentBlushFill,
    accentBlushText: EcTokens.accentBlushText,
    accentAmberFill: EcTokens.accentAmberFill,
    accentAmberText: EcTokens.accentAmberText,
    accentSkyFill: EcTokens.accentSkyFill,
  );

  static const EcColors dark = EcColors(
    textSecondary: EcTokens.textSecondaryDark,
    textMuted: EcTokens.textMutedDark,
    textCritical: EcTokens.textCriticalDark,
    bgCard: EcTokens.bgCardDark,
    bgRecessed: EcTokens.bgRecessedDark,
    accentBrand: EcTokens.accentBrandDark,
    accentMint: EcTokens.accentMintDark,
    accentSky: Color(0xFF6FB0FF),
    accentCoral: EcTokens.accentCoral,
    accentPlum: EcTokens.accentPlum,
    accentMintFill: Color(0x2910D9A0),
    accentMintText: Color(0xFF5FEAC2),
    accentBlushFill: Color(0x29FF6F91),
    accentBlushText: Color(0xFFFF9DB5),
    accentAmberFill: Color(0x29FFB23E),
    accentAmberText: Color(0xFFFFD27A),
    accentSkyFill: Color(0x293A86FF),
  );

  @override
  EcColors copyWith({
    Color? textSecondary,
    Color? textMuted,
    Color? textCritical,
    Color? bgCard,
    Color? bgRecessed,
    Color? accentBrand,
    Color? accentMint,
    Color? accentSky,
    Color? accentCoral,
    Color? accentPlum,
    Color? accentMintFill,
    Color? accentMintText,
    Color? accentBlushFill,
    Color? accentBlushText,
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

/// Glass surface tokens for liquid glass UI.
class EcGlass extends ThemeExtension<EcGlass> {
  const EcGlass({
    required this.fill,
    required this.fillElevated,
    required this.fillSubtle,
    required this.border,
    required this.borderStrong,
    required this.highlight,
    required this.navFill,
    required this.tintBrand,
    required this.shadowColor,
  });

  final Color fill;
  final Color fillElevated;
  final Color fillSubtle;
  final Color border;
  final Color borderStrong;
  final Color highlight;
  final Color navFill;
  final Color tintBrand;
  final Color shadowColor;

  static EcGlass of(BuildContext context) =>
      Theme.of(context).extension<EcGlass>()!;

  static final EcGlass light = EcGlass(
    fill: Colors.white.withValues(alpha: 0.80),
    fillElevated: Colors.white.withValues(alpha: 0.92),
    fillSubtle: Colors.white.withValues(alpha: 0.55),
    border: Colors.white.withValues(alpha: 0.95),
    borderStrong: Colors.white,
    highlight: Colors.white,
    navFill: Colors.white.withValues(alpha: 0.82),
    tintBrand: EcTokens.accentBrand,
    shadowColor: const Color(0xFF211A4D),
  );

  static final EcGlass dark = EcGlass(
    fill: const Color(0xFF161B2E).withValues(alpha: 0.58),
    fillElevated: const Color(0xFF1C2440).withValues(alpha: 0.74),
    fillSubtle: const Color(0xFF10131F).withValues(alpha: 0.52),
    border: Colors.white.withValues(alpha: 0.12),
    borderStrong: Colors.white.withValues(alpha: 0.24),
    highlight: Colors.white.withValues(alpha: 0.16),
    navFill: const Color(0xFF0B0E18).withValues(alpha: 0.74),
    tintBrand: EcTokens.accentBrandDark,
    shadowColor: Colors.black,
  );

  @override
  EcGlass copyWith({
    Color? fill,
    Color? fillElevated,
    Color? fillSubtle,
    Color? border,
    Color? borderStrong,
    Color? highlight,
    Color? navFill,
    Color? tintBrand,
    Color? shadowColor,
  }) {
    return EcGlass(
      fill: fill ?? this.fill,
      fillElevated: fillElevated ?? this.fillElevated,
      fillSubtle: fillSubtle ?? this.fillSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      highlight: highlight ?? this.highlight,
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
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
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
