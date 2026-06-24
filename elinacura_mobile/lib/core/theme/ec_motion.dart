import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'ec_tokens.dart';

/// Central motion registry — durations and curves aligned with the PWA motion
/// system. Honors reduced-motion preferences app-wide.
class EcMotion {
  EcMotion._();

  static const Duration instant = EcTokens.motionInstant;
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration expressive = EcTokens.motionExpressive;
  static const Duration staggerStep = Duration(milliseconds: 40);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve standard = Curves.easeInOutCubic;

  static bool reducedMotionOf(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context) ||
        SchedulerBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
  }

  static Duration resolve(BuildContext context, Duration normal) {
    return reducedMotionOf(context) ? Duration.zero : normal;
  }

  static Duration staggerIndex(BuildContext context, int index) {
    if (reducedMotionOf(context)) return Duration.zero;
    return staggerStep * index.clamp(0, 12);
  }
}

/// Wraps [child] with a standard entrance animation.
class EcMotionEntrance extends StatelessWidget {
  const EcMotionEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.axis = Axis.vertical,
  });

  final Widget child;
  final int index;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    if (EcMotion.reducedMotionOf(context)) return child;
    final delay = EcMotion.staggerIndex(context, index);
    return child
        .animate()
        .fadeIn(duration: EcMotion.base, curve: EcMotion.emphasized, delay: delay)
        .slide(
          begin: axis == Axis.vertical ? const Offset(0, 0.04) : const Offset(0.03, 0),
          end: Offset.zero,
          duration: EcMotion.base,
          curve: EcMotion.emphasized,
          delay: delay,
        );
  }
}
