import 'foods_page.dart';

enum MealType { breakfast, lunch, snacks, dinner }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch => 'Lunch',
    MealType.snacks => 'Snacks',
    MealType.dinner => 'Dinner',
  };
}

/// Uses the SAME FoodCatalogItem and catalog maintained in foods_page.dart.
/// No duplicate foods, prices, images, or suitableFor field.
class AutoPlan {
  final DateTime date;
  final Map<MealType, FoodCatalogItem> meals;

  AutoPlan({required this.date, required Map<MealType, FoodCatalogItem> meals})
      : meals = Map.unmodifiable(meals);

  int get total => meals.values.fold(0, (sum, food) => sum + food.price);
}

class GenerateResult {
  final Map<MealType, FoodCatalogItem>? meals;
  final String? error;

  const GenerateResult.success(Map<MealType, FoodCatalogItem> value)
      : meals = value, error = null;
  const GenerateResult.failure(String message)
      : meals = null, error = message;

  bool get success => meals != null;
}
