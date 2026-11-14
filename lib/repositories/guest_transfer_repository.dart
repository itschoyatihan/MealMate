import '../services/api_client.dart';
import '../ui/auto_models.dart';
import '../ui/manual_models.dart';
import '../ui/foods_page.dart';
import 'food_repository.dart';

/// Only call this after a successful NEW-ACCOUNT registration.
/// Never call it after login or session restoration.
class GuestTransferRepository {
  GuestTransferRepository(this._api);
  final ApiClient _api;

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _key(FoodCatalogItem food) =>
      '${food.name.trim().toLowerCase()}\u0001'
      '${food.shopName.trim().toLowerCase()}\u0001'
      '${food.category.trim().toLowerCase()}\u0001${food.price}';

  Future<Map<String, dynamic>> transfer({
    required DateTime date,
    required int? guestBudget,
    required Object? guestPlan,
  }) async {
    if (guestBudget == null && guestPlan == null) {
      return const {'success': true, 'data': <String, dynamic>{}};
    }
    if (guestPlan != null && guestBudget == null) {
      throw StateError('A guest meal plan needs a daily budget to transfer.');
    }

    final payload = <String, dynamic>{'date': _date(date)};
    if (guestBudget != null) payload['budget'] = {'amount': guestBudget};

    if (guestPlan != null) {
      final foods = await FoodRepository(_api).getFoods();
      final byKey = <String, List<FoodCatalogItem>>{};
      for (final food in foods) {
        byKey.putIfAbsent(_key(food), () => []).add(food);
      }

      String mappedId(FoodCatalogItem guestFood) {
        final matches = byKey[_key(guestFood)] ?? const <FoodCatalogItem>[];
        if (matches.length != 1) {
          throw StateError(
            'Cannot safely match ${guestFood.name} at ${guestFood.shopName} '
            'to one backend catalog entry. Guest data was kept.',
          );
        }
        return matches.single.id;
      }

      late final String method;
      late final List<Map<String, dynamic>> items;
      if (guestPlan is AutoPlan) {
        if (!_sameDay(guestPlan.date, date)) {
          throw StateError('Guest plan date is not today.');
        }
        method = 'auto';
        items = [
          for (final entry in guestPlan.meals.entries)
            {'foodId': mappedId(entry.value), 'quantity': 1,
             'mealType': entry.key.name},
        ];
      } else if (guestPlan is ManualPlan) {
        if (!_sameDay(guestPlan.date, date)) {
          throw StateError('Guest plan date is not today.');
        }
        method = 'manual';
        items = [
          for (final entry in guestPlan.meals.entries)
            for (final item in entry.value)
              {'foodId': mappedId(item.food), 'quantity': item.quantity,
               'mealType': entry.key.name},
        ];
      } else {
        throw StateError('Unsupported guest plan type.');
      }
      if (items.isEmpty) throw StateError('Guest meal plan is empty.');
      payload['plan'] = {'method': method, 'items': items};
    }

    final response = await _api.post('/guest-transfer', data: payload);
    if (response['success'] != true) {
      throw StateError('Guest transfer was not successful.');
    }
    return response;
  }
}
