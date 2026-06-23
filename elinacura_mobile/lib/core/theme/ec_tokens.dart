import 'package:flutter/material.dart';

/// ElinaCura design tokens — "Elina Glass" liquid system.
///
/// True liquid glass: neutral white-frosted surfaces, deep void backgrounds
/// with ambient depth blobs, and solid semantic accent colors.
/// No gradient fills — color comes from scene objects behind the glass.
class EcTokens {
  EcTokens._();

  /// Primary typeface (Geist Sans, bundled in assets/fonts).
  static const String fontFamily = 'Geist';

  // ───────────────────────────────────────────────────────────── Surfaces ──
  // Pure void backgrounds — no gradient ramps.
  static const Color bgVoid = Color(0xFF080810);       // deep indigo-void
  static const Color bgVoidLight = Color(0xFFF3F4FD);  // airy cool light

  // Legacy aliases kept for compatibility across the design system.
  static const Color bgAppLight = bgVoidLight;
  static const Color bgAppDark = bgVoid;

  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgCardDark = Color(0xFF141A2B);
  static const Color bgRecessedLight = Color(0xFFE6E8F5);
  static const Color bgRecessedDark = Color(0xFF0A0C16);

  // ───────────────────────────────────────────────────────────────── Text ──
  static const Color textPrimaryLight = Color(0xFF11131F);
  static const Color textPrimaryDark = Color(0xFFF3F5FF);
  static const Color textSecondaryLight = Color(0xFF4C5167);
  static const Color textSecondaryDark = Color(0xFFA7AEC8);
  static const Color textMutedLight = Color(0xFF7B8098);
  static const Color textMutedDark = Color(0xFF6E7593);
  static const Color textCriticalLight = Color(0xFFC81E4A);
  static const Color textCriticalDark = Color(0xFFFF9DB5);

  // ──────────────────────────────────────────────────────────────── Brand ──
  // Vivid violet — premium, modern.
  static const Color accentBrand = Color(0xFF6C4FF5);
  static const Color accentBrandDark = Color(0xFF9D86FF);
  static const Color accentBrandDeep = Color(0xFF5638D6);

  // Wellness — mint.
  static const Color accentMint = Color(0xFF10D9A0);
  static const Color accentMintDark = Color(0xFF3DE9B6);
  static const Color accentMintFill = Color(0xFFD8F6EC);
  static const Color accentMintText = Color(0xFF0B7A5B);

  // Insight — sky blue.
  static const Color accentSky = Color(0xFF3A86FF);
  static const Color accentSkyFill = Color(0xFFDCE9FF);
  static const Color accentSkyText = Color(0xFF1E5BC6);

  // Energy — coral.
  static const Color accentCoral = Color(0xFFFF6F91);
  static const Color accentEnergy = Color(0xFFFF8A5B);
  static const Color accentBlushFill = Color(0xFFFFE0E7);
  static const Color accentBlushText = Color(0xFFD11D54);

  // Focus — amber.
  static const Color accentAmber = Color(0xFFFFB23E);
  static const Color accentAmberFill = Color(0xFFFFEFCC);
  static const Color accentAmberText = Color(0xFF9A6400);

  // Calm — plum.
  static const Color accentPlum = Color(0xFFB15CFF);

  // ──────────────────────────────────────────────────────────── Statuses ──
  static const Color statusPositive = Color(0xFF0FB57D);
  static const Color statusCaution = Color(0xFFC98A00);
  static const Color statusWarning = Color(0xFFD8631F);
  static const Color statusCritical = Color(0xFFE11D48);

  // ───────────────────────────────────────────────── Aurora accent hues ──
  // Used for depth-scene blobs painted behind glass, and data viz.
  // These are scene-level objects — NOT UI fills.
  static const Color auroraViolet = Color(0xFF7C5CFF);
  static const Color auroraIndigo = Color(0xFF4F46E5);
  static const Color auroraBlue = Color(0xFF3A86FF);
  static const Color auroraCyan = Color(0xFF22D3EE);
  static const Color auroraMint = Color(0xFF15E0A6);
  static const Color auroraCoral = Color(0xFFFF6F91);
  static const Color auroraPlum = Color(0xFFB15CFF);
  static const Color auroraDeep = Color(0xFF241B66);

  // ─────────────────────────────────────────────────────────────── Radii ──
  static const double radiusXs = 10;
  static const double radiusSm = 14;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusCard = 22;
  static const double radiusHero = 28;
  static const double radiusGlass = 34;
  static const double radiusFull = 999;

  // ────────────────────────────────────────────────── Spacing (8pt) ──
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

  // ─────────────────────────────────────── Liquid glass Z-depth system ──
  // Blur intensity per depth layer (content → elevated → floating).
  static const double glassBlurZ2 = 28; // base content
  static const double glassBlurZ3 = 44; // elevated cards / headers
  static const double glassBlurZ4 = 60; // floating (nav, modals, sheets)

  // Legacy aliases kept for EcGlassSurface compatibility.
  static const double glassBlur = glassBlurZ2;
  static const double glassBlurHeavy = glassBlurZ4;
  static const double glassBlurLight = 18;
  static const double glassBlurUltra = glassBlurZ4;

  // Neutral white-fill opacity per Z-depth (dark mode).
  // Glass is colorless — it reveals the ambient scene behind it through blur.
  static const double glassZ2Opacity = 0.07;
  static const double glassZ3Opacity = 0.10;
  static const double glassZ4Opacity = 0.13;

  // Specular edge opacities — directional light catch from top-left.
  static const double glassSpecularTopOpacity = 0.22; // 1px top-edge line
  static const double glassSpecularSideOpacity = 0.10; // 0.5px left-edge line
  static const double glassBorderOpacity = 0.12;

  // ────────────────────────────────────────────────── Typography (XL) ──
  // Extended display scale beyond Material defaults.
  static const double fontSizeDisplayXL = 80.0; // clock / data hero
  static const double letterSpacingDisplayXL = -4.0;
  static const double fontSizeDisplayLg = 52.0; // large stat / greeting
  static const double letterSpacingDisplayLg = -2.5;

  // ──────────────────────────────────────────────────────────── Motion ──
  static const Duration motionInstant = Duration(milliseconds: 90);
  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionBase = Duration(milliseconds: 340);
  static const Duration motionSlow = Duration(milliseconds: 560);
  static const Duration motionExpressive = Duration(milliseconds: 760);
  static const Duration staggerItem = Duration(milliseconds: 60);

  static const Curve curveEmphasized = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.easeOutBack;
  static const Curve curveStandard = Curves.easeInOutCubic;
}
