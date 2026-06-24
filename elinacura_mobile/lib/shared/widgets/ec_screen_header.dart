import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/ec_a11y.dart';
import '../../core/theme/ec_perf.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';

/// Unified screen header for tab, push, and modal routes.
class EcScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const EcScreenHeader({
    super.key,
    this.title,
    this.eyebrow,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.variant = EcHeaderVariant.push,
    this.showBack = true,
  });

  final String? title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final EcHeaderVariant variant;
  final bool showBack;

  @override
  Size get preferredSize => Size.fromHeight(
        variant == EcHeaderVariant.tab ? 88 : 56,
      );

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reducedGlass = EcA11y.prefersReducedTransparency(context);
    final top = MediaQuery.paddingOf(context).top;
    final canPop = context.canPop();

    final content = Padding(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 12),
      child: Row(
        children: [
          if (variant == EcHeaderVariant.push && showBack && canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            )
          else ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: ec.textMuted,
                    ),
                  ),
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: variant == EcHeaderVariant.tab ? 28 : 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: variant == EcHeaderVariant.tab ? -0.8 : -0.3,
                      color: isDark ? Colors.white : EcTokens.textPrimaryLight,
                    ),
                  ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 13, color: ec.textSecondary),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );

    if (!EcPerf.useLiquidBlur(context) || reducedGlass) {
      return Material(
        color: isDark
            ? EcTokens.bgVoid.withValues(alpha: 0.92)
            : EcTokens.bgVoidLight.withValues(alpha: 0.96),
        child: content,
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: EcPerf.blurSigma(context, EcTokens.glassBlurZ3),
          sigmaY: EcPerf.blurSigma(context, EcTokens.glassBlurZ3),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EcGlass.of(context).fillFloat,
            border: Border(bottom: BorderSide(color: EcGlass.of(context).border)),
          ),
          child: content,
        ),
      ),
    );
  }
}

enum EcHeaderVariant { tab, push, modal }
