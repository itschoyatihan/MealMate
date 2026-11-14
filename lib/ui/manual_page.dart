import 'package:flutter/material.dart';

import 'auto_models.dart';
import 'foods_page.dart';
import 'manual_models.dart';
import 'manual_browse.dart';
import 'manual_detail.dart';

/// Standalone manual editor. Caller supplies the saved daily budget and
/// handles persistence via onSave. Draft changes never update saved data.
class ManualPage extends StatefulWidget {
  const ManualPage({
    super.key,
    required this.dailyBudget,
    this.foods = sampleFoodCatalog,
    this.initialPlan,
    this.onSave,
  });
  final int dailyBudget;
  final List<FoodCatalogItem> foods;
  final ManualPlan? initialPlan;
  final Future<void> Function(ManualPlan plan)? onSave;
  @override
  State<ManualPage> createState() => _ManualPageState();
}

class _ManualPageState extends State<ManualPage> {
  static const dark = Color(0xFF123D22),
      green = Color(0xFF248719),
      orange = Color(0xFFFF8300),
      cream = Color(0xFFFFFAF2);
  late final Map<MealType, List<ManualItem>> draft;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    draft = {
      for (final type in MealType.values)
        type: List.of(widget.initialPlan?.meals[type] ?? const <ManualItem>[]),
    };
  }

  int mealTotal(MealType type) =>
      draft[type]!.fold<int>(0, (sum, e) => sum + e.total);
  int get total =>
      MealType.values.fold<int>(0, (sum, type) => sum + mealTotal(type));
  String money(int amount) => amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  void add(MealType type, FoodCatalogItem food) => setState(() {
    final items = draft[type]!;
    final index = items.indexWhere((e) => e.food.id == food.id);
    if (index < 0) {
      items.add(ManualItem(food: food, quantity: 1));
    } else {
      items[index] = items[index].withQuantity(items[index].quantity + 1);
    }
  });
  Future<void> browse(MealType type) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManualBrowsePage(
          mealName: type.label,
          foods: widget.foods,
          onAdd: (food) => add(type, food),
        ),
      ),
    );
    if (!mounted) return;
    if (draft[type]!.isNotEmpty) await detail(type);
  }

  Future<void> detail(MealType type) async {
    final result = await Navigator.of(context).push<List<ManualItem>>(
      MaterialPageRoute(
        builder: (_) => ManualDetailPage(
          type: type,
          foods: widget.foods,
          initialItems: draft[type]!,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => draft[type] = result);
  }

  Future<void> clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Meal Plan?'),
        content: const Text(
          'This will remove all selected foods from Breakfast, Lunch, Snacks, and Dinner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Plan'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      for (final type in MealType.values) {
        draft[type]!.clear();
      }
    });
  }

  Future<void> save() async {
    if (saving) return;
    if (total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one food first.')),
      );
      return;
    }
    if (total > widget.dailyBudget) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Over Budget'),
          content: Text(
            'Your plan is ${money(total - widget.dailyBudget)} Ks over the daily budget. Save anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    if (widget.onSave == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Save is not connected yet. Your draft remains on this page.',
          ),
        ),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await widget.onSave!(
        ManualPlan(
          date: widget.initialPlan?.date ?? DateTime.now(),
          meals: draft,
        ),
      );
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the meal plan. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // Match the Automatic Meal Plan's compact three-column summary.
  Widget summary() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE3E7DD)),
    ),
    child: Row(
      children: [
        _stat("Today's\nBudget", widget.dailyBudget),
        const SizedBox(height: 55, child: VerticalDivider()),
        _stat('Plan\nTotal', total),
        const SizedBox(height: 55, child: VerticalDivider()),
        _stat('Remaining\nBudget', widget.dailyBudget - total),
      ],
    ),
  );

  Widget _stat(String label, int value) => Expanded(
    child: Column(
      children: [
        Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('${money(value)} Ks',
            style: TextStyle(
              color: value < 0 ? Colors.red : const Color(0xFF083F25),
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
      ],
    ),
  );

  Widget mealRow(MealType type) {
    final count = draft[type]!.length;
    final icon = switch (type) {
      MealType.breakfast => Icons.egg_alt_outlined,
      MealType.lunch => Icons.rice_bowl,
      MealType.snacks => Icons.local_cafe_outlined,
      MealType.dinner => Icons.dinner_dining,
    };
    return Card(
      color: count > 0 ? const Color(0xFFEAF6DF) : Colors.white,
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE1EBD8)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: saving ? null : () => count == 0 ? browse(type) : detail(type),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: orange, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: dark,
                      ),
                    ),
                    Text(
                      count == 0 ? 'Not planned' : '$count items',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0) ...[
                Flexible(
                  child: Text(
                    '${money(mealTotal(type))} Ks',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: dark),
              ] else
                OutlinedButton.icon(
                  onPressed: saving ? null : () => browse(type),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dark,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cream,
    appBar: AppBar(
      backgroundColor: cream,
      title: const Text(
        'Manual Meal Plan',
        style: TextStyle(color: dark, fontWeight: FontWeight.bold),
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summary(),
            if (total > widget.dailyBudget)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Over budget by ${money(total - widget.dailyBudget)} Ks. You can still save.',
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            const Text(
              'Plan Your Meals',
              style: TextStyle(
                fontSize: 21,
                color: dark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text('Choose and add foods for each meal.'),
            const SizedBox(height: 14),
            for (final type in MealType.values) mealRow(type),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: saving ? null : clear,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear Plan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dark,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Save Meal Plan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
