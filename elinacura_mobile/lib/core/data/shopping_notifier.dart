import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import '../network/offline_queue.dart';
import 'engagement_repository.dart';

/// Shopping list state with offline mutation queue (Rec #29).
class ShoppingState {
  const ShoppingState({
    this.items = const [],
    this.loading = false,
    this.live = false,
    this.error,
  });

  final List<ShoppingListItem> items;
  final bool loading;
  final bool live;
  final String? error;

  ShoppingState copyWith({
    List<ShoppingListItem>? items,
    bool? loading,
    bool? live,
    String? error,
    bool clearError = false,
  }) {
    return ShoppingState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      live: live ?? this.live,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ShoppingNotifier extends StateNotifier<ShoppingState> {
  ShoppingNotifier(this._repo, this._ref) : super(const ShoppingState());

  final EngagementRepository _repo;
  final Ref _ref;

  Future<void> load(String profileId) async {
    state = state.copyWith(loading: true, clearError: true);
    final result = await _repo.getShoppingListResult(profileId);
    result.when(
      success: (items) => state = state.copyWith(
        items: items,
        live: items.isNotEmpty,
        loading: false,
      ),
      failure: (msg, _) => state = state.copyWith(
        loading: false,
        error: msg,
        live: false,
      ),
    );
  }

  Future<void> togglePurchased(String profileId, ShoppingListItem item) async {
    final next = !item.purchased;
    state = state.copyWith(
      items: state.items
          .map((i) => i.id == item.id ? i.copyWith(purchased: next) : i)
          .toList(),
    );
    try {
      await _repo.setShoppingItemPurchased(item.id, next);
    } catch (_) {
      await _ref.read(offlineQueueProvider.notifier).enqueue(
            method: 'PATCH',
            path: '/shopping-list/items/${item.id}',
            body: {'purchased': next},
          );
    }
  }

  Future<void> addItem(String profileId, String name) async {
    try {
      final created = await _repo.addShoppingItem(profileId, name);
      if (created != null) {
        state = state.copyWith(
          items: [...state.items, created],
          live: true,
        );
      }
    } catch (_) {
      final local = ShoppingListItem(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
      );
      state = state.copyWith(items: [...state.items, local]);
      await _ref.read(offlineQueueProvider.notifier).enqueue(
            method: 'POST',
            path: '/shopping-list/$profileId/items',
            body: {'name': name},
          );
    }
  }

  Future<void> removeItem(ShoppingListItem item) async {
    state = state.copyWith(
      items: state.items.where((i) => i.id != item.id).toList(),
    );
    try {
      await _repo.deleteShoppingItem(item.id);
    } catch (_) {
      await _ref.read(offlineQueueProvider.notifier).enqueue(
            method: 'DELETE',
            path: '/shopping-list/items/${item.id}',
          );
    }
  }
}

final shoppingNotifierProvider =
    StateNotifierProvider.family<ShoppingNotifier, ShoppingState, String>(
  (ref, profileId) {
    final notifier = ShoppingNotifier(
      ref.watch(engagementRepositoryProvider),
      ref,
    );
    notifier.load(profileId);
    return notifier;
  },
);
