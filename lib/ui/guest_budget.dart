import 'package:flutter/foundation.dart';

/// Temporary daily budget for MealMate Guest Mode.
/// Shared across pages while the app is running; no database required.
/// This value resets when the app is fully restarted.
class GuestBudget {
  GuestBudget._();

  static final ValueNotifier<int?> dailyBudget = ValueNotifier<int?>(null);

  static int? get amount => dailyBudget.value;
  static bool get hasBudget => amount != null;

  static void save(int amount) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Budget must be positive');
    }
    dailyBudget.value = amount;
  }

  static void clear() => dailyBudget.value = null;

  static String format(int amount) => amount.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
}
