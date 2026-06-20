import 'package:flutter/material.dart';

/// ElinaCura brand mark — glossy 3D emblem, theme-aware.
///
/// Shows the black glossy logo on light backgrounds and the white/frosted
/// glossy logo on dark backgrounds. Both are transparent PNGs.
class EcLogo extends StatelessWidget {
  const EcLogo({
    super.key,
    this.size = 120,
    this.semanticLabel = 'ElinaCura',
    this.brightness,
  });

  final double size;
  final String semanticLabel;

  /// Force a specific variant regardless of the ambient theme. When null the
  /// logo follows [Theme.of(context).brightness].
  final Brightness? brightness;

  static const lightAsset = 'assets/images/logo_light.png'; // black, for light bg
  static const darkAsset = 'assets/images/logo_dark.png'; // white, for dark bg

  @override
  Widget build(BuildContext context) {
    final isDark = (brightness ?? Theme.of(context).brightness) == Brightness.dark;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.asset(
        isDark ? darkAsset : lightAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
