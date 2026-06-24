import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_provider.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import 'ec_glass.dart';

/// A floating glass pill that appears at the top of the app only while the
/// device is offline. Renders nothing when online.
class EcOfflineBanner extends ConsumerWidget {
  const EcOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider).valueOrNull ?? true;
    if (online) return const SizedBox.shrink();
    final ec = EcColors.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          child: EcGlassSurface(
            variant: EcGlassVariant.float,
            borderRadius: EcTokens.radiusFull,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 16, color: ec.textSecondary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Offline — showing your latest saved data',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: ec.textSecondary,
                    ),
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
