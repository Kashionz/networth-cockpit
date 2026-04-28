import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../features/budget/models/budget_category.dart';
import '../../features/budget/models/budget_month.dart';
import '../../shared/models/money.dart';
import '../../shared/models/month_key.dart';
import '../mock/mock_budget_data.dart';
import '../services/supabase/supabase_budget_service.dart';
import '../services/supabase/supabase_client_factory.dart';

export '../../features/budget/models/budget_category.dart';
export '../../features/budget/models/budget_month.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final remoteService = client == null
      ? null
      : SupabaseBudgetService(client: client);
  return BudgetRepositoryImpl(remoteService: remoteService);
});

final budgetMonthProvider = Provider<BudgetMonth>(
  (ref) => ref.watch(budgetRepositoryProvider).getCurrentMonth(),
);

abstract interface class BudgetRepository {
  BudgetMonth getCurrentMonth();
}

abstract interface class RefreshableBudgetRepository implements BudgetRepository {
  Future<BudgetMonth> fetchCurrentMonth();
}

class BudgetRepositoryImpl implements RefreshableBudgetRepository {
  BudgetRepositoryImpl({SupabaseBudgetService? remoteService})
    : _remoteService = remoteService,
      _localMonth = MockBudgetData.currentMonth;

  final SupabaseBudgetService? _remoteService;
  BudgetMonth _localMonth;

  @override
  BudgetMonth getCurrentMonth() => _snapshot(_localMonth);

  @override
  Future<BudgetMonth> fetchCurrentMonth() async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote == null || userId == null) {
      return _snapshot(_localMonth);
    }

    final now = DateTime.now();
    final fallbackMonth = MonthKey.fromDate(now);
    final monthStartUtc = DateTime.utc(now.year, now.month, 1);
    final nextMonthStartUtc = DateTime.utc(now.year, now.month + 1, 1);

    try {
      final budgetRows = await remote.fetchMonthlyBudgetsByUserId(
        userId,
        monthStart: monthStartUtc,
      );
      if (budgetRows.isEmpty) {
        return _snapshot(_localMonth);
      }

      final month = _resolveMonthKey(budgetRows, fallback: fallbackMonth);
      final categories = _buildCategories(
        month: month,
        rows: budgetRows,
        fallbackCategories: _localMonth.categories,
      );

      List<Map<String, dynamic>> transactionRows = const [];
      try {
        transactionRows = await remote.fetchTransactionsByUserIdWithinRange(
          userId,
          startInclusive: monthStartUtc,
          endExclusive: nextMonthStartUtc,
        );
      } catch (error, stackTrace) {
        developer.log(
          'fetchCurrentMonth transactions remote call failed',
          name: 'BudgetRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }

      final largeExpenses = _resolveLargeExpenses(
        month: month,
        rows: transactionRows,
        categories: categories,
        fallbackExpenses: _localMonth.largeExpenses,
      );

      _localMonth = BudgetMonth(
        month: month,
        categories: categories,
        largeExpenses: largeExpenses,
      );
      return _snapshot(_localMonth);
    } catch (error, stackTrace) {
      developer.log(
        'fetchCurrentMonth remote call failed',
        name: 'BudgetRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return _snapshot(_localMonth);
    }
  }

  BudgetMonth _snapshot(BudgetMonth month) {
    return BudgetMonth(
      month: month.month,
      categories: List<BudgetCategory>.unmodifiable(month.categories),
      largeExpenses: List<LargeExpense>.unmodifiable(month.largeExpenses),
    );
  }

  MonthKey _resolveMonthKey(
    List<Map<String, dynamic>> rows, {
    required MonthKey fallback,
  }) {
    for (final row in rows) {
      final parsed = _parseDateTime(row['budget_month']);
      if (parsed != null) {
        return MonthKey(parsed.year, parsed.month);
      }
    }
    return fallback;
  }

  List<BudgetCategory> _buildCategories({
    required MonthKey month,
    required List<Map<String, dynamic>> rows,
    required List<BudgetCategory> fallbackCategories,
  }) {
    final fallbackMap = {
      for (final category in fallbackCategories) category.type: category,
    };
    final rowMap = <BudgetCategoryType, Map<String, dynamic>>{};

    for (final row in rows) {
      final type = _categoryTypeFromRaw(row['category']?.toString());
      if (type == null) {
        continue;
      }
      rowMap[type] = row;
    }

    return List<BudgetCategory>.unmodifiable([
      for (final type in BudgetCategoryType.values)
        _buildCategoryForType(
          month: month,
          type: type,
          row: rowMap[type],
          fallback: fallbackMap[type] ?? _defaultCategory(type, month),
        ),
    ]);
  }

  BudgetCategory _buildCategoryForType({
    required MonthKey month,
    required BudgetCategoryType type,
    required Map<String, dynamic>? row,
    required BudgetCategory fallback,
  }) {
    final limit = _toNum(row?['amount_limit']) ?? fallback.budgetAmount.amount;
    final spent = _toNum(row?['spent_amount']) ?? fallback.usedAmount.amount;
    final rollover = _toBool(row?['rollover_enabled']) ?? fallback.rollover;
    final id =
        row?['id']?.toString() ??
        'budget-${month.year}-${month.month}-${type.name}';

    return BudgetCategory(
      id: id,
      name: _labelForType(type),
      type: type,
      budgetAmount: Money.twd(limit),
      usedAmount: Money.twd(spent),
      rollover: rollover,
    );
  }

  BudgetCategory _defaultCategory(BudgetCategoryType type, MonthKey month) {
    final seed = MockBudgetData.currentMonth.categories.firstWhere(
      (category) => category.type == type,
    );
    return BudgetCategory(
      id: 'budget-${month.year}-${month.month}-${type.name}',
      name: _labelForType(type),
      type: type,
      budgetAmount: seed.budgetAmount,
      usedAmount: seed.usedAmount,
      rollover: seed.rollover,
    );
  }

  List<LargeExpense> _resolveLargeExpenses({
    required MonthKey month,
    required List<Map<String, dynamic>> rows,
    required List<BudgetCategory> categories,
    required List<LargeExpense> fallbackExpenses,
  }) {
    final fallback = _fallbackExpensesForMonth(month, fallbackExpenses);
    final candidates = _buildExpenseCandidates(month: month, rows: rows);
    if (candidates.isEmpty) {
      return fallback;
    }

    final totalBudget = categories.fold<num>(
      0,
      (sum, category) => sum + category.budgetAmount.amount,
    );
    final dynamicThreshold = (totalBudget * 0.12).round();
    final threshold = dynamicThreshold < 3000 ? 3000 : dynamicThreshold;

    final selected = candidates
        .where((candidate) => candidate.amount >= threshold)
        .take(5)
        .toList(growable: false);
    if (selected.isEmpty) {
      return fallback;
    }

    // 高額支出資料過少時，沿用 fallback，避免 UI 顯示過度稀疏。
    if (selected.length < 2 && fallback.isNotEmpty) {
      return fallback;
    }

    return List<LargeExpense>.unmodifiable([
      for (final candidate in selected)
        LargeExpense(
          id: candidate.id,
          title: candidate.title,
          amount: Money(candidate.amount, currencyCode: candidate.currencyCode),
          categoryType: candidate.categoryType,
          recordedAt: candidate.recordedAt,
        ),
    ]);
  }

  List<_ExpenseCandidate> _buildExpenseCandidates({
    required MonthKey month,
    required List<Map<String, dynamic>> rows,
  }) {
    final results = <_ExpenseCandidate>[];

    for (final row in rows) {
      final occurredAt = _parseDateTime(row['occurred_at'])?.toLocal();
      if (occurredAt == null) {
        continue;
      }
      if (occurredAt.year != month.year || occurredAt.month != month.month) {
        continue;
      }
      if (!_isExpenseRow(row)) {
        continue;
      }

      final amount = _toNum(row['amount'])?.abs();
      if (amount == null || amount <= 0) {
        continue;
      }

      final categoryType =
          _categoryTypeFromRaw(row['category']?.toString()) ??
          BudgetCategoryType.living;
      final currencyCode = _normalizeCurrencyCode(row['currency_code']);
      final id =
          row['id']?.toString() ??
          'large-${occurredAt.microsecondsSinceEpoch}-${amount.toInt()}';

      results.add(
        _ExpenseCandidate(
          id: id,
          title: _resolveExpenseTitle(row),
          amount: amount,
          currencyCode: currencyCode,
          categoryType: categoryType,
          recordedAt: occurredAt,
        ),
      );
    }

    results.sort((a, b) {
      final byAmount = b.amount.compareTo(a.amount);
      if (byAmount != 0) {
        return byAmount;
      }
      return b.recordedAt.compareTo(a.recordedAt);
    });
    return results;
  }

  bool _isExpenseRow(Map<String, dynamic> row) {
    final transactionType = row['transaction_type']?.toString().trim().toLowerCase();
    if (transactionType == 'expense') {
      return true;
    }
    if (transactionType == 'income') {
      return false;
    }

    final direction = row['direction']?.toString().trim().toLowerCase();
    if (direction == 'outflow' || direction == 'debit') {
      return true;
    }
    if (direction == 'inflow' || direction == 'credit') {
      return false;
    }

    final amount = _toNum(row['amount']);
    return amount != null && amount < 0;
  }

  String _resolveExpenseTitle(Map<String, dynamic> row) {
    final merchant = row['merchant']?.toString().trim();
    if (merchant != null && merchant.isNotEmpty) {
      return merchant;
    }

    final note = row['note']?.toString().trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }

    final category = row['category']?.toString().trim();
    if (category != null && category.isNotEmpty) {
      return category;
    }

    return '未分類支出';
  }

  List<LargeExpense> _fallbackExpensesForMonth(
    MonthKey month,
    List<LargeExpense> source,
  ) {
    final fallbackSource =
        source.isEmpty ? MockBudgetData.currentMonth.largeExpenses : source;

    final maxDay = DateTime(month.year, month.month + 1, 0).day;
    return List<LargeExpense>.unmodifiable([
      for (final expense in fallbackSource)
        LargeExpense(
          id: '${expense.id}-${month.year}-${month.month}',
          title: expense.title,
          amount: expense.amount,
          categoryType: expense.categoryType,
          recordedAt: DateTime(
            month.year,
            month.month,
            expense.recordedAt.day > maxDay ? maxDay : expense.recordedAt.day,
          ),
        ),
    ]);
  }

  BudgetCategoryType? _categoryTypeFromRaw(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    return switch (normalized) {
      'fixed' || '固定' || 'essential' || 'essentials' => BudgetCategoryType.fixed,
      'living' || '生活' || 'daily' || 'needs' => BudgetCategoryType.living,
      'flex' || '彈性' || 'flexible' || 'discretionary' => BudgetCategoryType.flex,
      _ => null,
    };
  }

  String _labelForType(BudgetCategoryType type) => switch (type) {
    BudgetCategoryType.fixed => '固定',
    BudgetCategoryType.living => '生活',
    BudgetCategoryType.flex => '彈性',
  };

  String _normalizeCurrencyCode(Object? raw) {
    final value = raw?.toString().trim().toUpperCase();
    if (value == null || value.isEmpty) {
      return 'TWD';
    }
    return value;
  }

  DateTime? _parseDateTime(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  num? _toNum(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString());
  }

  bool? _toBool(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return null;
  }
}

class _ExpenseCandidate {
  const _ExpenseCandidate({
    required this.id,
    required this.title,
    required this.amount,
    required this.currencyCode,
    required this.categoryType,
    required this.recordedAt,
  });

  final String id;
  final String title;
  final num amount;
  final String currencyCode;
  final BudgetCategoryType categoryType;
  final DateTime recordedAt;
}

class MockBudgetRepository implements RefreshableBudgetRepository {
  const MockBudgetRepository();

  @override
  BudgetMonth getCurrentMonth() => MockBudgetData.currentMonth;

  @override
  Future<BudgetMonth> fetchCurrentMonth() async => getCurrentMonth();
}
