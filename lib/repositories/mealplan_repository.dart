import '../services/api_client.dart';
import '../ui/auto_models.dart';
import '../ui/manual_models.dart';
import '../ui/foods_page.dart';

/// Authenticated meal-plan persistence.
/// Guest plans must continue using the existing local flow.
class MealPlanRepository {
  MealPlanRepository(this._api);

  final ApiClient _api;

  static String _date(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static Map<String, dynamic> _data(Map<String, dynamic> response) {
    if (response['success'] != true || response['data'] is! Map) {
      throw const FormatException('Invalid meal plan API response.');
    }
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  /// POST /plans: the server checks the budget and replaces today's old plan.
  Future<Map<String, dynamic>> save(Object plan) async {
    late final DateTime date;
    late final String method;
    late final List<Map<String, dynamic>> items;

    if (plan is AutoPlan) {
      date = plan.date;
      method = 'auto';
      items = [
        for (final entry in plan.meals.entries)
          {'foodId': entry.value.id, 'quantity': 1, 'mealType': entry.key.name},
      ];
    } else if (plan is ManualPlan) {
      date = plan.date;
      method = 'manual';
      items = [
        for (final entry in plan.meals.entries)
          for (final item in entry.value)
            {
              'foodId': item.food.id,
              'quantity': item.quantity,
              'mealType': entry.key.name,
            },
      ];
    } else {
      throw ArgumentError.value(plan, 'plan', 'Unsupported meal plan type.');
    }

    if (items.isEmpty) {
      throw StateError('Add at least one food before saving the plan.');
    }

    return _data(
      await _api.post(
        '/plans',
        data: {'date': _date(date), 'method': method, 'items': items},
      ),
    );
  }

  /// GET /plans?date=YYYY-MM-DD; a missing plan is reported by the API as 404.
  Future<Map<String, dynamic>> get(DateTime date) async {
    return _data(
      await _api.get('/plans', queryParameters: {'date': _date(date)}),
    );
  }

  Future<Object?> getSavedPlan(
    DateTime date,
    List<FoodCatalogItem> catalog,
  ) async {
    final data = await get(date);
    final plan = Map<String, dynamic>.from(data['plan'] as Map);

    final method = plan['method']?.toString();
    final rawItems = plan['items'];

    if (rawItems is! List) {
      throw const FormatException('Saved plan items are missing.');
    }

    final foodsById = {for (final food in catalog) food.id: food};

    final savedDate = DateTime.parse(
      (plan['date'] ??
              plan['planDate'] ??
              '${date.year.toString().padLeft(4, '0')}-'
                  '${date.month.toString().padLeft(2, '0')}-'
                  '${date.day.toString().padLeft(2, '0')}')
          .toString(),
    );

    if (method == 'auto') {
      final meals = <MealType, FoodCatalogItem>{};

      for (final raw in rawItems) {
        final item = Map<String, dynamic>.from(raw as Map);
        final foodId = (item['food'] ?? item['foodId'] ?? item['food_id'])
            ?.toString();

        if (foodId == null) {
          throw const FormatException('Saved plan food ID is missing.');
        }
        final food = foodsById[foodId];

        if (food == null) {
          throw FormatException('Food $foodId is missing from the catalog.');
        }

        final type = MealType.values.byName(
          (item['mealType'] ?? item['meal_type']).toString(),
        );

        meals[type] = food;
      }

      return AutoPlan(date: savedDate, meals: meals);
    }

    if (method == 'manual') {
      final meals = <MealType, List<ManualItem>>{};

      for (final raw in rawItems) {
        final item = Map<String, dynamic>.from(raw as Map);
        final foodId = (item['food'] ?? item['foodId'] ?? item['food_id'])
            ?.toString();

        if (foodId == null) {
          throw const FormatException('Saved plan food ID is missing.');
        }
        final food = foodsById[foodId];

        if (food == null) {
          throw FormatException('Food $foodId is missing from the catalog.');
        }

        final type = MealType.values.byName(
          (item['mealType'] ?? item['meal_type']).toString(),
        );

        (meals[type] ??= []).add(
          ManualItem(food: food, quantity: (item['quantity'] as num).toInt()),
        );
      }

      return ManualPlan(date: savedDate, meals: meals);
    }

    throw FormatException('Unknown plan method: $method');
  }

  /// DELETE /plans?date=YYYY-MM-DD; the server preserves the daily budget.
  Future<Map<String, dynamic>> delete(DateTime date) async {
    return _data(await _api.delete('/plans?date=${_date(date)}'));
  }
}
