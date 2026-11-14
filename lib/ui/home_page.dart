import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/api_client.dart';
import '../logic/auth/auth_bloc.dart';
import '../logic/auth/auth_event.dart';
import '../logic/auth/auth_state.dart';
import '../repositories/food_repository.dart';
import '../repositories/mealplan_repository.dart';
import 'login_page.dart';
import 'set_budget.dart';
import 'budget_save.dart';
import 'guest_budget.dart';
import 'foods_page.dart';
import 'auto_page.dart';
import 'auto_models.dart';
import 'manual_page.dart';
import 'manual_models.dart';
import 'myplan_page.dart';
import 'profile_page.dart';
import 'expenses_page.dart';

class HomePage extends StatelessWidget {
  void _openLogin(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const LoginPage()));
  }

  const HomePage({super.key});

  static const Color green = Color(0xFF083F25);
  static const Color orange = Color(0xFFFF7900);
  static const Color cream = Color(0xFFFFF8EF);
  static const Color lightGreen = Color(0xFFEAF6DF);
  // Shared, in-memory saved plan. Both planners replace the same active plan.
  // Backend persistence and guest-to-account migration will be added later.
  static final ValueNotifier<Object?> _savedTodayPlan = ValueNotifier<Object?>(
    null,
  );
  // Snapshot is captured before registration changes the auth session.
  static ({DateTime date, int? budget, Object? plan}) guestSnapshot() => (
    date: DateTime.now(),
    budget: GuestBudget.amount,
    plan: _savedTodayPlan.value,
  );

  // Registration owns the first account load until guest transfer completes.
  static bool registrationTransferPending = false;
  static final ValueNotifier<int> transferRefresh = ValueNotifier<int>(0);
  static void refreshAfterTransfer() => transferRefresh.value++;

  static final ValueNotifier<int> _selectedSection = ValueNotifier<int>(0);
  static final GlobalKey<ExpensesPageState> _expensesKey =
      GlobalKey<ExpensesPageState>();

  void _showMyPlan() => _selectSection(2);
  void _showHome() => _selectSection(0);
  void _showExpenses(BuildContext context) {
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      _openLogin(context);
      return;
    }
    _selectSection(3);
  }

  Future<void> _selectSection(int section) async {
    if (_selectedSection.value == 3 && section != 3) {
      final canLeave = await _expensesKey.currentState?.confirmLeave() ?? true;
      if (!canLeave) return;
    }
    _selectedSection.value = section;
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveBudgetToBackend(BuildContext context, int amount) async {
    final api = context.read<ApiClient>();

    final response = await api.put(
      '/budget',
      data: {'date': _todayDate(), 'amount': amount},
    );

    if (response['success'] != true) {
      throw StateError('Budget could not be saved.');
    }
  }

  Future<void> _editSavedPlan(BuildContext context) async {
    final plan = _savedTodayPlan.value;
    if (plan is! AutoPlan && plan is! ManualPlan) return;

    final budget = GuestBudget.amount;
    if (budget == null) {
      await _startPlan(context, plan is AutoPlan ? 'Automatic' : 'Manual');
      return;
    }

    final isLoggedIn = context.read<AuthBloc>().state.isAuthenticated;
    List<FoodCatalogItem> foods = sampleFoodCatalog;

    if (isLoggedIn) {
      try {
        foods = await FoodRepository(context.read<ApiClient>()).getFoods();
        if (!context.mounted) return;
        if (foods.isEmpty) {
          throw StateError('No foods available in the catalog.');
        }
      } catch (error, stackTrace) {
        debugPrint('EDIT PLAN CATALOG ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load foods for editing.')),
        );
        return;
      }
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => plan is AutoPlan
            ? AutoPlanPage(
                dailyBudget: budget,
                catalog: foods,
                initialPlan: plan,
                onSave: (updated) => _savePlan(context, updated),
              )
            : ManualPage(
                dailyBudget: budget,
                foods: foods,
                initialPlan: plan as ManualPlan,
                onSave: (updated) => _savePlan(context, updated),
              ),
      ),
    );
  }

  Widget _myPlanContent(BuildContext context) => MyPlanPage(
    savedPlan: _savedTodayPlan,
    onChooseAutomatic: () => _startPlan(context, 'Automatic'),
    onChooseManual: () => _startPlan(context, 'Manual'),
    onEdit: () => _editSavedPlan(context),
    onDelete: () async {
      final isLoggedIn = context.read<AuthBloc>().state.isAuthenticated;
      try {
        if (isLoggedIn) {
          await MealPlanRepository(context.read<ApiClient>())
              .delete(DateTime.now());
        }
        _savedTodayPlan.value = null;
      } catch (error, stackTrace) {
        debugPrint('PLAN DELETE ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete meal plan. Please try again.'),
          ),
        );
      }
    },
    onBack: _showHome,
  );

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _savePlan(BuildContext homeContext, Object plan) async {
    if (!homeContext.mounted) {
      throw StateError('Home is no longer available.');
    }

    final isLoggedIn = homeContext.read<AuthBloc>().state.isAuthenticated;

    if (isLoggedIn) {
      final repository = MealPlanRepository(homeContext.read<ApiClient>());

      // Backend must save successfully before updating the UI.
      await repository.save(plan);
    }

    if (!homeContext.mounted) {
      throw StateError('Home is no longer available.');
    }

    _savedTodayPlan.value = plan;

    final homeRoute = ModalRoute.of(homeContext);
    if (homeRoute != null) {
      Navigator.of(homeContext)
          .popUntil((route) => identical(route, homeRoute));
    }
  }

  Widget _plannerPage(BuildContext homeContext, String method, int budget) {
    final isLoggedIn = homeContext.read<AuthBloc>().state.isAuthenticated;

    Widget buildPlanner(List<FoodCatalogItem> foods) {
      if (method == 'Automatic') {
        return AutoPlanPage(
          dailyBudget: budget,
          catalog: foods,
          onSave: (AutoPlan plan) => _savePlan(homeContext, plan),
        );
      }

      return ManualPage(
        dailyBudget: budget,
        foods: foods,
        onSave: (ManualPlan plan) => _savePlan(homeContext, plan),
      );
    }

    if (!isLoggedIn) {
      return buildPlanner(sampleFoodCatalog);
    }

    return FutureBuilder<List<FoodCatalogItem>>(
      future: FoodRepository(homeContext.read<ApiClient>()).getFoods(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meal Planning')),
            body: const Center(child: Text('Could not load food catalog.')),
          );
        }

        final foods = snapshot.data ?? [];

        if (foods.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Meal Planning')),
            body: const Center(child: Text('No foods available.')),
          );
        }

        return buildPlanner(foods);
      },
    );
  }

  void _openPlanner(BuildContext context, String method, int budget) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _plannerPage(context, method, budget),
      ),
    );
  }

  // Home > Set Daily Budget retains the existing confirmation screen.
  Future<void> openBudget(BuildContext context) async {
    final isLoggedIn = context.read<AuthBloc>().state.isAuthenticated;

    Future<bool> saveBudget(int amount) async {
      try {
        if (isLoggedIn) {
          await _saveBudgetToBackend(context, amount);
        }

        GuestBudget.save(amount);
        return true;
      } catch (error, stackTrace) {
        debugPrint('BUDGET SAVE ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
        return false;
      }
    }

    await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => SetBudgetPage(
          initialBudget: GuestBudget.amount,
          onSave: saveBudget,
          confirmationPageBuilder: (amount) => BudgetSavePage(
            budget: amount,
            onBudgetChanged: saveBudget,
            automaticPageBuilder: (_) => _plannerPage(
              context,
              'Automatic',
              GuestBudget.amount ?? amount,
            ),
            manualPageBuilder: (_) =>
                _plannerPage(context, 'Manual', GuestBudget.amount ?? amount),
          ),
        ),
      ),
    );
  }

  static Future<({List<FoodCatalogItem> foods, Set<String> favorites})>?
  _foodsLoad;
  static Object? _foodsSessionKey;
  static ({List<FoodCatalogItem> foods, Set<String> favorites})?
  _foodsCachedData;
  Future<({List<FoodCatalogItem> foods, Set<String> favorites})> _loadFoods(
    BuildContext context,
  ) {
    final auth = context.read<AuthBloc>().state;
    final sessionKey = auth.isAuthenticated ? auth : null;
    if (_foodsLoad == null || !identical(_foodsSessionKey, sessionKey)) {
      _foodsSessionKey = sessionKey;
      _foodsCachedData = null;
      final repository = FoodRepository(context.read<ApiClient>());
      _foodsLoad = () async {
        final foods = await repository.getFoods();
        final favorites = auth.isAuthenticated
            ? await repository.getFavoriteIds()
            : <String>{};
        final result = (foods: foods, favorites: favorites);
        _foodsCachedData = result;
        return result;
      }();
    }
    return _foodsLoad!;
  }

  Future<void> _openFoods(BuildContext context) async {
    await _selectSection(1);
  }

  Widget _foodsContent(BuildContext context) {
    final repository = FoodRepository(context.read<ApiClient>());
    return FutureBuilder<
      ({List<FoodCatalogItem> foods, Set<String> favorites})
    >(
      future: _loadFoods(context),
      initialData: _foodsCachedData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load foods. Please try again.'),
                TextButton(
                  onPressed: () {
                    _foodsLoad = null;
                    _selectedSection.value = -1;
                    _selectedSection.value = 1;
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.requireData;
        final loggedIn = context.read<AuthBloc>().state.isAuthenticated;
        return FoodsPage(
          embedded: true,
          isLoggedIn: loggedIn,
          foods: data.foods,
          initialFavoriteIds: data.favorites,
          onFavoriteToggle: loggedIn
              ? (id, add) async {
                  await repository.setFavorite(id, add);
                  if (add) {
                    data.favorites.add(id);
                  } else {
                    data.favorites.remove(id);
                  }
                }
              : null,
          onBack: _showHome,
          onMyPlanRequested: _showMyPlan,
          onLoginRequested: () => _openLogin(context),
          onExpensesRequested: () => _showExpenses(context),
          onProfileRequested: () => _openProfile(context),
        );
      },
    );
  }

  void _unavailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature page is not implemented yet.')),
    );
  }

  void _protectedFeature(BuildContext context, String feature) {
    final isLoggedIn = context.read<AuthBloc>().state.isAuthenticated;
    if (!isLoggedIn) {
      _openLogin(context); // No intermediate login-required dialog.
    } else {
      if (feature == 'Expenses') {
        _showExpenses(context);
      } else {
        _unavailable(context, feature);
      }
    }
  }

  Future<void> _openAccount(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;

    if (!authState.isAuthenticated) {
      _openLogin(context);
      return;
    }

    final user = authState.user;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Your Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: lightGreen,
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5B636B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile settings are coming in a later step.',
                style: TextStyle(fontSize: 13, color: Color(0xFF5B636B)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openProfile(BuildContext context) async {
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      _openLogin(context);
      return;
    }
    await _selectSection(4);
  }

  Future<void> _startPlan(BuildContext context, String method) async {
    if (method == 'My Plan' || method == 'View') {
      _showMyPlan();
      return;
    }
    if (method != 'Automatic' && method != 'Manual') {
      _unavailable(context, method);
      return;
    }

    var budget = GuestBudget.amount;
    if (budget == null) {
      final isLoggedIn = context.read<AuthBloc>().state.isAuthenticated;
      final api = context.read<ApiClient>();
      budget = await Navigator.of(context).push<int>(
        MaterialPageRoute<int>(
          builder: (_) => SetBudgetPage(
            onSave: (amount) async {
              if (isLoggedIn) {
                final response = await api.put(
                  '/budget',
                  data: {'date': _todayDate(), 'amount': amount},
                );
                if (response['success'] != true) {
                  throw StateError('Budget could not be saved.');
                }
              }
              GuestBudget.save(amount);
              return true;
            },
          ),
        ),
      );
      if (!context.mounted || budget == null) return;
      // Skip BudgetSavePage for a planner-initiated budget setup.
    }
    if (!context.mounted) return;
    _openPlanner(context, method, budget);
  }

  @override
  Widget build(BuildContext context) {
    return _PlanSessionGate(
      child: ValueListenableBuilder<int>(
        valueListenable: _selectedSection,
        builder: (context, selectedSection, _) => Scaffold(
          backgroundColor: cream,
          body: LayoutBuilder(
            builder: (context, outer) {
              final isDesktop = outer.maxWidth >= 850;
              return Row(
                children: [
                  if (isDesktop) _sidebar(context, selectedSection),
                  Expanded(
                    child: SafeArea(
                      child: selectedSection == 1
                          ? _foodsContent(context)
                          : selectedSection == 4
                          ? ProfilePage(
                              embedded: true,
                              onNameUpdated: (name) {
                                context.read<AuthBloc>().add(
                                  AuthProfileNameUpdated(name),
                                );
                              },
                            )
                          : selectedSection == 2
                          ? _myPlanContent(context)
                          : selectedSection == 3
                          ? ExpensesPage(
                              key: _expensesKey,
                              embedded: true,
                              onBack: _showHome,
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final wideContent = constraints.maxWidth >= 680;
                                return SingleChildScrollView(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: constraints.maxWidth >= 900
                                        ? 36
                                        : constraints.maxWidth >= 500
                                        ? 20
                                        : 14,
                                    vertical: constraints.maxWidth < 500
                                        ? 16
                                        : 28,
                                  ),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 1120,
                                      ),
                                      child: _content(context, wideContent),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: LayoutBuilder(
            builder: (context, constraints) {
              if (MediaQuery.sizeOf(context).width >= 850) {
                return const SizedBox.shrink();
              }
              return SafeArea(
                top: false,
                child: NavigationBar(
                  selectedIndex: selectedSection,
                  onDestinationSelected: (index) {
                    switch (index) {
                      case 0:
                        _showHome();
                        return;
                      case 1:
                        _openFoods(context);
                        return;
                      case 2:
                        _startPlan(context, 'My Plan');
                        return;
                      case 3:
                        _showExpenses(context);
                        return;
                      case 4:
                        _openProfile(context);
                        return;
                    }
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sidebar(BuildContext context, int selectedSection) {
    return Container(
      width: 205,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brand(compact: true),
          const SizedBox(height: 44),
          _sideItem(
            Icons.home_rounded,
            'Home',
            selected: selectedSection == 0,
            onTap: _showHome,
          ),
          _sideItem(
            Icons.fastfood,
            'Foods',
            selected: selectedSection == 1,
            onTap: () => _openFoods(context),
          ),
          _sideItem(
            Icons.calendar_month_outlined,
            'My Plan',
            selected: selectedSection == 2,
            onTap: _showMyPlan,
          ),
          _sideItem(
            Icons.account_balance_wallet_outlined,
            'Expenses',
            selected: selectedSection == 3,
            onTap: () => _showExpenses(context),
          ),
          _sideItem(
            Icons.person_outline_rounded,
            'Profile',
            selected: selectedSection == 4,
            onTap: () => _openProfile(context),
          ),
        ],
      ),
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
            color: selected ? orange : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, color: selected ? Colors.white : green, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : green,
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

  Widget _brand({bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/img/logo.png',
          height: compact ? 39 : 56,
          width: compact ? 39 : 56,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: const [
                  TextSpan(
                    text: 'Meal',
                    style: TextStyle(color: green),
                  ),
                  TextSpan(
                    text: 'Mate',
                    style: TextStyle(color: orange),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: compact ? 22 : 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            Text(
              'Plan · Eat · Save',
              style: TextStyle(
                color: green,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _content(BuildContext context, bool desktop) {
    final authState = context.watch<AuthBloc>().state;
    final isLoggedIn = authState.isAuthenticated;
    final userName = authState.user?.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            const Icon(
              Icons.notifications_none_rounded,
              color: green,
              size: 28,
            ),
            const SizedBox(width: 14),
            OutlinedButton.icon(
              onPressed: () => _openAccount(context),
              icon: const Icon(Icons.person_rounded, size: 20),
              label: Text(
                isLoggedIn
                    ? (userName?.trim().isNotEmpty == true
                          ? userName!
                          : 'Profile')
                    : 'Guest',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
                side: const BorderSide(color: green),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        if (!isLoggedIn)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 13,
              runSpacing: 5,
              children: const [
                Icon(Icons.person_rounded, color: green, size: 23),
                Text(
                  'Guest Mode',
                  style: TextStyle(
                    color: green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'You can plan meals and set a budget for today.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        const SizedBox(height: 22),
        Text(
          isLoggedIn && userName?.trim().isNotEmpty == true
              ? 'WELCOME, ${userName!.trim()}!'
              : 'WELCOME!',
          style: TextStyle(
            fontSize: desktop ? 33 : 29,
            fontWeight: FontWeight.w800,
            color: green,
          ),
        ),
        const Text(
          "Let's plan your meals for today.",
          style: TextStyle(color: Color(0xFF4B5563), fontSize: 16),
        ),
        const SizedBox(height: 20),
        _budgetCard(context),
        const SizedBox(height: 24),
        _sectionTitle('Plan Your Meals'),
        const SizedBox(height: 13),
        _adaptiveRow(
          desktop: desktop,
          children: [
            _planCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Automatic Meal Plan',
              subtitle: 'Get a budget-friendly meal plan',
              color: const Color(0xFFFFEAD5),
              iconColor: orange,
              onTap: () => _startPlan(context, 'Automatic'),
            ),
            _planCard(
              icon: Icons.restaurant_rounded,
              title: 'Manual Meal Plan',
              subtitle: 'Choose your own meals',
              color: lightGreen,
              iconColor: const Color(0xFF38B900),
              onTap: () => _startPlan(context, 'Manual'),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: desktop ? 180 : 154,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _featureCard(
                  context,
                  Icons.account_balance_wallet_rounded,
                  'Expenses',
                  'Track your meal spending',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _featureCard(
                  context,
                  Icons.bar_chart_rounded,
                  'Reports',
                  'View weekly & monthly summaries',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _featureCard(
                  context,
                  Icons.assignment_outlined,
                  'Meal History',
                  'See your actual recorded meals',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _sectionTitle("Today's Meal Plan")),
            TextButton(
              onPressed: _showMyPlan,
              child: const Text(
                'View Plan  ›',
                style: TextStyle(color: orange),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<Object?>(
          valueListenable: _savedTodayPlan,
          builder: (context, saved, _) {
            if (saved is AutoPlan && _isToday(saved.date)) {
              final items = <_HomeMealItem>[
                for (final type in MealType.values)
                  if (saved.meals[type] case final food?)
                    _HomeMealItem(type.label, food, 1),
              ];
              return _savedMealsCard(items);
            }
            if (saved is ManualPlan && _isToday(saved.date)) {
              final items = <_HomeMealItem>[
                for (final type in MealType.values)
                  for (final item in saved.meals[type] ?? const <ManualItem>[])
                    _HomeMealItem(type.label, item.food, item.quantity),
              ];
              return _savedMealsCard(items);
            }
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 12),
              decoration: _whiteDecoration(),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    color: Color(0xFF36A52B),
                    size: 37,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No Meal Plan Yet',
                    style: TextStyle(
                      color: green,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    "Choose Automatic or Manual above to plan today's meals.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF59616A)),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _savedMealsCard(List<_HomeMealItem> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _whiteDecoration(),
        child: const Center(child: Text('No foods selected in this plan.')),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _whiteDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 680 ? 4 : 2;
          const gap = 10.0;
          final tileWidth =
              (constraints.maxWidth - (columns - 1) * gap) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(width: tileWidth, child: _savedFoodTile(item)),
            ],
          );
        },
      ),
    );
  }

  Widget _savedFoodTile(_HomeMealItem item) {
    final food = item.food;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        border: Border.all(color: const Color(0xFFE8E8DF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              width: 54,
              height: 54,
              color: lightGreen,
              child: food.imagePath == null
                  ? const Icon(Icons.restaurant, color: green, size: 25)
                  : Image.asset(
                      food.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.restaurant, color: green, size: 25),
                    ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.mealType,
                  style: const TextStyle(
                    color: orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  food.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: green,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.quantity > 1)
                  Text(
                    '×${item.quantity}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF59616A),
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  '${food.price * item.quantity} Ks',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetCard(BuildContext context) {
    const darkGreen = Color(0xFF123D22);
    const buttonGreen = Color(0xFF17852A);
    return ValueListenableBuilder<int?>(
      valueListenable: GuestBudget.dailyBudget,
      builder: (context, amount, _) {
        final hasBudget = amount != null;
        return LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 520;
            final desktopBudget = constraints.maxWidth >= 600;
            final details = Row(
              children: [
                Image.asset(
                  'assets/img/wallet.png',
                  width: narrow ? 62 : 100,
                  height: narrow ? 62 : 100,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: narrow ? 12 : 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Today's Budget",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hasBudget
                            ? '${GuestBudget.format(amount)} MMK'
                            : 'Set your budget',
                        style: TextStyle(
                          fontSize: narrow ? 21 : 24,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      if (!hasBudget)
                        const Text(
                          'Start planning meals for today.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF344338),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasBudget)
                  IconButton(
                    tooltip: 'Edit Budget',
                    onPressed: () => openBudget(context),
                    icon: const Icon(Icons.edit_outlined, color: darkGreen),
                  ),
              ],
            );
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(narrow ? 16 : 26),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3F9E9), Color(0xFFECF5DC)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: desktopBudget && !hasBudget
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 220,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => openBudget(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Set Daily Budget',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        details,
                        if (!hasBudget) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => openBudget(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Set Daily Budget',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: green,
        fontSize: 23,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _adaptiveRow({required bool desktop, required List<Widget> children}) {
    if (!desktop) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _planCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        constraints: const BoxConstraints(minHeight: 125),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(subtitle, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Three cards stay on one row even on 360px Android screens.
        final compact = constraints.maxWidth < 170;
        final isLoggedIn = context.watch<AuthBloc>().state.isAuthenticated;
        return InkWell(
          onTap: () => _protectedFeature(context, title),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 12,
              vertical: compact ? 10 : 12,
            ),
            decoration: _whiteDecoration(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: compact ? 25 : 32,
                      color: const Color(0xFF29A825),
                    ),
                    SizedBox(height: compact ? 7 : 9),
                    Text(
                      title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 12 : 17,
                        height: 1.1,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (!isLoggedIn) ...[
                      SizedBox(height: compact ? 9 : 10),
                      if (compact)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: orange),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Log In Required',
                              maxLines: 1,
                              style: TextStyle(
                                color: orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        OutlinedButton(
                          onPressed: () => _openLogin(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: orange,
                            side: const BorderSide(color: orange),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Log In Required'),
                        ),
                    ],
                  ],
                ),
                if (isLoggedIn)
                  Positioned(
                    right: 0,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: compact ? 18 : 24,
                      color: const Color(0xFF29A825),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _whiteDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFEAE4DB)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 9,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
}

class _PlanSessionGate extends StatefulWidget {
  const _PlanSessionGate({required this.child});

  final Widget child;

  @override
  State<_PlanSessionGate> createState() => _PlanSessionGateState();
}

class _PlanSessionGateState extends State<_PlanSessionGate> {
  int _requestVersion = 0;
  String? _loadedAccount;

  void _refreshTransferredData() {
    if (HomePage.registrationTransferPending) return;
    final state = context.read<AuthBloc>().state;

    debugPrint(
      'TRANSFER UI REFRESH: '
      'mounted=$mounted, '
      'authenticated=${state.isAuthenticated}, '
      'account=${state.user?.email}',
    );

    if (state.isAuthenticated) {
      _syncSession(state);
    }
  }

  String? _accountKey(AuthState state) {
    if (!state.isAuthenticated) return null;
    return state.user?.email;
  }

  @override
  void initState() {
    super.initState();
    HomePage.transferRefresh.addListener(_refreshTransferredData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSession(context.read<AuthBloc>().state);
    });
  }

  Future<void> _syncSession(AuthState state) async {
    if (HomePage.registrationTransferPending) return;
    final account = _accountKey(state);
    final request = ++_requestVersion;

    if (account == null) {
      _loadedAccount = null;
      GuestBudget.clear();
      return;
    }

    if (_loadedAccount != account) {
      HomePage._savedTodayPlan.value = null;
      HomePage._selectedSection.value = 0;
      // Never show a previous guest/account budget in another account.
      GuestBudget.clear();
    }

    _loadedAccount = account;

    try {
      final api = context.read<ApiClient>();
      // Restore today's authenticated budget independently of meal-plan GET.
      // A missing budget (404) is an expected empty state.
      try {
        final response = await api.get(
          '/budget',
          queryParameters: {'date': _todayDateForSession()},
        );
        if (!mounted || request != _requestVersion) return;
        if (_accountKey(context.read<AuthBloc>().state) != account) return;
        final data = response['data'];
        final budget = data is Map ? data['budget'] : null;
        final amount = budget is Map ? budget['amount'] : null;
        if (amount is num && amount > 0) {
          GuestBudget.save(amount.toInt());
        } else if (amount is String) {
          final parsed = int.tryParse(amount);
          if (parsed != null && parsed > 0) GuestBudget.save(parsed);
        }
      } catch (error, stackTrace) {
        debugPrint('BUDGET GET ERROR (404 means no budget yet): $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (!mounted || request != _requestVersion) return;
      final foods = await FoodRepository(api).getFoods();

      if (!mounted || request != _requestVersion) return;

      final plan = await MealPlanRepository(api)
          .getSavedPlan(DateTime.now(), foods);

      if (!mounted || request != _requestVersion) return;

      if (_accountKey(context.read<AuthBloc>().state) != account) {
        return;
      }

      HomePage._savedTodayPlan.value = plan;
    } catch (error, stackTrace) {
      debugPrint('PLAN GET ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String _todayDateForSession() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void _onAuthChanged(AuthState current) {
    final newAccount = _accountKey(current);

    if (newAccount == null) {
      if (_loadedAccount != null) {
        ++_requestVersion;
        _loadedAccount = null;
        HomePage._savedTodayPlan.value = null;
        HomePage._selectedSection.value = 0;
        GuestBudget.clear();
      }
      return;
    }

    if (_loadedAccount != newAccount) {
      _syncSession(current);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.user?.email != current.user?.email,
      listener: (context, state) => _onAuthChanged(state),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    ++_requestVersion;
    HomePage.transferRefresh.removeListener(_refreshTransferredData);
    super.dispose();
  }
}

class _HomeMealItem {
  const _HomeMealItem(this.mealType, this.food, this.quantity);
  final String mealType;
  final FoodCatalogItem food;
  final int quantity;
}
