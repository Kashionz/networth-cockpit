import 'dart:developer' as developer;

import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../domain/rules/health_rule_projection.dart';
import '../../core/theme/app_colors.dart';
import '../../features/dashboard/models/dashboard_snapshot.dart';
import '../../shared/models/money.dart';
import '../../shared/models/month_key.dart';
import '../../shared/widgets/data_display/allocation_bar.dart';
import '../../shared/widgets/data_display/progress_bar.dart';
import '../mock/mock_dashboard_data.dart';
import 'income_stream_repository.dart';
import '../services/supabase/supabase_client_factory.dart';
import '../services/supabase/supabase_dashboard_service.dart';

export '../../features/dashboard/models/dashboard_snapshot.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final remoteService = client == null
      ? null
      : SupabaseDashboardService(client: client);
  final incomeStreamRepository = ref.watch(incomeStreamRepositoryProvider);

  return DashboardRepositoryImpl(
    remoteService: remoteService,
    incomeStreamRepository: incomeStreamRepository,
  );
});

final dashboardSnapshotProvider = Provider<DashboardSnapshot>(
  (ref) => ref.watch(dashboardRepositoryProvider).fallbackSnapshot,
);

abstract interface class DashboardRepository {
  DashboardSnapshot get fallbackSnapshot;

  Future<DashboardSnapshot> fetchSnapshot();
}

class MockDashboardRepository implements DashboardRepository {
  const MockDashboardRepository();

  @override
  DashboardSnapshot get fallbackSnapshot => mockDashboardSnapshot;

  DashboardSnapshot getSnapshot() => fallbackSnapshot;

  @override
  Future<DashboardSnapshot> fetchSnapshot() async => fallbackSnapshot;
}

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    SupabaseDashboardService? remoteService,
    IncomeStreamRepository? incomeStreamRepository,
  }) : _remoteService = remoteService,
       _incomeStreamRepository =
           incomeStreamRepository ?? MockIncomeStreamRepository(),
       _localSnapshot = mockDashboardSnapshot {
    _localSnapshot = _withUnifiedAttention(_localSnapshot);
  }

  final SupabaseDashboardService? _remoteService;
  final IncomeStreamRepository _incomeStreamRepository;
  DashboardSnapshot _localSnapshot;

  @override
  DashboardSnapshot get fallbackSnapshot => _localSnapshot;

  @override
  Future<DashboardSnapshot> fetchSnapshot() async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote == null || userId == null) {
      return _localSnapshot;
    }

    try {
      final monthlyIncome = await _resolveMonthlyIncome(userId: userId);
      final remoteSnapshot = await _buildRemoteSnapshot(
        remote: remote,
        userId: userId,
        fallback: _localSnapshot,
        monthlyIncome: monthlyIncome,
      );
      if (remoteSnapshot == null) {
        return _localSnapshot;
      }
      _localSnapshot = _withUnifiedAttention(remoteSnapshot);
      return _localSnapshot;
    } catch (error, stackTrace) {
      developer.log(
        'fetchSnapshot remote call failed',
        name: 'DashboardRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return _localSnapshot;
    }
  }

  Future<DashboardSnapshot?> _buildRemoteSnapshot({
    required SupabaseDashboardService remote,
    required String userId,
    required DashboardSnapshot fallback,
    required num monthlyIncome,
  }) async {
    final portfolioSnapshotsFuture = remote
        .fetchLatestPortfolioSnapshotsByUserId(userId, limit: 8);
    final monthlyBudgetsFuture = remote.fetchLatestMonthlyBudgetsByUserId(
      userId,
      limit: 48,
    );
    final holdingsFuture = remote.fetchHoldingsByUserId(userId);
    final assetsFuture = remote.fetchAssetsByUserId(userId);
    final targetAllocationsFuture = remote.fetchTargetAllocationsByUserId(
      userId,
    );
    final openStatementsFuture = remote.fetchOpenCardStatementsByUserId(userId);

    final portfolioSnapshots = await portfolioSnapshotsFuture;
    final monthlyBudgets = await monthlyBudgetsFuture;
    final holdings = await holdingsFuture;
    final assets = await assetsFuture;
    final targetAllocations = await targetAllocationsFuture;
    var statements = await openStatementsFuture;

    if (statements.isEmpty) {
      statements = await remote.fetchLatestCardStatementsByUserId(
        userId,
        limit: 1,
      );
    }

    final hasAnyRemoteRows =
        portfolioSnapshots.isNotEmpty ||
        monthlyBudgets.isNotEmpty ||
        holdings.isNotEmpty ||
        assets.isNotEmpty ||
        targetAllocations.isNotEmpty ||
        statements.isNotEmpty;

    if (!hasAnyRemoteRows) {
      return null;
    }

    final latestBudgetMonth = _latestMonthFromBudgets(monthlyBudgets);
    final latestSnapshotDate = _latestDateFromPortfolioSnapshots(
      portfolioSnapshots,
    );
    final referenceDate =
        latestBudgetMonth ?? latestSnapshotDate ?? DateTime.now();

    final budgetResult = _buildBudgetSummary(
      rows: monthlyBudgets,
      month: referenceDate,
      fallback: fallback.budgetSummary,
    );
    final savingsRate = _resolveSavingsRate(
      budgetResult: budgetResult,
      fallback: fallback.savingsRate,
      monthlyIncome: monthlyIncome,
    );
    final savingsTarget = _resolveSavingsTarget(
      sourceRows: budgetResult.sourceRows,
      fallback: fallback.savingsTarget,
    );

    final netWorthResult = _buildNetWorthSummary(
      portfolioSnapshots: portfolioSnapshots,
      holdings: holdings,
      assets: assets,
      fallback: fallback,
    );

    final allocationSummary = _buildAllocationSummary(
      holdings: holdings,
      assets: assets,
      targetAllocations: targetAllocations,
      fallback: fallback.allocationSummary,
    );

    final statementSummary = _buildStatementSummary(
      statements: statements,
      fallback: fallback.statementSummary,
    );

    final lastSyncedAt = _resolveLastSyncedAt(
      fallback: fallback.lastSyncedAt,
      sources: [
        portfolioSnapshots,
        monthlyBudgets,
        holdings,
        assets,
        targetAllocations,
        statements,
      ],
    );

    return DashboardSnapshot(
      month: MonthKey(referenceDate.year, referenceDate.month),
      savingsRate: savingsRate,
      savingsTarget: savingsTarget,
      netWorth: netWorthResult.netWorth,
      netWorthDelta: netWorthResult.netWorthDelta,
      netWorthTrend: netWorthResult.netWorthTrend,
      budgetSummary: budgetResult.items,
      allocationSummary: allocationSummary,
      attentionItems: fallback.attentionItems,
      statementSummary: statementSummary,
      lastSyncedAt: lastSyncedAt,
    );
  }

  _BudgetSummaryResult _buildBudgetSummary({
    required List<Map<String, dynamic>> rows,
    required DateTime month,
    required List<BudgetSnapshotItem> fallback,
  }) {
    final filtered = rows
        .where((row) {
          final budgetMonth = _parseDate(row['budget_month']);
          return budgetMonth != null &&
              budgetMonth.year == month.year &&
              budgetMonth.month == month.month;
        })
        .toList(growable: false);

    if (filtered.isEmpty) {
      final fallbackLimit = fallback.fold<num>(
        0,
        (sum, item) => sum + item.limit,
      );
      final fallbackUsed = fallback.fold<num>(
        0,
        (sum, item) => sum + item.used,
      );
      return _BudgetSummaryResult(
        items: fallback,
        sourceRows: const [],
        totalLimit: fallbackLimit,
        totalUsed: fallbackUsed,
      );
    }

    final totals = <String, _BudgetAccumulator>{};
    for (final row in filtered) {
      final rawCategory = row['category']?.toString();
      final label = _budgetLabelFromRaw(rawCategory);
      if (label == null) {
        continue;
      }

      final limit = _toNum(row['amount_limit']) ?? 0;
      final used = _toNum(row['spent_amount']) ?? 0;
      final current = totals[label];
      if (current == null) {
        totals[label] = _BudgetAccumulator(limit: limit, used: used);
      } else {
        totals[label] = _BudgetAccumulator(
          limit: current.limit + limit,
          used: current.used + used,
        );
      }
    }

    if (totals.isEmpty) {
      final fallbackLimit = fallback.fold<num>(
        0,
        (sum, item) => sum + item.limit,
      );
      final fallbackUsed = fallback.fold<num>(
        0,
        (sum, item) => sum + item.used,
      );
      return _BudgetSummaryResult(
        items: fallback,
        sourceRows: const [],
        totalLimit: fallbackLimit,
        totalUsed: fallbackUsed,
      );
    }

    final orderedLabels = ['固定', '生活', '彈性'];
    final summary = <BudgetSnapshotItem>[];
    for (final label in orderedLabels) {
      final value = totals[label];
      if (value == null) {
        continue;
      }
      summary.add(
        BudgetSnapshotItem(
          label: label,
          used: value.used,
          limit: value.limit <= 0 ? 1 : value.limit,
          tone: _toneForBudget(used: value.used, limit: value.limit),
        ),
      );
    }

    for (final entry in totals.entries) {
      if (orderedLabels.contains(entry.key)) {
        continue;
      }
      summary.add(
        BudgetSnapshotItem(
          label: entry.key,
          used: entry.value.used,
          limit: entry.value.limit <= 0 ? 1 : entry.value.limit,
          tone: _toneForBudget(
            used: entry.value.used,
            limit: entry.value.limit,
          ),
        ),
      );
    }

    final totalLimit = summary.fold<num>(0, (sum, item) => sum + item.limit);
    final totalUsed = summary.fold<num>(0, (sum, item) => sum + item.used);

    return _BudgetSummaryResult(
      items: summary,
      sourceRows: filtered,
      totalLimit: totalLimit,
      totalUsed: totalUsed,
    );
  }

  _NetWorthSummaryResult _buildNetWorthSummary({
    required List<Map<String, dynamic>> portfolioSnapshots,
    required List<Map<String, dynamic>> holdings,
    required List<Map<String, dynamic>> assets,
    required DashboardSnapshot fallback,
  }) {
    final sortedSnapshots = List<Map<String, dynamic>>.from(portfolioSnapshots)
      ..sort((left, right) {
        final leftDate = _parseDate(left['snapshot_date']) ?? DateTime(1970);
        final rightDate = _parseDate(right['snapshot_date']) ?? DateTime(1970);
        return leftDate.compareTo(rightDate);
      });

    final snapshotValues = <num>[];
    for (final row in sortedSnapshots) {
      final value = _toNum(row['total_value']);
      if (value != null && value > 0) {
        snapshotValues.add(value);
      }
    }

    if (snapshotValues.isNotEmpty) {
      final latest = snapshotValues.last;
      final previous = snapshotValues.length >= 2
          ? snapshotValues[snapshotValues.length - 2]
          : latest;
      final trend = snapshotValues.length >= 2
          ? snapshotValues
          : _scaleTrend(source: fallback.netWorthTrend, targetLatest: latest);
      return _NetWorthSummaryResult(
        netWorth: Money.twd(latest),
        netWorthDelta: Money.twd(latest - previous),
        netWorthTrend: trend,
      );
    }

    final holdingsTotal = _sumHoldingsMarketValue(holdings);
    if (holdingsTotal > 0) {
      return _NetWorthSummaryResult(
        netWorth: Money.twd(holdingsTotal),
        netWorthDelta: fallback.netWorthDelta,
        netWorthTrend: _scaleTrend(
          source: fallback.netWorthTrend,
          targetLatest: holdingsTotal,
        ),
      );
    }

    final assetsTotal = _sumAssetValue(assets);
    if (assetsTotal > 0) {
      return _NetWorthSummaryResult(
        netWorth: Money.twd(assetsTotal),
        netWorthDelta: fallback.netWorthDelta,
        netWorthTrend: _scaleTrend(
          source: fallback.netWorthTrend,
          targetLatest: assetsTotal,
        ),
      );
    }

    return _NetWorthSummaryResult(
      netWorth: fallback.netWorth,
      netWorthDelta: fallback.netWorthDelta,
      netWorthTrend: fallback.netWorthTrend,
    );
  }

  List<AllocationSegment> _buildAllocationSummary({
    required List<Map<String, dynamic>> holdings,
    required List<Map<String, dynamic>> assets,
    required List<Map<String, dynamic>> targetAllocations,
    required List<AllocationSegment> fallback,
  }) {
    final assetsById = <String, Map<String, dynamic>>{
      for (final asset in assets)
        if (asset['id'] != null) asset['id'].toString(): asset,
    };

    final holdingsTotals = <String, num>{};
    for (final holding in holdings) {
      final amount = _toNum(holding['market_value']) ?? 0;
      if (amount <= 0) {
        continue;
      }
      final assetId = holding['asset_id']?.toString();
      final assetType = assetsById[assetId]?['asset_type']?.toString();
      final label = _allocationLabelForAssetType(assetType);
      holdingsTotals[label] = (holdingsTotals[label] ?? 0) + amount;
    }

    if (holdingsTotals.isNotEmpty) {
      return _allocationSegmentsFromTotals(holdingsTotals);
    }

    final targetsTotals = <String, num>{};
    for (final target in targetAllocations) {
      final percentage = _toNum(target['target_percentage']) ?? 0;
      if (percentage <= 0) {
        continue;
      }
      final assetId = target['asset_id']?.toString();
      final assetType = assetsById[assetId]?['asset_type']?.toString();
      final label = _allocationLabelForAssetType(assetType);
      targetsTotals[label] = (targetsTotals[label] ?? 0) + percentage;
    }

    if (targetsTotals.isNotEmpty) {
      return _allocationSegmentsFromTotals(targetsTotals);
    }

    final assetTotals = <String, num>{};
    for (final asset in assets) {
      final metadata = _metadataMap(asset);
      final value = _toNum(metadata['value']) ?? 0;
      if (value <= 0) {
        continue;
      }
      final label = _allocationLabelForAssetType(
        asset['asset_type']?.toString(),
      );
      assetTotals[label] = (assetTotals[label] ?? 0) + value;
    }

    if (assetTotals.isNotEmpty) {
      return _allocationSegmentsFromTotals(assetTotals);
    }

    return fallback;
  }

  List<AllocationSegment> _allocationSegmentsFromTotals(
    Map<String, num> totals,
  ) {
    final positiveTotals = totals.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false);
    if (positiveTotals.isEmpty) {
      return const [];
    }

    final total = positiveTotals.fold<num>(
      0,
      (sum, entry) => sum + entry.value,
    );
    final segments = positiveTotals
        .map((entry) {
          final value = total <= 0 ? 0 : (entry.value / total * 100);
          return AllocationSegment(
            label: entry.key,
            value: value.toDouble(),
            color: _allocationColorForLabel(entry.key),
          );
        })
        .toList(growable: false);

    final sorted = List<AllocationSegment>.from(segments)
      ..sort((left, right) => right.value.compareTo(left.value));
    return sorted;
  }

  DashboardSnapshot _withUnifiedAttention(DashboardSnapshot snapshot) {
    final evaluation = HealthRuleProjection.evaluateDashboardSnapshot(snapshot);
    return DashboardSnapshot(
      month: snapshot.month,
      savingsRate: snapshot.savingsRate,
      savingsTarget: snapshot.savingsTarget,
      netWorth: snapshot.netWorth,
      netWorthDelta: snapshot.netWorthDelta,
      netWorthTrend: snapshot.netWorthTrend,
      budgetSummary: snapshot.budgetSummary,
      allocationSummary: snapshot.allocationSummary,
      attentionItems: [
        AttentionItem(title: evaluation.title, body: evaluation.reason),
      ],
      statementSummary: snapshot.statementSummary,
      lastSyncedAt: snapshot.lastSyncedAt,
    );
  }

  Money _buildStatementSummary({
    required List<Map<String, dynamic>> statements,
    required Money fallback,
  }) {
    if (statements.isEmpty) {
      return fallback;
    }

    var total = 0.0;
    for (final row in statements) {
      total += (_toNum(row['statement_balance']) ?? 0).toDouble();
    }

    if (total <= 0) {
      return fallback;
    }

    return Money.twd(total);
  }

  DateTime _resolveLastSyncedAt({
    required DateTime fallback,
    required List<List<Map<String, dynamic>>> sources,
  }) {
    DateTime? latest;

    for (final rows in sources) {
      for (final row in rows) {
        final candidates = <DateTime?>[
          _parseDateTime(row['updated_at']),
          _parseDateTime(row['created_at']),
          _parseDate(row['snapshot_date']),
          _parseDate(row['budget_month']),
          _parseDate(row['statement_period_end']),
        ];
        for (final candidate in candidates) {
          if (candidate == null) {
            continue;
          }
          if (latest == null || candidate.isAfter(latest)) {
            latest = candidate;
          }
        }
      }
    }

    return latest ?? fallback;
  }

  DateTime? _latestMonthFromBudgets(List<Map<String, dynamic>> rows) {
    DateTime? latest;
    for (final row in rows) {
      final budgetMonth = _parseDate(row['budget_month']);
      if (budgetMonth == null) {
        continue;
      }
      if (latest == null || budgetMonth.isAfter(latest)) {
        latest = budgetMonth;
      }
    }
    return latest;
  }

  DateTime? _latestDateFromPortfolioSnapshots(List<Map<String, dynamic>> rows) {
    DateTime? latest;
    for (final row in rows) {
      final snapshotDate = _parseDate(row['snapshot_date']);
      if (snapshotDate == null) {
        continue;
      }
      if (latest == null || snapshotDate.isAfter(latest)) {
        latest = snapshotDate;
      }
    }
    return latest;
  }

  Future<num> _resolveMonthlyIncome({required String userId}) async {
    final cachedIncome = _incomeStreamRepository.totalMonthlyIncome();
    if (cachedIncome > 0) {
      return cachedIncome;
    }

    try {
      await _incomeStreamRepository.fetchIncomeStreams(userId: userId);
    } catch (error, stackTrace) {
      developer.log(
        'fetchIncomeStreams for dashboard snapshot failed',
        name: 'DashboardRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final refreshedIncome = _incomeStreamRepository.totalMonthlyIncome();
    return refreshedIncome > 0 ? refreshedIncome : 0;
  }

  double _resolveSavingsRate({
    required _BudgetSummaryResult budgetResult,
    required double fallback,
    required num monthlyIncome,
  }) {
    if (monthlyIncome > 0) {
      final rate =
          ((monthlyIncome - budgetResult.totalUsed) / monthlyIncome) * 100;
      return rate.clamp(0, 100).toDouble();
    }

    if (budgetResult.sourceRows.isEmpty || budgetResult.totalLimit <= 0) {
      return fallback;
    }
    final rate =
        ((budgetResult.totalLimit - budgetResult.totalUsed) /
            budgetResult.totalLimit) *
        100;
    return rate.clamp(0, 100).toDouble();
  }

  double _resolveSavingsTarget({
    required List<Map<String, dynamic>> sourceRows,
    required double fallback,
  }) {
    for (final row in sourceRows) {
      final metadata = _metadataMap(row);
      final target =
          _toNum(metadata['target_savings_rate']) ??
          _toNum(metadata['savings_target']) ??
          _toNum(metadata['savings_rate_target']);
      if (target != null && target > 0) {
        return target.toDouble();
      }
    }
    return fallback;
  }

  num _sumHoldingsMarketValue(List<Map<String, dynamic>> rows) {
    var total = 0.0;
    for (final row in rows) {
      final marketValue =
          _toNum(row['market_value']) ??
          _toNum(_metadataMap(row)['market_value']) ??
          0;
      if (marketValue > 0) {
        total += marketValue.toDouble();
      }
    }
    return total;
  }

  num _sumAssetValue(List<Map<String, dynamic>> rows) {
    var total = 0.0;
    for (final row in rows) {
      final metadata = _metadataMap(row);
      final value = _toNum(metadata['value']) ?? 0;
      if (value > 0) {
        total += value.toDouble();
      }
    }
    return total;
  }

  List<num> _scaleTrend({
    required List<num> source,
    required num targetLatest,
  }) {
    if (source.isEmpty || targetLatest <= 0) {
      return source;
    }
    final last = source.last;
    if (last <= 0) {
      return source;
    }
    final scale = targetLatest / last;
    return source
        .map((point) => (point * scale).toDouble())
        .toList(growable: false);
  }

  String _allocationLabelForAssetType(String? raw) {
    final key = raw?.trim().toLowerCase();
    return switch (key) {
      'cash' || 'bank_deposit' => '現金',
      'bond' => '債券',
      _ => '股票',
    };
  }

  ProgressTone _toneForBudget({required num used, required num limit}) {
    if (limit <= 0) {
      return ProgressTone.calm;
    }
    final ratio = used / limit;
    if (ratio >= 1) {
      return ProgressTone.review;
    }
    if (ratio >= 0.85) {
      return ProgressTone.near;
    }
    return ProgressTone.calm;
  }

  String? _budgetLabelFromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final key = raw.trim().toLowerCase();
    return switch (key) {
      'fixed' || '固定' => '固定',
      'living' || '生活' => '生活',
      'flex' || '彈性' || 'discretionary' => '彈性',
      _ => raw.trim(),
    };
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

  DateTime? _parseDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw.toLocal();
    }
    final text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text)?.toLocal();
  }

  DateTime? _parseDate(Object? raw) {
    final text = raw?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }

  Map<String, dynamic> _metadataMap(Map<String, dynamic> row) {
    final metadata = row['metadata'];
    if (metadata is Map) {
      return Map<String, dynamic>.from(metadata);
    }
    return const <String, dynamic>{};
  }
}

class _BudgetSummaryResult {
  const _BudgetSummaryResult({
    required this.items,
    required this.sourceRows,
    required this.totalLimit,
    required this.totalUsed,
  });

  final List<BudgetSnapshotItem> items;
  final List<Map<String, dynamic>> sourceRows;
  final num totalLimit;
  final num totalUsed;
}

class _NetWorthSummaryResult {
  const _NetWorthSummaryResult({
    required this.netWorth,
    required this.netWorthDelta,
    required this.netWorthTrend,
  });

  final Money netWorth;
  final Money netWorthDelta;
  final List<num> netWorthTrend;
}

class _BudgetAccumulator {
  const _BudgetAccumulator({required this.limit, required this.used});

  final num limit;
  final num used;
}

Color _allocationColorForLabel(String label) {
  return switch (label) {
    '股票' => AppColors.assetEquity,
    '債券' => AppColors.assetBond,
    _ => AppColors.assetCash,
  };
}
