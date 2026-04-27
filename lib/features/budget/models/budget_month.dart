import '../../../shared/models/money.dart';
import '../../../shared/models/month_key.dart';
import 'budget_category.dart';

class BudgetMonth {
  const BudgetMonth({
    required this.month,
    required this.categories,
    required this.largeExpenses,
  });

  final MonthKey month;
  final List<BudgetCategory> categories;
  final List<LargeExpense> largeExpenses;

  Money get totalBudget => Money.twd(
    categories.fold<num>(
      0,
      (total, category) => total + category.budgetAmount.amount,
    ),
  );

  Money get totalUsed => Money.twd(
    categories.fold<num>(
      0,
      (total, category) => total + category.usedAmount.amount,
    ),
  );

  Money get totalRemaining => Money.twd(totalBudget.amount - totalUsed.amount);
  double get totalUsageRate =>
      totalBudget.amount == 0 ? 0 : totalUsed.amount / totalBudget.amount;
  int get totalUsagePercent => (totalUsageRate * 100).round();

  BudgetCategory categoryOf(BudgetCategoryType type) {
    return categories.firstWhere((category) => category.type == type);
  }
}

class LargeExpense {
  const LargeExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryType,
    required this.recordedAt,
  });

  final String id;
  final String title;
  final Money amount;
  final BudgetCategoryType categoryType;
  final DateTime recordedAt;
}
