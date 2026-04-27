import '../../features/budget/models/budget_category.dart';
import '../../features/budget/models/budget_month.dart';
import '../../shared/models/money.dart';
import '../../shared/models/month_key.dart';

class MockBudgetData {
  const MockBudgetData._();

  static const categories = ['固定', '生活', '彈性'];

  static final currentMonth = BudgetMonth(
    month: const MonthKey(2026, 4),
    categories: const [
      BudgetCategory(
        id: 'budget-fixed',
        name: '固定',
        type: BudgetCategoryType.fixed,
        budgetAmount: Money.twd(18000),
        usedAmount: Money.twd(17200),
        rollover: false,
      ),
      BudgetCategory(
        id: 'budget-living',
        name: '生活',
        type: BudgetCategoryType.living,
        budgetAmount: Money.twd(15000),
        usedAmount: Money.twd(10800),
        rollover: false,
      ),
      BudgetCategory(
        id: 'budget-flex',
        name: '彈性',
        type: BudgetCategoryType.flex,
        budgetAmount: Money.twd(7000),
        usedAmount: Money.twd(4200),
        rollover: true,
      ),
    ],
    largeExpenses: [
      LargeExpense(
        id: 'large-appliance',
        title: '家電汰換',
        amount: const Money.twd(5200),
        categoryType: BudgetCategoryType.flex,
        recordedAt: DateTime(2026, 4, 8),
      ),
      LargeExpense(
        id: 'large-insurance',
        title: '年度保險',
        amount: const Money.twd(9000),
        categoryType: BudgetCategoryType.fixed,
        recordedAt: DateTime(2026, 4, 15),
      ),
    ],
  );
}
