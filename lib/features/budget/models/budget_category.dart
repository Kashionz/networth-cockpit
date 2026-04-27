import '../../../shared/models/money.dart';

enum BudgetCategoryType { fixed, living, flex }

class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.budgetAmount,
    required this.usedAmount,
    required this.rollover,
  });

  final String id;
  final String name;
  final BudgetCategoryType type;
  final Money budgetAmount;
  final Money usedAmount;
  final bool rollover;

  num get remainingAmount => budgetAmount.amount - usedAmount.amount;
  Money get remainingMoney => Money.twd(remainingAmount);
  double get usageRate =>
      budgetAmount.amount == 0 ? 0 : usedAmount.amount / budgetAmount.amount;
  int get usagePercent => (usageRate * 100).round();
  bool get isNearLimit => usageRate >= 0.8;
  bool get needsReview => usageRate >= 0.95;
}
