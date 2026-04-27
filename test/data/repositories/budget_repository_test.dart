import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/budget_repository.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';

void main() {
  test('budget repository exposes the current month budget model', () {
    final repository = MockBudgetRepository();

    final month = repository.getCurrentMonth();

    expect(month.month, const MonthKey(2026, 4));
    expect(month.categories, hasLength(3));
    expect(month.categories.map((category) => category.type), [
      BudgetCategoryType.fixed,
      BudgetCategoryType.living,
      BudgetCategoryType.flex,
    ]);
    expect(month.categories.map((category) => category.rollover), [
      false,
      false,
      true,
    ]);
    expect(month.largeExpenses, hasLength(2));
    expect(month.largeExpenses.first.title, '家電汰換');
    expect(month.totalBudget.amount, 40000);
    expect(month.totalUsed.amount, 32200);
  });
}
