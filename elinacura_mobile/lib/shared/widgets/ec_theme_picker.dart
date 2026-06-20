import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../core/theme/theme_provider.dart';
import 'ec_glass.dart';

/// System / Light / Dark appearance picker.
class EcThemePicker extends ConsumerWidget {
  const EcThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themePreferenceProvider);
    final ec = EcColors.of(context);

    return Row(
      children: EcThemePreference.values.map((option) {
        final isSelected = selected == option;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option != EcThemePreference.dark ? 8 : 0,
            ),
            child: EcGlassSurface(
              onTap: () => ref.read(themePreferenceProvider.notifier).set(option),
              variant: isSelected ? EcGlassVariant.tinted : EcGlassVariant.subtle,
              tint: isSelected ? ec.accentBrand : null,
              borderRadius: EcTokens.radiusLg,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 22,
                    color: isSelected ? ec.accentBrand : ec.textMuted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? ec.accentBrand : ec.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
