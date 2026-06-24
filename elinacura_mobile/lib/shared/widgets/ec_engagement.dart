import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';
import 'ec_widgets.dart';

/// Hero card used across migrated PWA engagement screens.
class EcEngagementHero extends StatelessWidget {
  const EcEngagementHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final color = accent ?? ec.accentBrand;

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    fontFamily: EcTokens.fontFamily,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: ec.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class EcChecklistTile extends StatelessWidget {
  const EcChecklistTile({
    super.key,
    required this.title,
    required this.done,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool done;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);

    return EcGlassSurface(
      onTap: () => onChanged(!done),
      variant: EcGlassVariant.regular,
      borderRadius: EcTokens.radiusCard,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: done ? ec.accentMintText : ec.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? ec.textMuted : null,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: ec.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EcShareActions extends StatelessWidget {
  const EcShareActions({
    super.key,
    required this.text,
    this.onCopied,
  });

  final String text;
  final VoidCallback? onCopied;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              onCopied?.call();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy'),
          ),
        ),
      ],
    );
  }
}

class EcStatChip extends StatelessWidget {
  const EcStatChip({
    super.key,
    required this.label,
    required this.value,
    this.tone = EcPillTone.neutral,
  });

  final String label;
  final String value;
  final EcPillTone tone;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Expanded(
      child: EcGlassSurface(
        variant: EcGlassVariant.regular,
        borderRadius: EcTokens.radiusCard,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: ec.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
