import 'package:flutter/material.dart';

/// ElinaCura design tokens — premium health OS.
///
/// Light mode: airy blue-white canvas, pastel category cards (Google Health–inspired).
/// Dark mode: obsidian void, frosted liquid glass with category accents.
/// Category hues are data-only — never used as page backgrounds.
/// Color is purposeful: each category owns one hue, used consistently across
/// icons, charts, chips, and arcs. Status colors (positive/caution/critical)
/// are strictly for state, never decoration.
class EcTokens {
  EcTokens._();

  /// UI / body — DM Sans (humanist, legible at 13–15sp).
  static const String fontFamily = 'DM Sans';

  /// Display / data numbers — Bricolage Grotesque (wide letterforms for metrics).
  static const String fontFamilyDisplay = 'Bricolage Grotesque';

  /// Time / IDs / code — JetBrains Mono (precise, clinical).
  static const String fontFamilyMono = 'JetBrains Mono';

  // ─────────────────────────────────────────────────── Canvas backgrounds ──
  /// Light: airy blue-white canvas (Google Health–inspired).
  static const Color bgVoidLight = Color(0xFFEEF3FB);
  /// Dark: Chromatic Obsidian — near-black with a faint cool tint.
  static const Color bgVoid = Color(0xFF080A0F);

  static const Color bgAppLight = bgVoidLight;
  static const Color bgAppDark = bgVoid;

  /// Card surfaces — solid white in light, frosted obsidian in dark.
  /// Dark surface ladder (Chromatic Obsidian):
  ///   L1 #0F1219 base cards · L2 #161C26 modals/sheets · L3 #1D2333 innermost.
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgCardDark = Color(0xFF0F1219); // Surface L1
  static const Color surfaceL2Dark = Color(0xFF161C26); // modals, sheets, popovers
  static const Color surfaceL3Dark = Color(0xFF1D2333); // toasts, tooltips, innermost
  static const Color bgRecessedLight = Color(0xFFE4EDF8);
  static const Color bgRecessedDark = Color(0xFF0B0D13);

  /// Soft category washes for card backgrounds (light mode).
  static const Color washActivity = Color(0xFFE8F0FE);
  static const Color washSleep = Color(0xFFEDE9FE);
  static const Color washHeart = Color(0xFFFFEBEB);
  static const Color washNutrition = Color(0xFFDCFCE7);
  static const Color washRecovery = Color(0xFFF3E8FF);
  static const Color washWeight = Color(0xFFE0F2FE);
  static const Color washBreathing = Color(0xFFCCFBF1);
  static const Color washCaution = Color(0xFFFFF7ED);

  // ─────────────────────────────────────────────────────────────── Text ──
  static const Color textPrimaryLight = Color(0xFF1A1C2E);
  static const Color textPrimaryDark = Color(0xFFEDF0F7);
  static const Color textSecondaryLight = Color(0xFF4A5068);
  static const Color textSecondaryDark = Color(0xFF8A93A8);
  static const Color textMutedLight = Color(0xFF7C829E);
  static const Color textMutedDark = Color(0xFF4A5568);
  static const Color textCriticalLight = Color(0xFFB42318);
  static const Color textCriticalDark = Color(0xFFFCA5A5);

  // ──────────────────────────────────────────── Brand ──
  /// Forest green — logo, primary CTA accents (dot usage, not backgrounds).
  static const Color brandForest = Color(0xFF1A3C34);
  /// Terracotta — warmth accents (logo dot, critical warmth).
  static const Color brandTerracotta = Color(0xFFC03F0C);

  /// Chromatic Obsidian signature accents.
  /// Primary — warm antique gold (aged brass; premium health, not gamification).
  static const Color accentGold = Color(0xFFC8A96E);
  /// Secondary — desaturated jade. Success states + active health metrics only.
  static const Color accentJade = Color(0xFF4FC3A1);

  /// Ink / paper brand accents for UI chrome.
  /// Dark: antique gold is the primary identity accent.
  static const Color accentBrand = Color(0xFF1A1C2E);
  static const Color accentBrandDark = accentGold;
  static const Color accentBrandDeep = Color(0xFF000000);
  static const Color onAccentLight = Color(0xFFFFFFFF);
  static const Color onAccentDark = Color(0xFF0A0A0F);

  // ─────────────────────────────── Health category colors (GH-inspired) ──
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

  /// Tab accents — Chromatic Obsidian uses a single gold identity accent for
  /// the active destination (gold dot + icon shift), not per-tab hues.
  static const Color tabToday = accentGold;
  static const Color tabHealth = accentGold;
  static const Color tabCare = accentGold;
  static const Color tabYou = accentGold;

  // ─────────────────────────────────── Semantic status (state only) ──
  static const Color statusPositive = Color(0xFF2E9E73);
  static const Color statusPositiveLight = Color(0xFFD1FAE5);
  static const Color statusCaution = Color(0xFFB8861F);
  static const Color statusCautionLight = Color(0xFFFEF9C3);
  static const Color statusWarning = Color(0xFFC2691F);
  /// Controlled crimson — Emergency / SOS and error states only.
  static const Color statusCritical = Color(0xFFE05757);
  static const Color statusCriticalLight = Color(0xFFFFEBEB);

  // ─────────── Legacy accent aliases (kept for backward compat) ──
  static const Color accentMint = Color(0xFF16A34A);
  static const Color accentMintDark = accentJade;
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
  // Chromatic Obsidian: cards 20 · inner elements 12 · chips/badges full pill.
  static const double radiusXs = 10;
  static const double radiusSm = 12; // inner elements inside cards
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusCard = 20; // cards
  static const double radiusHero = 28;
  static const double radiusGlass = 28;
  static const double radiusFull = 999; // full pill (chips, badges, nav)

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

  // ─────────────────────────────── Glass blur Z-layers (liquid glass) ──
  // Chromatic Obsidian 3-tier system:
  //   Micro Frost   — blur 12, fill 3% (chips, badges, nav pills)
  //   Frosted Sheet — blur 24, fill 4% (cards, timeline items)
  //   Deep Frost    — blur 40, fill 6% (bottom sheets, modals, nav)
  static const double glassBlurZ2 = 12; // Micro Frost
  static const double glassBlurZ3 = 24; // Frosted Sheet
  static const double glassBlurZ4 = 40; // Deep Frost
  static const double glassBlur = glassBlurZ3; // default card = Frosted Sheet
  static const double glassBlurHeavy = glassBlurZ4;
  static const double glassBlurLight = glassBlurZ2;
  static const double glassBlurUltra = glassBlurZ4;

  static const double glassZ2Opacity = 0.03; // Micro Frost
  static const double glassZ3Opacity = 0.04; // Frosted Sheet
  static const double glassZ4Opacity = 0.06; // Deep Frost
  static const double glassSpecularTopOpacity = 0.10; // top-left refraction highlight
  static const double glassSpecularSideOpacity = 0.06;
  static const double glassBorderOpacity = 0.08;
  /// Faint antique-gold glow on elevated/floating glass (premium depth).
  static const double glassGoldGlowOpacity = 0.05;

  // ──────────────────────────────────────────── Typography (display) ──
  static const double fontSizeDisplayXL = 80.0;
  static const double letterSpacingDisplayXL = -4.0;
  static const double fontSizeDisplayLg = 52.0;
  static const double letterSpacingDisplayLg = -2.5;

  // ──────────────────────────────────────────────────────── Motion ──
  static const Duration motionInstant = Duration(milliseconds: 90);
  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionBase = Duration(milliseconds: 320);
  static const Duration motionSlow = Duration(milliseconds: 520);
  static const Duration motionExpressive = Duration(milliseconds: 700);
  static const Duration staggerItem = Duration(milliseconds: 55);
  static const Curve curveEmphasized = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.easeOutBack;
  static const Curve curveStandard = Curves.easeInOutCubic;
}
