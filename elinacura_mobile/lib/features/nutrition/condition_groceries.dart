// Condition-aware grocery engine: maps a user's conditions to a de-duplicated
// shopping list of foods, each tagged with a store aisle and the reason it was
// suggested. This is the "wow moment" connecting conditions to nutrition.

class GroceryFood {
  const GroceryFood({required this.name, required this.aisle, required this.reason});

  final String name;
  final String aisle;

  /// Why it's on the list — e.g. 'Staple' or 'Diabetes-friendly'.
  final String reason;

  String get id => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

const _staples = <GroceryFood>[
  GroceryFood(name: 'Leafy greens', aisle: 'Produce', reason: 'Staple'),
  GroceryFood(name: 'Mixed berries', aisle: 'Produce', reason: 'Staple'),
  GroceryFood(name: 'Whole grain bread', aisle: 'Bakery', reason: 'Staple'),
  GroceryFood(name: 'Greek yogurt', aisle: 'Dairy', reason: 'Staple'),
  GroceryFood(name: 'Extra-virgin olive oil', aisle: 'Pantry', reason: 'Staple'),
];

/// keyword -> (display label, foods)
const _conditionFoods = <String, (String, List<GroceryFood>)>{
  'diabet': (
    'Diabetes-friendly',
    [
      GroceryFood(name: 'Steel-cut oats', aisle: 'Pantry', reason: 'Diabetes-friendly'),
      GroceryFood(name: 'Cinnamon', aisle: 'Pantry', reason: 'Diabetes-friendly'),
      GroceryFood(name: 'Almonds', aisle: 'Pantry', reason: 'Diabetes-friendly'),
      GroceryFood(name: 'Lentils', aisle: 'Pantry', reason: 'Diabetes-friendly'),
      GroceryFood(name: 'Broccoli', aisle: 'Produce', reason: 'Diabetes-friendly'),
    ],
  ),
  'hypertens': (
    'Heart / BP support',
    [
      GroceryFood(name: 'Salmon fillet', aisle: 'Seafood', reason: 'Heart / BP support'),
      GroceryFood(name: 'Bananas', aisle: 'Produce', reason: 'Heart / BP support'),
      GroceryFood(name: 'Spinach', aisle: 'Produce', reason: 'Heart / BP support'),
      GroceryFood(name: 'Low-sodium broth', aisle: 'Pantry', reason: 'Heart / BP support'),
    ],
  ),
  'heart': (
    'Heart support',
    [
      GroceryFood(name: 'Walnuts', aisle: 'Pantry', reason: 'Heart support'),
      GroceryFood(name: 'Avocado', aisle: 'Produce', reason: 'Heart support'),
      GroceryFood(name: 'Salmon fillet', aisle: 'Seafood', reason: 'Heart support'),
    ],
  ),
  'cholesterol': (
    'Cholesterol-lowering',
    [
      GroceryFood(name: 'Oats', aisle: 'Pantry', reason: 'Cholesterol-lowering'),
      GroceryFood(name: 'Black beans', aisle: 'Pantry', reason: 'Cholesterol-lowering'),
    ],
  ),
  'kidney': (
    'Kidney-friendly',
    [
      GroceryFood(name: 'Cauliflower', aisle: 'Produce', reason: 'Kidney-friendly'),
      GroceryFood(name: 'Egg whites', aisle: 'Dairy', reason: 'Kidney-friendly'),
    ],
  ),
  'anemia': (
    'Iron-rich',
    [
      GroceryFood(name: 'Lean red meat', aisle: 'Meat', reason: 'Iron-rich'),
      GroceryFood(name: 'Spinach', aisle: 'Produce', reason: 'Iron-rich'),
    ],
  ),
  'osteo': (
    'Bone health',
    [
      GroceryFood(name: 'Milk', aisle: 'Dairy', reason: 'Bone health'),
      GroceryFood(name: 'Sardines', aisle: 'Seafood', reason: 'Bone health'),
      GroceryFood(name: 'Tofu', aisle: 'Refrigerated', reason: 'Bone health'),
    ],
  ),
  'celiac': (
    'Gluten-free',
    [
      GroceryFood(name: 'Quinoa', aisle: 'Pantry', reason: 'Gluten-free'),
      GroceryFood(name: 'Brown rice', aisle: 'Pantry', reason: 'Gluten-free'),
    ],
  ),
};

/// Builds a de-duplicated, condition-aware grocery list (staples first, then
/// condition-specific foods). De-dupes by food name (case-insensitive).
List<GroceryFood> smartGroceryList(List<String> conditions) {
  final out = <String, GroceryFood>{};
  for (final f in _staples) {
    out[f.name.toLowerCase()] = f;
  }
  for (final raw in conditions) {
    final c = raw.toLowerCase();
    for (final entry in _conditionFoods.entries) {
      if (c.contains(entry.key)) {
        for (final f in entry.value.$2) {
          out.putIfAbsent(f.name.toLowerCase(), () => f);
        }
      }
    }
  }
  return out.values.toList();
}

/// Display labels of the conditions that drove the list (for a banner).
List<String> matchedConditionLabels(List<String> conditions) {
  final labels = <String>{};
  for (final raw in conditions) {
    final c = raw.toLowerCase();
    for (final entry in _conditionFoods.entries) {
      if (c.contains(entry.key)) labels.add(entry.value.$1);
    }
  }
  return labels.toList();
}
