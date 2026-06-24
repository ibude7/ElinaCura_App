import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Subtle guilloché engraved line pattern for Care Passport (Rec #20, #39).
class EcGuillochePainter extends CustomPainter {
  const EcGuillochePainter({this.opacity = 0.08});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(size.width, size.height) * 0.48;

    for (var i = 0; i < 24; i++) {
      final angle = i * math.pi / 12;
      final path = Path();
      for (var t = 0.0; t <= math.pi * 2; t += 0.05) {
        final r = maxR * (0.55 + 0.45 * math.sin(6 * t + angle));
        final x = cx + r * math.cos(t + angle);
        final y = cy + r * math.sin(t + angle);
        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(EcGuillochePainter old) => old.opacity != opacity;
}

class EcGuillocheBackdrop extends StatelessWidget {
  const EcGuillocheBackdrop({super.key, required this.child, this.opacity});

  final Widget child;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: EcGuillochePainter(
              opacity: opacity ?? (isDark ? 0.12 : 0.06),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
