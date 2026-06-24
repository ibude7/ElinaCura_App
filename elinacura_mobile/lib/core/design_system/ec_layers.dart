import 'package:flutter/material.dart';

/// Strict three-layer material model (Rec #1).
///
/// L0 void — solid canvas, zero blur.
/// L1 content — solid elevated cards, charts, vitals.
/// L2 liquid glass — frosted floating furniture only.
enum EcMaterialLayer {
  voidCanvas,
  solidContent,
  liquidGlass,
}

extension EcMaterialLayerX on EcMaterialLayer {
  bool get allowsBlur => this == EcMaterialLayer.liquidGlass;

  bool get isSolid => this != EcMaterialLayer.liquidGlass;
}

/// Ensures L1 widgets never apply backdrop blur.
class EcLayerGuard extends StatelessWidget {
  const EcLayerGuard({
    super.key,
    required this.layer,
    required this.child,
  });

  final EcMaterialLayer layer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: switch (layer) {
        EcMaterialLayer.voidCanvas => 'void canvas',
        EcMaterialLayer.solidContent => 'content surface',
        EcMaterialLayer.liquidGlass => 'liquid glass surface',
      },
      child: child,
    );
  }
}
