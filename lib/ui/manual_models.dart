import 'foods_page.dart';
import 'auto_models.dart';

class ManualItem {
  final FoodCatalogItem food;
  final int quantity;
  const ManualItem({required this.food, required this.quantity})
      : assert(quantity > 0);
  int get total => food.price * quantity;
  ManualItem withQuantity(int value) => ManualItem(food: food, quantity: value);
}

class ManualPlan {
  final DateTime date;
  final Map<MealType, List<ManualItem>> meals;
  ManualPlan({required this.date, required Map<MealType, List<ManualItem>> meals})
      : meals = Map.unmodifiable({
          for (final type in MealType.values)
            type: List<ManualItem>.unmodifiable(meals[type] ?? const []),
        });
  int get total => meals.values.expand((items) => items)
      .fold<int>(0, (sum, item) => sum + item.total);
}
