import 'package:flutter/material.dart';

/// Subtle parallax tilt on medication cards (Rec #24).
class EcMedCardParallax extends StatefulWidget {
  const EcMedCardParallax({super.key, required this.child});

  final Widget child;

  @override
  State<EcMedCardParallax> createState() => _EcMedCardParallaxState();
}

class _EcMedCardParallaxState extends State<EcMedCardParallax> {
  Offset _tilt = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(e.position);
        final w = box.size.width;
        final h = box.size.height;
        setState(() {
          _tilt = Offset(
            (local.dx / w - 0.5) * 0.04,
            (local.dy / h - 0.5) * 0.04,
          );
        });
      },
      onPointerUp: (_) => setState(() => _tilt = Offset.zero),
      onPointerCancel: (_) => setState(() => _tilt = Offset.zero),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(-_tilt.dy)
          ..rotateY(_tilt.dx),
        child: widget.child,
      ),
    );
  }
}
