import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/engagement_repository.dart';
import '../../core/data/local_prefs.dart';
import '../../core/data/shopping_notifier.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_engagement.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_outcome_hero.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_widgets.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _addController = TextEditingController();
  List<ShoppingListItem> _localItems = [];
  bool _localLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocal();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _loadLocal() async {
    final saved = await LocalPrefs.readList('ec.shopping.items');
    if (!mounted) return;
    setState(() {
      _localItems = saved.isEmpty
          ? const [
              ShoppingListItem(
                id: 's1',
                name: 'Blood pressure monitor batteries',
                kind: 'pharmacy',
              ),
              ShoppingListItem(
                id: 's2',
                name: 'Low-sodium crackers',
                kind: 'grocery',
              ),
              ShoppingListItem(
                id: 's3',
                name: 'Vitamin D refill',
                kind: 'pharmacy',
              ),
            ]
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
      _localLoading = false;
    });
  }

  Future<void> _persistLocal(List<ShoppingListItem> items) async {
    await LocalPrefs.writeList(
      'ec.shopping.items',
      items
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

  @override
  Widget build(BuildContext context) {
    final profileId = activeProfileId(ref);
    final remote = profileId != null
        ? ref.watch(shoppingNotifierProvider(profileId))
        : null;
    final loading = profileId != null ? (remote?.loading ?? true) : _localLoading;
    final items = profileId != null ? (remote?.items ?? []) : _localItems;
    final notifier = profileId != null
        ? ref.read(shoppingNotifierProvider(profileId).notifier)
        : null;

    final done = items.where((i) => i.purchased).length;
    final remaining = items.length - done;

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Shopping list'),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: kEcGlassListPadding,
              children: [
                EcOutcomeHero(
                  eyebrow: 'Outcome',
                  title: 'Smart shopping',
                  subtitle: 'Pharmacy refills and staples in one run.',
                  icon: Icons.shopping_cart_rounded,
                  accent: EcAccent.mint,
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
                        onSubmitted: (_) => _add(profileId, notifier),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _add(profileId, notifier),
                      icon: const Icon(Icons.check_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const EcEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'List is empty',
                    message: 'Add pharmacy refills or grocery staples.',
                  )
                else
                  ...items.map(
                    (item) => EcGlassListTile(
                      icon: item.purchased
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      title: item.name,
                      subtitle: item.kind,
                      onTap: () => _toggle(profileId, notifier, item),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => _remove(profileId, notifier, item),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                EcShareActions(
                  text: items
                      .where((i) => !i.purchased)
                      .map((i) => '• ${i.name}')
                      .join('\n'),
                ),
              ],
            ),
    );
  }

  Future<void> _add(String? profileId, ShoppingNotifier? notifier) async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    _addController.clear();
    if (notifier != null && profileId != null) {
      await notifier.addItem(profileId, name);
    } else {
      setState(() {
        _localItems = [
          ..._localItems,
          ShoppingListItem(
            id: 'local-${DateTime.now().millisecondsSinceEpoch}',
            name: name,
          ),
        ];
      });
      await _persistLocal(_localItems);
    }
  }

  Future<void> _toggle(
    String? profileId,
    ShoppingNotifier? notifier,
    ShoppingListItem item,
  ) async {
    if (notifier != null && profileId != null) {
      await notifier.togglePurchased(profileId, item);
    } else {
      setState(() {
        _localItems = _localItems
            .map((i) => i.id == item.id ? i.copyWith(purchased: !i.purchased) : i)
            .toList();
      });
      await _persistLocal(_localItems);
    }
  }

  Future<void> _remove(
    String? profileId,
    ShoppingNotifier? notifier,
    ShoppingListItem item,
  ) async {
    if (notifier != null) {
      await notifier.removeItem(item);
    } else {
      setState(() => _localItems = _localItems.where((i) => i.id != item.id).toList());
      await _persistLocal(_localItems);
    }
  }
}
