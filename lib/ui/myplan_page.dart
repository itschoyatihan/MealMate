import 'package:flutter/material.dart';

import 'auto_models.dart';
import 'manual_models.dart';
import 'foods_page.dart';
import 'guest_budget.dart';
import 'package:flutter/foundation.dart';

/// My Plan is a presentation page. Home owns the single saved plan and
/// supplies navigation callbacks during the integration step.
class MyPlanPage extends StatelessWidget {
  const MyPlanPage({
    super.key,
    required this.savedPlan,
    required this.onChooseAutomatic,
    required this.onChooseManual,
    required this.onEdit,
    required this.onDelete,
    this.onBack,
  });

  final ValueListenable<Object?> savedPlan;
  final VoidCallback onChooseAutomatic;
  final VoidCallback onChooseManual;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final VoidCallback? onBack;

  static const green = Color(0xFF084B2B);
  static const orange = Color(0xFFF47A12);
  static const cream = Color(0xFFFFFBF3);
  static const paleGreen = Color(0xFFEDF8E8);

  bool _today(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _dateLabel(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _money(int amount) => '${GuestBudget.format(amount)} MMK';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: green),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'My Meal Plan',
          style: TextStyle(color: green, fontWeight: FontWeight.w800),
        ),
      ),
      body: ValueListenableBuilder<Object?>(
        valueListenable: savedPlan,
        builder: (context, plan, _) {
          final valid =
              (plan is AutoPlan && _today(plan.date)) ||
              (plan is ManualPlan && _today(plan.date));
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: valid ? _savedContent(context, plan!) : _emptyContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 90),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F2E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'No Meal Plan Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: green,
              fontWeight: FontWeight.w800,
              fontSize: 27,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'You haven’t saved a meal plan for today.\nLet’s create one!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF565656),
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 64),
          const Text(
            'Choose Your Plan',
            style: TextStyle(
              color: green,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          _choice(
            'Automatic Meal Plan',
            'Get a budget-friendly meal\nplan for today.',
            orange,
            const Color(0xFFFFF6E5),
            onChooseAutomatic,
          ),
          const SizedBox(height: 16),
          _choice(
            'Manual Meal Plan',
            'Choose your own meals\nfrom the food catalog.',
            const Color(0xFF16842C),
            paleGreen,
            onChooseManual,
          ),
        ],
      ),
    );
  }

  Widget _choice(
    String title,
    String description,
    Color accent,
    Color background,
    VoidCallback action,
  ) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 21),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Color(0xFF525252),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: accent, size: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _savedContent(BuildContext context, Object plan) {
    final isAutomatic = plan is AutoPlan;
    final date = plan is AutoPlan ? plan.date : (plan as ManualPlan).date;
    final total = plan is AutoPlan ? plan.total : (plan as ManualPlan).total;
    final foods = <_PlanFood>[];
    if (plan is AutoPlan) {
      for (final type in MealType.values) {
        final food = plan.meals[type];
        if (food != null) foods.add(_PlanFood(type.label, food, 1));
      }
    } else if (plan is ManualPlan) {
      for (final type in MealType.values) {
        for (final item in plan.meals[type] ?? <ManualItem>[]) {
          foods.add(_PlanFood(type.label, item.food, item.quantity));
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: paleGreen,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today’s Meal Plan',
                          style: TextStyle(
                            fontSize: 23,
                            color: green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _dateLabel(date),
                          style: const TextStyle(
                            color: Color(0xFF646464),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15902C),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      isAutomatic ? 'Automatic' : 'Manual',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ValueListenableBuilder<int?>(
                valueListenable: GuestBudget.dailyBudget,
                builder: (context, amount, _) {
                  final budget = amount ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        _metric('Today’s Budget', _money(budget)),
                        Container(
                          height: 43,
                          width: 1,
                          color: const Color(0xFFDDDDDD),
                        ),
                        _metric('Plan Total', _money(total)),
                        Container(
                          height: 43,
                          width: 1,
                          color: const Color(0xFFDDDDDD),
                        ),
                        _metric(
                          'Remaining',
                          _money(budget - total),
                          highlight: budget - total >= 0,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final item in foods) ...[
          _foodCard(item),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Meal Plan'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF07842A),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Today’s Plan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD5212A),
              side: const BorderSide(color: Color(0xFFD5212A)),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 35),
      ],
    );
  }

  Widget _metric(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: green,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: highlight
                      ? const Color(0xFF0B8C28)
                      : const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodCard(_PlanFood item) {
    final image = item.food.imagePath;
    final Color badgeColor = switch (item.meal) {
      'Breakfast' => const Color(0xFFFFE9D3),
      'Lunch' => const Color(0xFFE5F7DF),
      'Snacks' => const Color(0xFFFFF0D8),
      _ => const Color(0xFFEDE8FF),
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 70,
              height: 70,
              child: image == null || image.isEmpty
                  ? const ColoredBox(
                      color: paleGreen,
                      child: Icon(Icons.restaurant, color: green),
                    )
                  : Image.asset(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                            color: paleGreen,
                            child: Icon(Icons.restaurant, color: green),
                          ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    item.meal,
                    style: const TextStyle(
                      fontSize: 12,
                      color: green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.food.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.quantity > 1)
                  Text(
                    '×${item.quantity}',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            flex: 0,
            child: Text(
              _money(item.food.price * item.quantity),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Today’s Plan?'),
        content: const Text(
          'Delete the saved meal plan for today? Your daily budget will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD5212A),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await onDelete();
    }
  }
}

class _PlanFood {
  const _PlanFood(this.meal, this.food, this.quantity);
  final String meal;
  final FoodCatalogItem food;
  final int quantity;
}
