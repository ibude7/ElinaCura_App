import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/engagement_repository.dart';
import '../../core/data/local_prefs.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_engagement.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  List<ShoppingListItem> _items = [];
  bool _loading = true;
  bool _live = false;
  final _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profileId = activeProfileId(ref);
    setState(() => _loading = true);
    if (profileId != null) {
      try {
        final live = await ref.read(engagementRepositoryProvider).getShoppingList(profileId);
        if (live.isNotEmpty && mounted) {
          setState(() {
            _items = live;
            _live = true;
            _loading = false;
          });
          return;
        }
      } catch (_) {}
    }
    final saved = await LocalPrefs.readList('ec.shopping.items');
    if (!mounted) return;
    setState(() {
      _items = saved.isEmpty
          ? _seedItems()
          : saved
              .map(
                (e) => ShoppingListItem(
                  id: e['id'] as String? ?? '',
                  name: e['name'] as String? ?? '',
                  purchased: e['purchased'] as bool? ?? false,
                  kind: e['kind'] as String?,
                ),
              )
              .toList();
      _live = false;
      _loading = false;
    });
  }

  List<ShoppingListItem> _seedItems() => const [
        ShoppingListItem(id: 's1', name: 'Blood pressure monitor batteries', kind: 'pharmacy'),
        ShoppingListItem(id: 's2', name: 'Low-sodium crackers', kind: 'grocery'),
        ShoppingListItem(id: 's3', name: 'Vitamin D refill', kind: 'pharmacy'),
      ];

  Future<void> _persistLocal() async {
    if (_live) return;
    await LocalPrefs.writeList(
      'ec.shopping.items',
      _items
          .map(
            (i) => {
              'id': i.id,
              'name': i.name,
              'purchased': i.purchased,
              'kind': i.kind,
            },
          )
          .toList(),
    );
  }

  Future<void> _toggle(ShoppingListItem item) async {
    final next = !item.purchased;
    setState(() {
      _items = _items
          .map((i) => i.id == item.id ? i.copyWith(purchased: next) : i)
          .toList();
    });
    if (_live) {
      try {
        await ref.read(engagementRepositoryProvider).setShoppingItemPurchased(item.id, next);
      } catch (_) {}
    } else {
      await _persistLocal();
    }
  }

  Future<void> _add() async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    _addController.clear();
    final profileId = activeProfileId(ref);
    if (_live && profileId != null) {
      try {
        final created =
            await ref.read(engagementRepositoryProvider).addShoppingItem(profileId, name);
        if (created != null && mounted) {
          setState(() => _items = [..._items, created]);
        }
        return;
      } catch (_) {}
    }
    setState(() {
      _items = [
        ..._items,
        ShoppingListItem(id: 'local-${DateTime.now().millisecondsSinceEpoch}', name: name),
      ];
    });
    await _persistLocal();
  }

  Future<void> _remove(ShoppingListItem item) async {
    setState(() => _items = _items.where((i) => i.id != item.id).toList());
    if (_live) {
      try {
        await ref.read(engagementRepositoryProvider).deleteShoppingItem(item.id);
      } catch (_) {}
    } else {
      await _persistLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _items.where((i) => i.purchased).length;
    final remaining = _items.length - done;

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Shopping list'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: kEcGlassListPadding,
              children: [
                EcEngagementHero(
                  title: 'Smart shopping',
                  subtitle: 'Pharmacy refills and staples in one run.',
                  icon: Icons.shopping_cart_rounded,
                  trailing: EcPill(
                    label: '$remaining left',
                    tone: remaining == 0 ? EcPillTone.positive : EcPillTone.info,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addController,
                        decoration: const InputDecoration(
                          hintText: 'Add item',
                          prefixIcon: Icon(Icons.add_rounded),
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: _add, icon: const Icon(Icons.check_rounded)),
                  ],
                ),
                const SizedBox(height: 16),
                if (_items.isEmpty)
                  const EcEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'List is empty',
                    message: 'Add pharmacy refills or grocery staples.',
                  )
                else
                  ..._items.map(
                    (item) => EcGlassListTile(
                      icon: item.purchased
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      title: item.name,
                      subtitle: item.kind,
                      onTap: () => _toggle(item),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => _remove(item),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                EcShareActions(
                  text: _items
                      .where((i) => !i.purchased)
                      .map((i) => '• ${i.name}')
                      .join('\n'),
                ),
              ],
            ),
    );
  }
}
