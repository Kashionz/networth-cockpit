import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/features/budget/controllers/budget_controller.dart';
import 'package:networth_cockpit/features/budget/models/budget_category.dart';

void main() {
  test('budget controller provides current month budget data', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final month = container.read(budgetControllerProvider);

    expect(month.categories.map((category) => category.type), [
      BudgetCategoryType.fixed,
      BudgetCategoryType.living,
      BudgetCategoryType.flex,
    ]);
    expect(month.categories.last.rollover, isTrue);
    expect(month.largeExpenses.map((expense) => expense.title), [
      '家電汰換',
      '年度保險',
    ]);
  });

  test('budget history controller keeps recent month summaries', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final history = container.read(budgetHistoryControllerProvider);

    expect(history, hasLength(4));
    expect(history.first.month.year, 2026);
    expect(history.first.month.month, 4);
    expect(history.first.categories.map((category) => category.type), [
      BudgetCategoryType.fixed,
      BudgetCategoryType.living,
      BudgetCategoryType.flex,
    ]);
    expect(history[1].largeExpenses, isNotEmpty);
  });

  test('budget month detail provider can resolve a history month', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final history = container.read(budgetHistoryControllerProvider);
    final selectedMonth = history[2].month;
    final detail = container.read(budgetMonthDetailProvider(selectedMonth));

    expect(detail, isNotNull);
    expect(detail!.month, selectedMonth);
    expect(detail.categories.last.rollover, isTrue);
  });
}
