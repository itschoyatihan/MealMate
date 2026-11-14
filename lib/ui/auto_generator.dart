import 'dart:math';
import 'foods_page.dart';
import 'auto_models.dart';

/// Category names must match those in foods_page.dart.
/// One catalog category can be eligible for several meal types.
class AutoGenerator {
  final Random _random;
  AutoGenerator({Random? random}) : _random = random ?? Random();

  static const Map<MealType, Set<String>> categories = {
    MealType.breakfast: {'Rice Dishes', 'Noodles', 'Soups', 'Others'},
    MealType.lunch: {'Rice Dishes', 'Noodles', 'Soups', 'Salads', 'Others'},
    MealType.snacks: {'Salads', 'Others'},
    MealType.dinner: {'Rice Dishes', 'Noodles', 'Soups', 'Others'},
  };

  List<FoodCatalogItem> eligible(
      List<FoodCatalogItem> catalog, MealType type) {
    return catalog.where((food) =>
        food.price > 0 &&
        categories[type]!.contains(food.category.trim())).toList();
  }

  GenerateResult generate({
    required List<FoodCatalogItem> catalog,
    required Set<MealType> selected,
    required int budget,
    Map<MealType, FoodCatalogItem> previous = const {},
  }) {
    if (selected.isEmpty) {
      return const GenerateResult.failure('Select at least one meal type.');
    }
    if (budget <= 0) {
      return const GenerateResult.failure('Set a valid daily budget first.');
    }

    final types = MealType.values.where(selected.contains).toList();
    final options = <MealType, List<FoodCatalogItem>>{};
    var minimum = 0;
    for (final type in types) {
      final candidates = eligible(catalog, type)..shuffle(_random);
      if (candidates.isEmpty) {
        return GenerateResult.failure(
          'Cannot Generate Plan. No catalog food is available for ${type.label}.',
        );
      }
      candidates.sort((a, b) =>
          (a.id == previous[type]?.id ? 1 : 0)
              .compareTo(b.id == previous[type]?.id ? 1 : 0));
      options[type] = candidates;
      minimum += candidates.map((f) => f.price).reduce(min);
    }
    if (minimum > budget) {
      return const GenerateResult.failure(
        'Cannot Generate Plan. Increase the budget or select fewer meal types.',
      );
    }

    // The minimum-cost combination guarantees a valid result when
    // minimum <= budget. Randomized candidates vary the recommendations.
    final selectedMeals = <MealType, FoodCatalogItem>{};
    bool search(int index, int left) {
      if (index == types.length) return true;
      final type = types[index];
      final remainingMinimum = types.skip(index + 1)
          .fold<int>(0, (sum, next) =>
              sum + options[next]!.map((f) => f.price).reduce(min));
      for (final food in options[type]!) {
        if (food.price + remainingMinimum > left) continue;
        selectedMeals[type] = food;
        if (search(index + 1, left - food.price)) return true;
      }
      selectedMeals.remove(type);
      return false;
    }

    if (!search(0, budget)) {
      return const GenerateResult.failure('Cannot Generate Plan.');
    }
    return GenerateResult.success(Map.of(selectedMeals));
  }

  GenerateResult regenerateOne({
    required MealType type,
    required List<FoodCatalogItem> catalog,
    required Map<MealType, FoodCatalogItem> current,
    required int budget,
  }) {
    final unchanged = Map<MealType, FoodCatalogItem>.of(current)..remove(type);
    final used = unchanged.values.fold<int>(0, (sum, f) => sum + f.price);
    final previousId = current[type]?.id;
    final candidates = eligible(catalog, type)
        .where((f) => f.price <= budget - used && f.id != previousId)
        .toList()..shuffle(_random);
    if (candidates.isEmpty) {
      return const GenerateResult.failure(
        'Cannot Regenerate Meal. No alternative fits the remaining budget.',
      );
    }
    return GenerateResult.success({...unchanged, type: candidates.first});
  }
}
