import 'package:flutter/material.dart';

import 'ec_page_kit.dart';

/// Outcome-flow hero for engagement screens (Rec #19).
class EcOutcomeHero extends StatelessWidget {
  const EcOutcomeHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accent = EcAccent.brand,
    this.stats = const [],
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final EcAccent accent;
  final List<EcHeroStat> stats;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return EcPageHero(
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      icon: icon,
      accent: accent,
      stats: stats,
      trailing: trailing,
      layer: EcSurfaceLayer.solidContent,
    );
  }
}
