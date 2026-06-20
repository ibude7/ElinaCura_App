import 'package:flutter/material.dart';

/// EC design tokens ported from frontend/src/foundation/tokens.js
class EcTokens {
  EcTokens._();

  static const Color bgAppLight = Color(0xFFF5F1EA);
  static const Color bgAppDark = Color(0xFF06090E);
  static const Color bgCardLight = Color(0xFFFDFBF7);
  static const Color bgCardDark = Color(0xFF161D2A);
  static const Color bgRecessedLight = Color(0xFFEBE5DC);
  static const Color bgRecessedDark = Color(0xFF080C12);

  static const Color textPrimaryLight = Color(0xFF1A1A1F);
  static const Color textPrimaryDark = Color(0xFFE7ECF2);
  static const Color textSecondaryLight = Color(0xFF52525B);
  static const Color textSecondaryDark = Color(0xFFAAB4C0);
  static const Color textMutedLight = Color(0xFF58585F);
  static const Color textMutedDark = Color(0xFF8B95A1);
  static const Color textCriticalLight = Color(0xFFB91C1C);
  static const Color textCriticalDark = Color(0xFFFCA5A5);

  static const Color accentBrand = Color(0xFFC03F0C);
  static const Color accentBrandDark = Color(0xFFFB7244);
  static const Color accentMintFill = Color(0xFFD6EFE2);
  static const Color accentMintText = Color(0xFF0F6E54);
  static const Color accentSkyFill = Color(0xFFDBE8FB);
  static const Color accentSkyText = Color(0xFF1D5FA8);
  static const Color accentBlushFill = Color(0xFFFBE0EC);
  static const Color accentBlushText = Color(0xFFAD2A64);
  static const Color accentAmberFill = Color(0xFFFBECC9);
  static const Color accentAmberText = Color(0xFF8A5A08);

  static const Color statusPositive = Color(0xFF0F766E);
  static const Color statusCaution = Color(0xFFA16207);
  static const Color statusWarning = Color(0xFFC2410C);
  static const Color statusCritical = Color(0xFFBE123C);

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusCard = 16;
  static const double radiusHero = 24;
  static const double radiusGlass = 28;

  // Liquid glass — premium blur depths
  static const double glassBlur = 32;
  static const double glassBlurHeavy = 48;
  static const double glassBlurLight = 22;

  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionBase = Duration(milliseconds: 320);
  static const Duration staggerItem = Duration(milliseconds: 40);
}
