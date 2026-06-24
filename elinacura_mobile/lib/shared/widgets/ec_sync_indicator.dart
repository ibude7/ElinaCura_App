import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/offline_queue.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';

/// Sync queue indicator beyond offline banner (Rec #29).
class EcSyncIndicator extends ConsumerWidget {
  const EcSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(offlineQueueProvider).valueOrNull ?? [];
    if (pending.isEmpty) return const SizedBox.shrink();
    final ec = EcColors.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: EcGlassSurface(
            variant: EcGlassVariant.float,
            borderRadius: EcTokens.radiusFull,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ec.accentBrand,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Syncing ${pending.length} change${pending.length == 1 ? '' : 's'}…',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ec.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
