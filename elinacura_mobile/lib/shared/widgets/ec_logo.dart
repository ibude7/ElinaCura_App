import 'package:flutter/material.dart';

/// ElinaCura brand mark — green leaf emblem with terracotta accent.
class EcLogo extends StatelessWidget {
  const EcLogo({
    super.key,
    this.size = 120,
    this.semanticLabel = 'ElinaCura',
  });

  final double size;
  final String semanticLabel;

  static const asset = 'assets/images/logo_mark.png';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
