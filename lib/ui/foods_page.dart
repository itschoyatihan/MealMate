import 'package:flutter/material.dart';

/// One catalog entry represents one food sold by one shop.
/// Replace sample catalog records with real data when ready.
class FoodCatalogItem {
  const FoodCatalogItem({
    required this.id,
    required this.name,
    required this.price,
    required this.shopName,
    required this.location,
    required this.category,
    this.imagePath,
  });

  final String id;
  final String name;
  final int price;
  final String shopName;
  final String location;
  final String category;
  final String? imagePath;
}

// EDIT YOUR FOOD CATALOG HERE.
// Replace these sample entries with real campus shops and prices.
// Each ID must be unique. Keep imagePath omitted until images are ready.
const List<FoodCatalogItem> sampleFoodCatalog = [
  FoodCatalogItem(
    id: 'food_001',
    name: 'Mohinga',
    price: 2000,
    shopName: 'Shop A',
    location: 'Hlaing',
    category: 'Soups',
    imagePath: 'assets/img/mohinga.jpg',
  ),
  FoodCatalogItem(
    id: 'food_002',
    name: 'Chicken Rice',
    price: 4000,
    shopName: 'Shop B',
    location: 'Kamayut',
    category: 'Rice Dishes',
    imagePath: 'assets/img/chickenrice.jpg',
  ),
  FoodCatalogItem(
    id: 'food_003',
    name: 'Fried Noodles',
    price: 3000,
    shopName: 'Shop C',
    location: 'Hlaing',
    category: 'Noodles',
  ),
  FoodCatalogItem(
    id: 'food_004',
    name: 'Tea Leaf Salad',
    price: 2500,
    shopName: 'Shop A',
    location: 'Insein',
    category: 'Salads',
    imagePath: 'assets/img/tealeafsalad.jpg',
  ),
  FoodCatalogItem(
    id: 'food_005',
    name: 'Fried Rice',
    price: 3500,
    shopName: 'Shop A',
    location: 'Hlaing',
    category: 'Rice Dishes',
    imagePath: 'assets/img/fried_rice.jpg',
  ),
  FoodCatalogItem(
    id: 'food_006',
    name: 'Mohinga',
    price: 2300,
    shopName: 'Shop B',
    location: 'Kamayut',
    category: 'Soups',
  ),
  FoodCatalogItem(
    id: 'food_007',
    name: 'Shan Noodles',
    price: 3000,
    shopName: 'Shop D',
    location: 'Insein',
    category: 'Noodles',
    imagePath: 'assets/img/shannoodles.jpg',
  ),
  FoodCatalogItem(
    id: 'food_008',
    name: 'Papaya Salad',
    price: 2200,
    shopName: 'Shop C',
    location: 'Hlaing',
    category: 'Salads',
    imagePath: 'assets/img/papayasalad.jpg',
  ),
  FoodCatalogItem(
    id: 'food_009',
    name: 'Steamed Bun',
    price: 1500,
    shopName: 'Shop E',
    location: 'Kamayut',
    category: 'Others',
  ),
  FoodCatalogItem(
    id: 'food_010',
    name: 'Mohinga',
    price: 2500,
    shopName: 'Shop C',
    location: 'Insein',
    category: 'Soups',
  ),
];

class FoodsPage extends StatefulWidget {
  const FoodsPage({
    super.key,
    this.isLoggedIn = false,
    this.foods = sampleFoodCatalog,
    this.initialFavoriteIds = const {},
    this.onLoginRequested,
    this.onExpensesRequested,
    this.onProfileRequested,
    this.onFavoritesChanged,
    this.onFavoriteToggle,
    this.onBack,
    this.onMyPlanRequested,
    this.embedded = false,
  });

  final bool isLoggedIn;
  final List<FoodCatalogItem> foods;
  final Set<String> initialFavoriteIds;
  final VoidCallback? onLoginRequested;
  final VoidCallback? onExpensesRequested;
  final VoidCallback? onProfileRequested;
  final ValueChanged<Set<String>>? onFavoritesChanged;
  final Future<void> Function(String foodId, bool add)? onFavoriteToggle;
  final VoidCallback? onBack;
  final VoidCallback? onMyPlanRequested;
  final bool embedded;

  @override
  State<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
  static const _darkGreen = Color(0xFF123D22);
  static const _green = Color(0xFF17852A);
  static const _orange = Color(0xFFFF8300);
  static const _cream = Color(0xFFFFFAF2);
  static const _categories = [
    'All',
    'Rice Dishes',
    'Noodles',
    'Soups',
    'Salads',
    'Others',
  ];

  final TextEditingController _searchController = TextEditingController();
  late Set<String> _favoriteIds;
  final Set<String> _updatingFavorites = {};
  String _selectedCategory = 'All';
  String _query = '';
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _favoriteIds = {...widget.initialFavoriteIds};
  }

  @override
  void didUpdateWidget(covariant FoodsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFavoriteIds != widget.initialFavoriteIds) {
      _favoriteIds = {...widget.initialFavoriteIds};
    }
    if (oldWidget.isLoggedIn && !widget.isLoggedIn) {
      _showFavorites = false;
      _favoriteIds.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodCatalogItem> get _visibleFoods {
    if (_showFavorites) {
      return widget.foods
          .where((food) => _favoriteIds.contains(food.id))
          .toList();
    }
    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      return widget.foods
          .where(
            (food) =>
                food.name.toLowerCase().contains(query) ||
                food.shopName.toLowerCase().contains(query),
          )
          .toList();
    }
    if (_selectedCategory == 'All') return widget.foods;
    return widget.foods
        .where((food) => food.category == _selectedCategory)
        .toList();
  }

  void _requestLogin() {
    if (widget.onLoginRequested != null) {
      widget.onLoginRequested!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to use favorites.')),
      );
    }
  }

  void _openProtectedPage(String feature) {
    if (!widget.isLoggedIn) {
      _requestLogin();
      return;
    }

    if (feature == 'Expenses') {
      widget.onExpensesRequested?.call();
    } else if (feature == 'Profile') {
      widget.onProfileRequested?.call();
    }
  }

  Future<void> _guestFavoriteDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.favorite_border_rounded, color: _orange),
            SizedBox(width: 10),
            Text('Please log in'),
          ],
        ),
        content: const Text('Log in to save your favorite foods.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            onPressed: () {
              Navigator.pop(dialogContext);
              _requestLogin();
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(String id) async {
    if (!widget.isLoggedIn) {
      _guestFavoriteDialog();
      return;
    }

    if (_updatingFavorites.contains(id)) return;

    final add = !_favoriteIds.contains(id);

    if (widget.onFavoriteToggle == null) {
      setState(() {
        if (add) {
          _favoriteIds.add(id);
        } else {
          _favoriteIds.remove(id);
        }
      });
      widget.onFavoritesChanged?.call({..._favoriteIds});
      return;
    }

    setState(() => _updatingFavorites.add(id));

    try {
      await widget.onFavoriteToggle!(id, add);

      if (!mounted) return;

      setState(() {
        if (add) {
          _favoriteIds.add(id);
        } else {
          _favoriteIds.remove(id);
        }
      });

      widget.onFavoritesChanged?.call({..._favoriteIds});
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update favorite. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingFavorites.remove(id));
      }
    }
  }

  void _openFavorites() {
    if (!widget.isLoggedIn) {
      _guestFavoriteDialog();
      return;
    }
    setState(() => _showFavorites = !_showFavorites);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 850;
        return Scaffold(
          backgroundColor: _cream,
          body: SafeArea(
            child: Row(
              children: [
                if (desktop && !widget.embedded) _desktopSidebar(),
                Expanded(child: _pageContent(desktop)),
              ],
            ),
          ),
          bottomNavigationBar: (desktop || widget.embedded) ? null : _mobileBottomBar(),
        );
      },
    );
  }

  // Matches the sidebar layout and branding in home_page.dart.
  Widget _desktopSidebar() {
    return Container(
      width: 205,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brand(),
          const SizedBox(height: 44),
          _sideItem(Icons.home_rounded, 'Home', onTap: widget.onBack),
          _sideItem(Icons.fastfood, 'Foods', selected: true),
          _sideItem(
            Icons.calendar_month_outlined,
            'My Plan',
            onTap: widget.onMyPlanRequested,
          ),
          _sideItem(
            Icons.account_balance_wallet_outlined,
            'Expenses',
            onTap: () => _openProtectedPage('Expenses'),
          ),
          _sideItem(
            Icons.person_outline_rounded,
            'Profile',
            onTap: () => _openProtectedPage('Profile'),
          ),
        ],
      ),
    );
  }

  Widget _brand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/img/logo.png',
          height: 39,
          width: 39,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'Meal',
                    style: TextStyle(color: Color(0xFF083F25)),
                  ),
                  TextSpan(
                    text: 'Mate',
                    style: TextStyle(color: Color(0xFFFF7900)),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const Text(
              'Plan · Eat · Save',
              style: TextStyle(
                color: Color(0xFF083F25),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sideItem(
    IconData icon,
    String title, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFF7900) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF083F25),
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF083F25),
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageContent(bool desktop) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1150),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                desktop ? 26 : 14,
                18,
                desktop ? 26 : 14,
                12,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!desktop) ...[
                          const Icon(
                            Icons.restaurant_rounded,
                            color: _orange,
                            size: 26,
                          ),
                          const SizedBox(width: 7),
                        ],
                        Expanded(
                          child: Text(
                            _showFavorites ? 'Favorite Foods' : 'Food Catalog',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _darkGreen,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: _showFavorites
                              ? 'Back to catalog'
                              : 'Favorite Foods',
                          onPressed: _openFavorites,
                          icon: Icon(
                            _showFavorites
                                ? Icons.grid_view_rounded
                                : Icons.favorite_border_rounded,
                            color: _orange,
                          ),
                        ),
                      ],
                    ),
                    if (!_showFavorites) ...[
                      const SizedBox(height: 15),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Search foods or shops...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8E2D8),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8E2D8),
                            ),
                          ),
                        ),
                      ),
                      if (_query.trim().isEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 7),
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final selected =
                                  category == _selectedCategory &&
                                  _query.isEmpty;
                              return ChoiceChip(
                                label: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selected ? Colors.white : _darkGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                selected: selected,
                                selectedColor: _green,
                                backgroundColor: Colors.white,
                                showCheckmark: false,
                                side: BorderSide(
                                  color: selected
                                      ? _green
                                      : const Color(0xFFE8E2D8),
                                ),
                                onSelected: (_) => setState(() {
                                  _selectedCategory = category;
                                  _searchController.clear();
                                  _query = '';
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _showFavorites
                                ? 'Saved Favorites'
                                : _query.isNotEmpty
                                ? 'Results for “${_query.trim()}”'
                                : _selectedCategory == 'All'
                                ? 'All Foods'
                                : _selectedCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _darkGreen,
                            ),
                          ),
                        ),
                        Text(
                          '${_visibleFoods.length} items',
                          style: const TextStyle(
                            color: Color(0xFF6D756F),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_visibleFoods.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showFavorites
                              ? Icons.favorite_border_rounded
                              : _query.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.restaurant_menu_rounded,
                          size: 56,
                          color: const Color(0xFF91B79A),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _showFavorites
                              ? 'No favorite foods yet'
                              : _query.isNotEmpty
                              ? 'No matching foods found'
                              : 'No foods available yet',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _darkGreen,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _showFavorites
                              ? 'Tap the heart on a food to save it here.'
                              : _query.isNotEmpty
                              ? 'Try a different food or shop name.'
                              : 'Foods will appear here when the catalog is added.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF68756A)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  desktop ? 26 : 14,
                  0,
                  desktop ? 26 : 14,
                  26,
                ),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final gap = desktop ? 14.0 : 9.0;
                    final cardWidth = (width - gap) / 2;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: gap,
                        mainAxisSpacing: gap,
                        mainAxisExtent:
                            (cardWidth * 3 / 4) + (cardWidth < 210 ? 138 : 125),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _foodCard(_visibleFoods[index], cardWidth),
                        childCount: _visibleFoods.length,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _foodCard(FoodCatalogItem food, double width) {
    final compact = width < 210;
    final isFavorite = _favoriteIds.contains(food.id);
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Keep every food image at 4:3, including the placeholder.
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF1F5E9),
                  child: food.imagePath == null
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Color(0xFF9CB4A0),
                            size: 35,
                          ),
                        )
                      : Image.asset(
                          food.imagePath!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Color(0xFF9CB4A0),
                                size: 35,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            SizedBox(height: compact ? 9 : 12),
            // Details stay left; the larger favorite heart is vertically
            // centered on the right, not pinned to the card's bottom corner.
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 14 : 18,
                            fontWeight: FontWeight.w800,
                            color: _darkGreen,
                          ),
                        ),
                        SizedBox(height: compact ? 3 : 5),
                        Text(
                          '${_formatPrice(food.price)} MMK',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 13 : 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC15D13),
                          ),
                        ),
                        SizedBox(height: compact ? 5 : 8),
                        Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: compact ? 14 : 17,
                              color: _orange,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                food.shopName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 12 : 14,
                                  color: const Color(0xFF576458),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 3 : 5),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: compact ? 14 : 17,
                              color: const Color(0xFF576458),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                food.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 12 : 14,
                                  color: const Color(0xFF576458),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? 2 : 8),
                  IconButton(
                    tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                    onPressed: () => _toggleFavorite(food.id),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: compact ? 36 : 44,
                      minHeight: compact ? 40 : 44,
                    ),
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: compact ? 27 : 32,
                      color: isFavorite ? _orange : const Color(0xFF59665A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  Widget _mobileBottomBar() {
    return NavigationBar(
      selectedIndex: 1,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            widget.onBack?.call();
            break;

          case 2:
            widget.onMyPlanRequested?.call();
            break;

          case 3:
            _openProtectedPage('Expenses');
            break;

          case 4:
            _openProtectedPage('Profile');
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.fastfood_outlined),
          label: 'Foods',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'My Plan',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: 'Expenses',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
