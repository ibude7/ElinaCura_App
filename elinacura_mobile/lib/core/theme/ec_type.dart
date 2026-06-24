import 'package:flutter/material.dart';

import 'ec_tokens.dart';

/// ElinaCura typography helpers — Chromatic Obsidian precision pairing.
///
/// • [display] / [hero] / [metric] — Bricolage Grotesque, for large numbers
///   (vitals, adherence %, counts). Wide letterforms read well for health data.
/// • [ui] — DM Sans, the body/UI face (this is the theme default, so most text
///   needs no helper).
/// • [mono] — JetBrains Mono, only for timestamps, IDs, and time chips.
class EcType {
  EcType._();

  /// Hero metric — e.g. the adherence "0%" at 64sp.
  static TextStyle hero({
    required Color color,
    double size = 64,
    FontWeight weight = FontWeight.w800,
    double letterSpacing = -2.0,
  }) =>
      TextStyle(
        fontFamily: EcTokens.fontFamilyDisplay,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        height: 1.0,
      );

  /// Secondary metric — e.g. 32sp vitals numbers.
  static TextStyle metric({
    required Color color,
    double size = 32,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = -1.0,
  }) =>
      TextStyle(
        fontFamily: EcTokens.fontFamilyDisplay,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        height: 1.05,
      );

  /// Generic display face at an arbitrary size.
  static TextStyle display({
    required Color color,
    required double size,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = -0.5,
    double height = 1.1,
  }) =>
      TextStyle(
        fontFamily: EcTokens.fontFamilyDisplay,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        height: height,
      );

  /// Monospace — timestamps, IDs, Care Rhythm time chips.
  static TextStyle mono({
    required Color color,
    double size = 11,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0.2,
  }) =>
      TextStyle(
        fontFamily: EcTokens.fontFamilyMono,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
      );

  /// Uppercase gold time label used on Care Rhythm cards (11sp).
  static TextStyle timeLabel({required Color color}) => TextStyle(
        fontFamily: EcTokens.fontFamilyMono,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: color,
      );

  /// Floating section label — 12sp uppercase, used above card clusters.
  static TextStyle sectionLabel({required Color color}) => TextStyle(
        fontFamily: EcTokens.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: color,
      );
}
