import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/budget/models/budget_month.dart';
import '../mock/mock_budget_data.dart';

export '../../features/budget/models/budget_category.dart';
export '../../features/budget/models/budget_month.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => const MockBudgetRepository(),
);

final budgetMonthProvider = Provider<BudgetMonth>(
  (ref) => ref.watch(budgetRepositoryProvider).getCurrentMonth(),
);

abstract interface class BudgetRepository {
  BudgetMonth getCurrentMonth();
}

class MockBudgetRepository implements BudgetRepository {
  const MockBudgetRepository();

  @override
  BudgetMonth getCurrentMonth() => MockBudgetData.currentMonth;
}
