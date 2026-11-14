import 'package:flutter/material.dart';

import 'foods_page.dart';

class ManualBrowsePage extends StatefulWidget {
  const ManualBrowsePage({
    super.key,
    required this.mealName,
    required this.foods,
    required this.onAdd,
  });
  final String mealName;
  final List<FoodCatalogItem> foods;
  final ValueChanged<FoodCatalogItem> onAdd;
  @override
  State<ManualBrowsePage> createState() => _ManualBrowsePageState();
}

class _ManualBrowsePageState extends State<ManualBrowsePage> {
  static const dark = Color(0xFF123D22), orange = Color(0xFFFF8300);
  String query = '', category = 'All';
  static const categories = [
    'All',
    'Rice Dishes',
    'Noodles',
    'Soups',
    'Salads',
    'Others',
  ];
  @override
  Widget build(BuildContext context) {
    final matches = widget.foods.where((food) {
      final q = query.trim().toLowerCase();
      // Search across ALL categories; chips filter only normal browsing.
      return q.isNotEmpty
          ? food.name.toLowerCase().contains(q) ||
                food.shopName.toLowerCase().contains(q)
          : category == 'All' || food.category == category;
    }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF2),
        title: Text(
          'Add to ${widget.mealName}',
          style: const TextStyle(color: dark, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search food or shop...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              if (query.trim().isEmpty)
                SizedBox(
                  height: 45,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final c in categories)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: category == c,
                            selectedColor: const Color(0xFFDFF2CD),
                            onSelected: (_) => setState(() => category = c),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: matches.isEmpty
                    ? const Center(child: Text('No foods found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final food = matches[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  _FoodThumb(food: food),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          food.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          food.shopName,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          '${food.price} Ks',
                                          style: const TextStyle(
                                            color: orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Add ${food.name}',
                                    onPressed: () {
                                      widget.onAdd(food);
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(
                                      Icons.add_circle,
                                      color: Color(0xFF66BD27),
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodThumb extends StatelessWidget {
  const _FoodThumb({required this.food});
  final FoodCatalogItem food;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      width: 72,
      height: 72,
      child: food.imagePath == null || food.imagePath!.isEmpty
          ? const ColoredBox(
              color: Color(0xFFE9F3DD),
              child: Icon(Icons.restaurant, color: Color(0xFF24852C)),
            )
          : Image.asset(
              food.imagePath!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE9F3DD),
                child: Icon(Icons.restaurant),
              ),
            ),
    ),
  );
}
