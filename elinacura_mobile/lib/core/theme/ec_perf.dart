import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ec_motion.dart';

/// Rendering tier for liquid-glass blur budget and animation density.
enum EcPerfTier { high, standard, low }

/// Decides whether BackdropFilter liquid glass is affordable on this device.
class EcPerf {
  EcPerf._();

  static EcPerfTier tierOf(BuildContext context) {
    if (EcMotion.reducedMotionOf(context)) return EcPerfTier.low;
    if (kIsWeb) return EcPerfTier.standard;
    try {
      if (Platform.isIOS || Platform.isMacOS) return EcPerfTier.high;
      if (Platform.isAndroid) {
        final views = WidgetsBinding.instance.platformDispatcher.views;
        if (views.isEmpty) return EcPerfTier.standard;
        final ratio = views.first.devicePixelRatio;
        return ratio > 3.0 ? EcPerfTier.standard : EcPerfTier.high;
      }
    } catch (_) {}
    return EcPerfTier.standard;
  }

  static bool useLiquidBlur(BuildContext context) =>
      tierOf(context) != EcPerfTier.low;

  /// Max simultaneous BackdropFilter surfaces recommended on screen.
  static int maxBlurSurfaces(BuildContext context) => switch (tierOf(context)) {
        EcPerfTier.high => 4,
        EcPerfTier.standard => 3,
        EcPerfTier.low => 0,
      };

  static double blurSigma(BuildContext context, double sigma) {
    if (!useLiquidBlur(context)) return 0;
    return switch (tierOf(context)) {
      EcPerfTier.high => sigma,
      EcPerfTier.standard => sigma * 0.85,
      EcPerfTier.low => 0,
    };
  }
}
