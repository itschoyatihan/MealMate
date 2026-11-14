import '../services/api_client.dart';
import '../ui/foods_page.dart';

class FoodRepository {
  FoodRepository(this.api);

  final ApiClient api;

  Future<List<FoodCatalogItem>> getFoods() async {
    final result = <FoodCatalogItem>[];
    var page = 1;

    while (true) {
      final body = await api.get(
        '/foods',
        authenticated: false,
        queryParameters: {'page': page, 'limit': 100},
      );

      if (body['success'] != true) {
        throw StateError('Cannot load foods.');
      }

      final data = Map<String, dynamic>.from(body['data'] as Map);
      final rows = data['foods'] as List;

      for (final row in rows) {
        final food = Map<String, dynamic>.from(row as Map);
        result.add(
          FoodCatalogItem(
            id: food['id'].toString(),
            name: food['name'].toString(),
            price: (food['price'] as num).toInt(),
            shopName: food['shopName'].toString(),
            location: (food['location'] ?? '').toString(),
            category: food['category'].toString(),
            imagePath: food['imagePath']?.toString(),
          ),
        );
      }

      final pagination =
          Map<String, dynamic>.from(data['pagination'] as Map);

      if (pagination['hasMore'] != true) break;
      page++;
    }

    return result;
  }

  Future<Set<String>> getFavoriteIds() async {
    final body = await api.get('/favorites');

    if (body['success'] != true) {
      throw StateError('Cannot load favorites.');
    }

    final data = Map<String, dynamic>.from(body['data'] as Map);
    final rows = data['favorites'] as List;

    return rows.map((row) {
      final favorite = Map<String, dynamic>.from(row as Map);
      final food = favorite['food'];

      if (food is Map) {
        return food['id'].toString();
      }

      return (favorite['foodId'] ?? favorite['food_id']).toString();
    }).toSet();
  }

  Future<void> setFavorite(String foodId, bool add) async {
    final Map<String, dynamic> body;

    if (add) {
      body = await api.post(
        '/favorites',
        data: {'foodId': foodId},
      );
    } else {
      body = await api.delete('/favorites/$foodId');
    }

    if (body['success'] != true) {
      throw StateError('Cannot update favorite.');
    }
  }
}
