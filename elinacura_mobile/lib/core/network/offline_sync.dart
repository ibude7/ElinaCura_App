import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../connectivity/connectivity_provider.dart';
import '../network/offline_queue.dart';

/// Flushes queued mutations when connectivity returns.
class OfflineSyncListener extends ConsumerStatefulWidget {
  const OfflineSyncListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OfflineSyncListener> createState() =>
      _OfflineSyncListenerState();
}

class _OfflineSyncListenerState extends ConsumerState<OfflineSyncListener> {
  bool _flushing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityProvider, (prev, next) {
      final online = next.valueOrNull ?? true;
      if (online) _flush();
    });

    ref.listen(offlineQueueProvider, (prev, next) {
      final online = ref.read(connectivityProvider).valueOrNull ?? true;
      if (online && (next.valueOrNull?.isNotEmpty ?? false)) {
        _flush();
      }
    });

    return widget.child;
  }

  Future<void> _flush() async {
    if (_flushing) return;
    final queue = ref.read(offlineQueueProvider).valueOrNull ?? [];
    if (queue.isEmpty) return;

    _flushing = true;
    final api = ref.read(apiClientProvider);
    final notifier = ref.read(offlineQueueProvider.notifier);

    for (final item in List<QueuedMutation>.from(queue)) {
      try {
        switch (item.method.toUpperCase()) {
          case 'POST':
            await api.post<dynamic>(item.path, data: item.body);
          case 'PUT':
            await api.put<dynamic>(item.path, data: item.body);
          case 'PATCH':
            await api.patch<dynamic>(item.path, data: item.body);
          case 'DELETE':
            await api.delete<dynamic>(item.path);
        }
        await notifier.remove(item.id);
      } catch (_) {
        break;
      }
    }
    _flushing = false;
  }
}
