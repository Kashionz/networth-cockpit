import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/budget_repository.dart';
import '../../../shared/models/money.dart';
import '../../../shared/models/month_key.dart';

final budgetControllerProvider = Provider<BudgetMonth>(
  (ref) => ref.watch(budgetMonthProvider),
);

final budgetHistoryControllerProvider = Provider<List<BudgetMonth>>((ref) {
  final currentMonth = ref.watch(budgetControllerProvider);
  final currentKey = currentMonth.month;

  return [
    currentMonth,
    _buildHistoryMonth(
      month: _minusMonths(currentKey, 1),
      fixedUsed: 17800,
      livingUsed: 13300,
      flexUsed: 6800,
      largeExpenses: [
        LargeExpense(
          id: 'large-family-trip-2026-03',
          title: '家庭旅行交通',
          amount: const Money.twd(8400),
          categoryType: BudgetCategoryType.flex,
          recordedAt: DateTime(2026, 3, 12),
        ),
        LargeExpense(
          id: 'large-car-insurance-2026-03',
          title: '汽車保險續約',
          amount: const Money.twd(7600),
          categoryType: BudgetCategoryType.fixed,
          recordedAt: DateTime(2026, 3, 22),
        ),
      ],
    ),
    _buildHistoryMonth(
      month: _minusMonths(currentKey, 2),
      fixedUsed: 17500,
      livingUsed: 12000,
      flexUsed: 5100,
      largeExpenses: [
        LargeExpense(
          id: 'large-phone-2026-02',
          title: '手機換新',
          amount: const Money.twd(10800),
          categoryType: BudgetCategoryType.flex,
          recordedAt: DateTime(2026, 2, 6),
        ),
      ],
    ),
    _buildHistoryMonth(
      month: _minusMonths(currentKey, 3),
      fixedUsed: 17600,
      livingUsed: 14100,
      flexUsed: 3900,
      largeExpenses: [
        LargeExpense(
          id: 'large-checkup-2026-01',
          title: '年度健檢',
          amount: const Money.twd(5600),
          categoryType: BudgetCategoryType.living,
          recordedAt: DateTime(2026, 1, 18),
        ),
        LargeExpense(
          id: 'large-ac-maintenance-2026-01',
          title: '冷氣保養',
          amount: const Money.twd(5100),
          categoryType: BudgetCategoryType.fixed,
          recordedAt: DateTime(2026, 1, 25),
        ),
      ],
    ),
  ];
});

final budgetMonthDetailProvider = Provider.family<BudgetMonth?, MonthKey>((
  ref,
  month,
) {
  final history = ref.watch(budgetHistoryControllerProvider);
  for (final item in history) {
    if (item.month == month) {
      return item;
    }
  }
  return null;
});

BudgetMonth _buildHistoryMonth({
  required MonthKey month,
  required num fixedUsed,
  required num livingUsed,
  required num flexUsed,
  required List<LargeExpense> largeExpenses,
}) {
  return BudgetMonth(
    month: month,
    categories: [
      _buildCategory(
        month: month,
        type: BudgetCategoryType.fixed,
        budgetAmount: 18000,
        usedAmount: fixedUsed,
        rollover: false,
      ),
      _buildCategory(
        month: month,
        type: BudgetCategoryType.living,
        budgetAmount: 15000,
        usedAmount: livingUsed,
        rollover: false,
      ),
      _buildCategory(
        month: month,
        type: BudgetCategoryType.flex,
        budgetAmount: 7000,
        usedAmount: flexUsed,
        rollover: true,
      ),
    ],
    largeExpenses: largeExpenses,
  );
}

BudgetCategory _buildCategory({
  required MonthKey month,
  required BudgetCategoryType type,
  required num budgetAmount,
  required num usedAmount,
  required bool rollover,
}) {
  final label = switch (type) {
    BudgetCategoryType.fixed => '固定',
    BudgetCategoryType.living => '生活',
    BudgetCategoryType.flex => '彈性',
  };

  return BudgetCategory(
    id: 'budget-${month.year}-${month.month}-${type.name}',
    name: label,
    type: type,
    budgetAmount: Money.twd(budgetAmount),
    usedAmount: Money.twd(usedAmount),
    rollover: rollover,
  );
}

MonthKey _minusMonths(MonthKey month, int months) {
  final totalMonths = month.year * 12 + month.month - 1 - months;
  return MonthKey(totalMonths ~/ 12, totalMonths % 12 + 1);
}
