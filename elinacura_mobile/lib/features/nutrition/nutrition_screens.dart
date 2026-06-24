import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/data/local_prefs.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/widgets/ec_engagement.dart';
import '../../shared/widgets/ec_outcome_hero.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

class _GroceryItem {
  const _GroceryItem({required this.id, required this.name, required this.aisle});

  final String id;
  final String name;
  final String aisle;
}

const _defaultGrocery = [
  _GroceryItem(id: 'g1', name: 'Leafy greens', aisle: 'Produce'),
  _GroceryItem(id: 'g2', name: 'Berries', aisle: 'Produce'),
  _GroceryItem(id: 'g3', name: 'Whole grain bread', aisle: 'Bakery'),
  _GroceryItem(id: 'g4', name: 'Low-sodium broth', aisle: 'Pantry'),
  _GroceryItem(id: 'g5', name: 'Greek yogurt', aisle: 'Dairy'),
  _GroceryItem(id: 'g6', name: 'Salmon fillet', aisle: 'Seafood'),
];

class GroceryScreen extends ConsumerStatefulWidget {
  const GroceryScreen({super.key});

  @override
  ConsumerState<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends ConsumerState<GroceryScreen> {
  Map<String, bool> _checked = {};
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
    final saved = await LocalPrefs.readBoolMap('ec.grocery.checked');
    if (mounted) setState(() => _checked = saved);
  }

  Future<void> _toggle(String id) async {
    setState(() {
      final next = {..._checked};
      if (next[id] == true) {
        next.remove(id);
      } else {
        next[id] = true;
      }
      _checked = next;
    });
    await LocalPrefs.writeBoolMap('ec.grocery.checked', _checked);
  }

  List<_GroceryItem> _itemsForProfile() {
    final profile = ref.read(healthOverviewProvider).valueOrNull?.profile;
    if (profile == null) return _defaultGrocery;
    final items = [..._defaultGrocery];
    if (profile.conditions.any((c) => c.toLowerCase().contains('diabet'))) {
      items.add(const _GroceryItem(id: 'g7', name: 'Cinnamon oats', aisle: 'Pantry'));
    }
    if (profile.conditions.any((c) => c.toLowerCase().contains('heart'))) {
      items.add(const _GroceryItem(id: 'g8', name: 'Walnuts', aisle: 'Pantry'));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsForProfile();
    final done = items.where((i) => _checked[i.id] == true).length;
    final ec = EcColors.of(context);

    final byAisle = <String, List<_GroceryItem>>{};
    for (final item in items) {
      byAisle.putIfAbsent(item.aisle, () => []).add(item);
    }

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Grocery list'),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          EcOutcomeHero(
            eyebrow: 'Nutrition',
            title: 'Condition-aware groceries',
            subtitle: 'Grouped by aisle with foods aligned to your care profile.',
            icon: Icons.shopping_basket_rounded,
            accent: EcAccent.mint,
            trailing: EcPill(
              label: '$done/${items.length}',
              tone: done == items.length ? EcPillTone.positive : EcPillTone.info,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addController,
                  decoration: const InputDecoration(
                    hintText: 'Add custom item',
                    prefixIcon: Icon(Icons.add_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  if (_addController.text.trim().isEmpty) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added "${_addController.text.trim()}"')),
                  );
                  _addController.clear();
                },
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...byAisle.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: ec.textMuted,
                    ),
                  ),
                ),
                ...entry.value.map(
                  (item) => EcChecklistTile(
                    title: item.name,
                    done: _checked[item.id] == true,
                    onChanged: (_) => _toggle(item.id),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
          EcShareActions(
            text: items
                .where((i) => _checked[i.id] != true)
                .map((i) => '• ${i.name} (${i.aisle})')
                .join('\n'),
          ),
        ],
      ),
    );
  }
}

class _MealSlot {
  const _MealSlot(this.key, this.label, this.time);

  final String key;
  final String label;
  final String time;
}

const _mealSlots = [
  _MealSlot('breakfast', 'Breakfast', '08:00'),
  _MealSlot('lunch', 'Lunch', '12:30'),
  _MealSlot('dinner', 'Dinner', '18:30'),
  _MealSlot('snack', 'Snack', '15:00'),
];

const _mealCards = [
  ('Mediterranean bowl', '420 kcal · high fiber'),
  ('Grilled salmon plate', '510 kcal · omega-3'),
  ('Vegetable lentil soup', '320 kcal · low sodium'),
  ('Berry yogurt parfait', '280 kcal · protein'),
];

class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key});

  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
  final Map<String, String> _plan = {
    'breakfast': 'Berry yogurt parfait',
    'lunch': 'Mediterranean bowl',
    'dinner': 'Grilled salmon plate',
    'snack': 'Vegetable lentil soup',
  };
  final Map<String, bool> _logged = {};

  @override
  Widget build(BuildContext context) {
    final loggedCount = _logged.values.where((v) => v).length;
    final plannedKcal = 1530;

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Meals'),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          EcOutcomeHero(
            eyebrow: 'Daily plan',
            title: 'Today\'s meal plan',
            subtitle: 'Nutrition guidance tuned to your conditions and medications.',
            icon: Icons.restaurant_rounded,
            accent: EcAccent.mint,
            trailing: EcPill(label: '$plannedKcal kcal', tone: EcPillTone.info),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              EcStatChip(label: 'Logged', value: '$loggedCount/4', tone: EcPillTone.positive),
              const SizedBox(width: 8),
              EcStatChip(label: 'Targets', value: 'Balanced', tone: EcPillTone.neutral),
            ],
          ),
          const SizedBox(height: 20),
          EcSectionTitle(title: 'Today'),
          const SizedBox(height: 8),
          ..._mealSlots.map((slot) {
            final dish = _plan[slot.key] ?? 'Choose a meal';
            final logged = _logged[slot.key] == true;
            return EcGlassEntrance(
              index: 1,
              child: EcGlassListTile(
                icon: Icons.schedule_rounded,
                title: '${slot.label} · ${slot.time}',
                subtitle: dish,
                trailing: IconButton(
                  icon: Icon(
                    logged ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: logged ? EcColors.of(context).accentMintText : null,
                  ),
                  onPressed: () => setState(() => _logged[slot.key] = !logged),
                ),
                onTap: () => _pickMeal(slot.key),
              ),
            );
          }),
          const SizedBox(height: 20),
          EcSectionTitle(title: 'Recommended'),
          const SizedBox(height: 8),
          ..._mealCards.map(
            (card) => EcGlassListTile(
              icon: Icons.local_dining_rounded,
              title: card.$1,
              subtitle: card.$2,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMeal(String slotKey) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _mealCards
              .map(
                (c) => ListTile(
                  title: Text(c.$1),
                  subtitle: Text(c.$2),
                  onTap: () => Navigator.pop(context, c.$1),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked != null) setState(() => _plan[slotKey] = picked);
  }
}
