import 'package:flutter/material.dart';

/// ElinaCura design tokens — Google-Health-inspired premium health OS.
///
/// Light mode: soft blue-white canvas, solid white cards, semantic category
/// colors per health domain. Dark mode: deep navy canvas, frosted glass.
/// Color is purposeful: each category owns one hue, used consistently across
/// icons, charts, chips, and arcs. Status colors (positive/caution/critical)
/// are strictly for state, never decoration.
class EcTokens {
  EcTokens._();

  static const String fontFamily = 'Geist';

  // ─────────────────────────────────────────────────── Canvas backgrounds ──
  /// Light: soft blue-white (Google Health inspired).
  static const Color bgVoidLight = Color(0xFFEEF2FF);
  /// Dark: deep obsidian navy.
  static const Color bgVoid = Color(0xFF0A0A0F);

  static const Color bgAppLight = bgVoidLight;
  static const Color bgAppDark = bgVoid;

  /// Card surfaces (solid in light, frosted in dark).
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgCardDark = Color(0xFF14141A);
  static const Color bgRecessedLight = Color(0xFFE4E9FF);
  static const Color bgRecessedDark = Color(0xFF0E0E14);

  // ─────────────────────────────────────────────────────────────── Text ──
  static const Color textPrimaryLight = Color(0xFF1A1C2E);
  static const Color textPrimaryDark = Color(0xFFF0F2FF);
  static const Color textSecondaryLight = Color(0xFF4A5068);
  static const Color textSecondaryDark = Color(0xFFAAAEC4);
  static const Color textMutedLight = Color(0xFF7C829E);
  static const Color textMutedDark = Color(0xFF6A6E88);
  static const Color textCriticalLight = Color(0xFFB42318);
  static const Color textCriticalDark = Color(0xFFFCA5A5);

  // ──────────────────────────────────────────── Brand (ink / paper) ──
  /// Single brand accent: near-black in light, near-white in dark.
  static const Color accentBrand = Color(0xFF1A1C2E);
  static const Color accentBrandDark = Color(0xFFF0F2FF);
  static const Color accentBrandDeep = Color(0xFF000000);
  static const Color onAccentLight = Color(0xFFFFFFFF);
  static const Color onAccentDark = Color(0xFF0A0A0F);

  // ─────────────────────────────── Health category colors (GH-inspired) ──
  // Each health domain owns exactly one hue. Used for icons, chart lines,
  // arc strokes, and chip fills. Never used as page backgrounds.

  /// Activity / steps / workouts — Google blue.
  static const Color categoryActivity = Color(0xFF4285F4);
  static const Color categoryActivityLight = Color(0xFFE8F0FE);

  /// Sleep — muted indigo.
  static const Color categorySleep = Color(0xFF7C6AF5);
  static const Color categorySleepLight = Color(0xFFEDE9FE);

  /// Heart rate / HR / vitals — warm red.
  static const Color categoryHeart = Color(0xFFE84040);
  static const Color categoryHeartLight = Color(0xFFFFEBEB);

  /// Weight / body composition — sky blue.
  static const Color categoryWeight = Color(0xFF0EA5E9);
  static const Color categoryWeightLight = Color(0xFFE0F2FE);

  /// Blood oxygen / breathing — teal.
  static const Color categoryBreathing = Color(0xFF0D9488);
  static const Color categoryBreathingLight = Color(0xFFCCFBF1);

  /// Nutrition / medications — forest green.
  static const Color categoryNutrition = Color(0xFF16A34A);
  static const Color categoryNutritionLight = Color(0xFFDCFCE7);

  /// HRV / recovery — purple.
  static const Color categoryRecovery = Color(0xFF9333EA);
  static const Color categoryRecoveryLight = Color(0xFFF3E8FF);

  // ─────────────────────────────────── Semantic status (state only) ──
  static const Color statusPositive = Color(0xFF2E9E73);
  static const Color statusPositiveLight = Color(0xFFD1FAE5);
  static const Color statusCaution = Color(0xFFB8861F);
  static const Color statusCautionLight = Color(0xFFFEF9C3);
  static const Color statusWarning = Color(0xFFC2691F);
  static const Color statusCritical = Color(0xFFC0392B);
  static const Color statusCriticalLight = Color(0xFFFFEBEB);

  // ─────────── Legacy accent aliases (kept for backward compat) ──
  static const Color accentMint = Color(0xFF16A34A);
  static const Color accentMintDark = Color(0xFF6FD4AE);
  static const Color accentMintFill = Color(0xFFD1FAE5);
  static const Color accentMintText = Color(0xFF166534);
  static const Color accentSky = Color(0xFF0EA5E9);
  static const Color accentSkyFill = Color(0xFFE0F2FE);
  static const Color accentSkyText = Color(0xFF0369A1);
  static const Color accentCoral = Color(0xFFC56B6B);
  static const Color accentEnergy = Color(0xFFC1794F);
  static const Color accentBlushFill = Color(0xFFFFEBEB);
  static const Color accentBlushText = Color(0xFFA33A3A);
  static const Color accentAmber = Color(0xFFC79A3E);
  static const Color accentAmberFill = Color(0xFFFEF9C3);
  static const Color accentAmberText = Color(0xFF92620D);
  static const Color accentPlum = Color(0xFF8A7CA0);
  static const Color auroraViolet = Color(0xFFFFFFFF);
  static const Color auroraIndigo = Color(0xFFE6E6E6);
  static const Color auroraBlue = Color(0xFFD8D8D8);
  static const Color auroraCyan = Color(0xFFEDEDED);
  static const Color auroraMint = Color(0xFFFFFFFF);
  static const Color auroraCoral = Color(0xFFE0E0E0);
  static const Color auroraPlum = Color(0xFFDADADA);
  static const Color auroraDeep = Color(0xFF101012);

  // ────────────────────────────────────────────────────────── Radii ──
  static const double radiusXs = 10;
  static const double radiusSm = 14;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusCard = 20;
  static const double radiusHero = 28;
  static const double radiusGlass = 24;
  static const double radiusFull = 999;

  // ─────────────────────────────────────────────────── Spacing (8pt) ──
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space64 = 64;

  // ─────────────────────────────── Glass blur Z-layers (dark mode) ──
  static const double glassBlurZ2 = 24;
  static const double glassBlurZ3 = 40;
  static const double glassBlurZ4 = 56;
  static const double glassBlur = glassBlurZ2;
  static const double glassBlurHeavy = glassBlurZ4;
  static const double glassBlurLight = 16;
  static const double glassBlurUltra = glassBlurZ4;

  static const double glassZ2Opacity = 0.07;
  static const double glassZ3Opacity = 0.10;
  static const double glassZ4Opacity = 0.13;
  static const double glassSpecularTopOpacity = 0.22;
  static const double glassSpecularSideOpacity = 0.09;
  static const double glassBorderOpacity = 0.10;

  // ──────────────────────────────────────────── Typography (display) ──
  static const double fontSizeDisplayXL = 80.0;
  static const double letterSpacingDisplayXL = -4.0;
  static const double fontSizeDisplayLg = 52.0;
  static const double letterSpacingDisplayLg = -2.5;

  // ──────────────────────────────────────────────────────── Motion ──
  static const Duration motionInstant = Duration(milliseconds: 90);
  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionBase = Duration(milliseconds: 300);
  static const Duration motionSlow = Duration(milliseconds: 500);
  static const Duration motionExpressive = Duration(milliseconds: 700);
  static const Duration staggerItem = Duration(milliseconds: 55);
  static const Curve curveEmphasized = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.easeOutBack;
  static const Curve curveStandard = Curves.easeInOutCubic;
}
