import 'package:flutter/material.dart';

/// ElinaCura design tokens — "Aurora" premium system.
///
/// A cool-toned, vibrant glassmorphism language tuned for a modern health,
/// wellness & fitness product. Dark mode is the hero surface (deep indigo
/// space + flowing aurora light); light mode is an airy, cool near-white.
///
/// Naming is kept stable across the app — values are re-tuned, new tokens are
/// added, nothing the rest of the app depends on is removed.
class EcTokens {
  EcTokens._();

  /// Primary typeface (Geist Sans, bundled in assets/fonts).
  static const String fontFamily = 'Geist';

  // ───────────────────────────────────────────────────────────── Surfaces ──
  // Dark is the signature surface; light stays cool and bright.
  static const Color bgAppLight = Color(0xFFF1F2FB);
  static const Color bgAppDark = Color(0xFF06070F);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgCardDark = Color(0xFF141A2B);
  static const Color bgRecessedLight = Color(0xFFE6E8F5);
  static const Color bgRecessedDark = Color(0xFF0A0C16);

  /// Background gradient ramps (top → bottom).
  static const List<Color> bgRampLight = [
    Color(0xFFF7F8FF),
    Color(0xFFEFF1FB),
    Color(0xFFE7EAF7),
  ];
  static const List<Color> bgRampDark = [
    Color(0xFF0A0C18),
    Color(0xFF080A14),
    Color(0xFF05060D),
  ];

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
  // Vivid violet — premium, modern, energetic without being loud.
  static const Color accentBrand = Color(0xFF6C4FF5);
  static const Color accentBrandDark = Color(0xFF9D86FF);
  static const Color accentBrandDeep = Color(0xFF5638D6);

  // Wellness — mint / emerald.
  static const Color accentMint = Color(0xFF10D9A0);
  static const Color accentMintDark = Color(0xFF3DE9B6);
  static const Color accentMintFill = Color(0xFFD8F6EC);
  static const Color accentMintText = Color(0xFF0B7A5B);

  // Insight — sky blue.
  static const Color accentSky = Color(0xFF3A86FF);
  static const Color accentSkyFill = Color(0xFFDCE9FF);
  static const Color accentSkyText = Color(0xFF1E5BC6);

  // Fitness / energy — coral & rose.
  static const Color accentCoral = Color(0xFFFF6F91);
  static const Color accentEnergy = Color(0xFFFF8A5B);
  static const Color accentBlushFill = Color(0xFFFFE0E7);
  static const Color accentBlushText = Color(0xFFD11D54);

  // Focus / vitamin — amber.
  static const Color accentAmber = Color(0xFFFFB23E);
  static const Color accentAmberFill = Color(0xFFFFEFCC);
  static const Color accentAmberText = Color(0xFF9A6400);

  // Calm — violet-plum (sleep / mindfulness).
  static const Color accentPlum = Color(0xFFB15CFF);

  // ──────────────────────────────────────────────────────────── Statuses ──
  static const Color statusPositive = Color(0xFF0FB57D);
  static const Color statusCaution = Color(0xFFC98A00);
  static const Color statusWarning = Color(0xFFD8631F);
  static const Color statusCritical = Color(0xFFE11D48);

  // ───────────────────────────────────────────────── Aurora accent hues ──
  // Vibrant accent hues for hero data viz. Backgrounds use a SINGLE hue at a
  // time (see onboarding) — never a multi-hue blend.
  static const Color auroraViolet = Color(0xFF7C5CFF);
  static const Color auroraIndigo = Color(0xFF4F46E5);
  static const Color auroraBlue = Color(0xFF3A86FF);
  static const Color auroraCyan = Color(0xFF22D3EE);
  static const Color auroraMint = Color(0xFF15E0A6);
  static const Color auroraCoral = Color(0xFFFF6F91);
  static const Color auroraPlum = Color(0xFFB15CFF);

  /// Deep base used as the darkest stop of a single-hue backdrop ramp.
  static const Color auroraDeep = Color(0xFF241B66);

  // ───────────────────────────────────────────────────────────── Gradients ──
  static const List<Color> gradientBrand = [
    Color(0xFF9D86FF),
    Color(0xFF6C4FF5),
    Color(0xFF5638D6),
  ];
  static const List<Color> gradientMint = [
    Color(0xFF59F0C6),
    Color(0xFF10C893),
  ];
  static const List<Color> gradientSky = [
    Color(0xFF73B6FF),
    Color(0xFF3A6BFF),
  ];
  static const List<Color> gradientCoral = [
    Color(0xFFFFA17A),
    Color(0xFFFF5C8A),
  ];
  static const List<Color> gradientPlum = [
    Color(0xFFC78BFF),
    Color(0xFF7C5CFF),
  ];

  /// Signature multi-stop aurora sweep.
  static const List<Color> gradientAurora = [
    Color(0xFF7C5CFF),
    Color(0xFF3A86FF),
    Color(0xFF15E0A6),
  ];

  static const LinearGradient brandSweep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: gradientBrand,
  );

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

  // ────────────────────────────────────────────────────── Spacing (8pt) ──
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

  // ──────────────────────────────────────────────── Liquid glass depths ──
  static const double glassBlur = 30;
  static const double glassBlurHeavy = 50;
  static const double glassBlurLight = 18;
  static const double glassBlurUltra = 64;

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
