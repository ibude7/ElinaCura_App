import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/ec_theme.dart';

/// Live voice waveform visualization (Rec #18).
class EcVoiceWaveform extends StatelessWidget {
  const EcVoiceWaveform({
    super.key,
    required this.active,
    this.level = 0.5,
    this.bars = 24,
  });

  final bool active;
  final double level;
  final int bars;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final color = active ? ec.accentBrand : ec.textMuted;

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(bars, (i) {
          final phase = (i / bars) * math.pi;
          final h = active
              ? 8 + (level.clamp(0.0, 1.0) * 32) * (0.4 + 0.6 * math.sin(phase))
              : 6.0;
          return AnimatedContainer(
            duration: Duration(milliseconds: 80 + (i % 5) * 20),
            curve: Curves.easeOut,
            width: 3,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: active ? 0.85 : 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
