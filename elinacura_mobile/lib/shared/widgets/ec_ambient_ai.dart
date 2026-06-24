import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/ec_copy.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';
import 'ec_page_kit.dart';

/// Proactive Care AI glass card on Today (Rec #41).
class EcAmbientAiCard extends StatelessWidget {
  const EcAmbientAiCard({
    super.key,
    required this.message,
    this.actionLabel = 'Discuss',
    this.route = '/chat',
  });

  final String message;
  final String actionLabel;
  final String route;

  factory EcAmbientAiCard.refill() => const EcAmbientAiCard(
        message: EcCopy.ambientAiRefill,
        actionLabel: 'Add to list',
        route: '/shopping-list',
      );

  factory EcAmbientAiCard.bpTrend() => const EcAmbientAiCard(
        message: EcCopy.ambientAiBp,
      );

  @override
  Widget build(BuildContext context) {
    return EcPageHero(
      eyebrow: 'Care AI',
      title: 'Insight for you',
      subtitle: message,
      icon: Icons.auto_awesome_rounded,
      accent: EcAccent.lavender,
      layer: EcSurfaceLayer.liquidGlass,
      trailing: TextButton(
        onPressed: () => context.push(route),
        child: Text(actionLabel),
      ),
    );
  }
}

/// Pinned glass chip on Today → opens chat with context (Rec #17).
class EcAskElinaChip extends StatelessWidget {
  const EcAskElinaChip({super.key, this.contextHint});

  final String? contextHint;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return EcGlassSurface(
      variant: EcGlassVariant.float,
      borderRadius: EcTokens.radiusFull,
      onTap: () => context.push('/chat', extra: contextHint),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: ec.accentBrand),
          const SizedBox(width: 8),
          const Text(
            'Ask Elina',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
