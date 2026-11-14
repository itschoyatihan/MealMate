import 'package:flutter/material.dart';

import 'auto_models.dart';
import 'manual_models.dart';
import 'manual_browse.dart';
import 'foods_page.dart';

class ManualDetailPage extends StatefulWidget {
  const ManualDetailPage({
    super.key,
    required this.type,
    required this.foods,
    required this.initialItems,
  });
  final MealType type;
  final List<FoodCatalogItem> foods;
  final List<ManualItem> initialItems;
  @override
  State<ManualDetailPage> createState() => _ManualDetailPageState();
}

class _ManualDetailPageState extends State<ManualDetailPage> {
  static const dark = Color(0xFF123D22), green = Color(0xFF278A18);
  late final List<ManualItem> items;
  @override
  void initState() {
    super.initState();
    items = List.of(widget.initialItems);
  }

  int get total => items.fold(0, (sum, item) => sum + item.total);
  void add(FoodCatalogItem food) => setState(() {
    final i = items.indexWhere((e) => e.food.id == food.id);
    if (i < 0) {
      items.add(ManualItem(food: food, quantity: 1));
    } else {
      items[i] = items[i].withQuantity(items[i].quantity + 1);
    }
  });
  Future<void> browse() async => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ManualBrowsePage(
        mealName: widget.type.label,
        foods: widget.foods,
        onAdd: add,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFAF2),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFFFAF2),
      title: Text(
        widget.type.label,
        style: const TextStyle(fontWeight: FontWeight.bold, color: dark),
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'Total: $total Ks',
              style: const TextStyle(fontWeight: FontWeight.bold, color: green),
            ),
          ),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_basket_outlined,
                    color: Color(0xFFFF8300),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Selected Foods (${items.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No foods selected yet'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final item = items[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.food.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${item.food.shopName} • ${item.food.price} Ks each',
                                      ),
                                      Text(
                                        '${item.total} Ks',
                                        style: const TextStyle(
                                          color: green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => setState(() {
                                    if (item.quantity == 1) {
                                      items.removeAt(index);
                                    } else {
                                      items[index] = item.withQuantity(
                                        item.quantity - 1,
                                      );
                                    }
                                  }),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: green,
                                  ),
                                  onPressed: () => setState(
                                    () => items[index] = item.withQuantity(
                                      item.quantity + 1,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () =>
                                      setState(() => items.removeAt(index)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              color: const Color(0xFFEAF6DF),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.type.label} Total',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$total Ks',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: OutlinedButton.icon(
                onPressed: browse,
                icon: const Icon(Icons.add),
                label: const Text('Add More Foods'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: dark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(context, List<ManualItem>.of(items)),
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
