import 'package:flutter/material.dart';

import 'set_budget.dart';
import 'guest_budget.dart';

/// Budget confirmation screen for Windows and Android.
///
/// Navigation:
/// - Edit Budget -> SetBudgetPage (same page used for first-time entry).
/// - Automatic / Manual -> caller-supplied page builders.
/// - Back to Home -> pops this screen and returns the latest budget to Home.
///
/// The calling Home page should await `Navigator.push<int>(...)` and update
/// its budget card from the returned amount. No database is required.
class BudgetSavePage extends StatefulWidget {
  final int budget;
  final WidgetBuilder? automaticPageBuilder;
  final WidgetBuilder? manualPageBuilder;
  final Future<bool> Function(int amount)? onBudgetChanged;

  const BudgetSavePage({
    super.key,
    required this.budget,
    this.automaticPageBuilder,
    this.manualPageBuilder,
    this.onBudgetChanged,
  });

  @override
  State<BudgetSavePage> createState() => _BudgetSavePageState();
}

class _BudgetSavePageState extends State<BudgetSavePage> {
  static const _dark = Color(0xFF174B27);
  static const _green = Color(0xFF329B19);
  static const _orange = Color(0xFFFF9D12);
  static const _cream = Color(0xFFFFFCF7);
  late int _budget;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
  }

  String _money(int amount) => amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  Future<void>_edit() async {
    final updated = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => SetBudgetPage(
          initialBudget: _budget,
          onSave: widget.onBudgetChanged,
        ),
      ),
    );

    if (!mounted || updated == null) return;

    if (widget.onBudgetChanged == null) {
      GuestBudget.save(updated);
    }

    setState(() {
      _budget = updated;
    });
  }

  void _home() => Navigator.of(context).pop(_budget);

  void _openPlan(WidgetBuilder? builder, String planName) {
    if (builder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$planName page is not connected yet.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return PopScope<int>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _home();
      },
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Back to Home',
            icon: const Icon(Icons.arrow_back_rounded, color: _dark),
            onPressed: _home,
          ),
          title: const Text(
            'MealMate',
            style: TextStyle(color: _dark, fontWeight: FontWeight.w800),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 22,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 620 : 500),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF75D72B), Color(0xFF2FA718)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 72,
                            color: Colors.white,
                          ),
                        ),
                        const Positioned(
                          right: -28,
                          top: -14,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 35,
                            color: _orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Budget Save!',
                      style: TextStyle(
                        color: _dark,
                        fontSize: isMobile ? 29 : 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your daily budget is',
                      style: TextStyle(fontSize: 19),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: isMobile ? double.infinity : 300,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F7C7),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        '${_money(_budget)} Ks',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          color: _dark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    OutlinedButton.icon(
                      onPressed: () => _edit(),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Budget'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _dark,
                        side: const BorderSide(color: _green, width: 1.5),
                        minimumSize: const Size(240, 49),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'What would you like to do next?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 23),
                    _planCard(
                      title: 'Automatic Meal Plan',
                      subtitle: 'Get a budget-friendly\nmeal plan for today',
                      icon: Icons.auto_awesome_rounded,
                      iconColor: _orange,
                      background: const Color(0xFFFFF0DA),
                      onTap: () => _openPlan(
                        widget.automaticPageBuilder,
                        'Automatic Meal Plan',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _planCard(
                      title: 'Manual Meal Plan',
                      subtitle: 'Choose your own meals\nfrom the catalog',
                      icon: Icons.restaurant_rounded,
                      iconColor: _green,
                      background: const Color(0xFFF0F8E4),
                      onTap: () => _openPlan(
                        widget.manualPageBuilder,
                        'Manual Meal Plan',
                      ),
                    ),
                    const SizedBox(height: 45),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _home,
                        icon: const Icon(Icons.home_rounded, size: 26),
                        label: const Text('Back to Home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _dark,
                          side: const BorderSide(color: _green, width: 1.5),
                          textStyle: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 65),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 43, color: iconColor),
              const SizedBox(width: 21),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 15, height: 1.35),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 30, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
