import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../features/insights/models/monthly_insight.dart';
import '../../shared/models/month_key.dart';
import '../../shared/widgets/data_display/progress_bar.dart';
import '../services/ai/l2_analysis_client.dart';
import '../services/supabase/supabase_client_factory.dart';
import '../services/supabase/supabase_insights_service.dart';
import 'dashboard_repository.dart';
import 'income_stream_repository.dart';

const _monthlyReportInsightType = 'monthly_report';

final monthlyReportRepositoryProvider = Provider<MonthlyReportRepository>((
  ref,
) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final remoteService = client == null
      ? null
      : SupabaseInsightsService(client: client);
  final dashboardRepository = ref.watch(dashboardRepositoryProvider);
  final incomeStreamRepository = ref.watch(incomeStreamRepositoryProvider);
  final l2Client = ref.watch(l2AnalysisClientProvider);

  return MonthlyReportRepositoryImpl(
    remoteService: remoteService,
    dashboardRepository: dashboardRepository,
    incomeStreamRepository: incomeStreamRepository,
    l2AnalysisClient: l2Client,
  );
});

abstract interface class MonthlyReportRepository {
  List<MonthlyReportRecord> get fallbackReports;

  Future<List<MonthlyReportRecord>> fetchReports({bool ensureCurrentMonth});
}

enum MonthlyReportSource { backend, fallback }

class MonthlyReportRecord {
  const MonthlyReportRecord({
    required this.insight,
    required this.source,
    required this.statusMessage,
  });

  final MonthlyInsight insight;
  final MonthlyReportSource source;
  final String statusMessage;

  MonthKey get month => insight.month;
  bool get usedFallback => source == MonthlyReportSource.fallback;
}

class MonthlyReportRepositoryImpl implements MonthlyReportRepository {
  MonthlyReportRepositoryImpl({
    SupabaseInsightsService? remoteService,
    required DashboardRepository dashboardRepository,
    IncomeStreamRepository? incomeStreamRepository,
    required L2AnalysisClient l2AnalysisClient,
    DateTime Function()? now,
    List<MonthlyReportRecord>? seedReports,
  }) : _remoteService = remoteService,
       _dashboardRepository = dashboardRepository,
       _incomeStreamRepository =
           incomeStreamRepository ?? MockIncomeStreamRepository(),
       _l2AnalysisClient = l2AnalysisClient,
       _now = now ?? DateTime.now,
       _localReports = List<MonthlyReportRecord>.from(seedReports ?? const []) {
    if (_localReports.isEmpty) {
      final month = MonthKey.fromDate(_now());
      _localReports = [
        MonthlyReportRecord(
          insight: _buildSeedInsight(
            snapshot: _dashboardRepository.fallbackSnapshot,
            month: month,
          ),
          source: MonthlyReportSource.fallback,
          statusMessage: '尚未連線分析服務，先使用本地解讀。',
        ),
      ];
    } else {
      _localReports = _mergeReports(
        primary: _localReports,
        secondary: const [],
      );
    }
  }

  final SupabaseInsightsService? _remoteService;
  final DashboardRepository _dashboardRepository;
  final IncomeStreamRepository _incomeStreamRepository;
  final L2AnalysisClient _l2AnalysisClient;
  final DateTime Function() _now;
  List<MonthlyReportRecord> _localReports;

  @override
  List<MonthlyReportRecord> get fallbackReports =>
      List<MonthlyReportRecord>.unmodifiable(_localReports);

  @override
  Future<List<MonthlyReportRecord>> fetchReports({
    bool ensureCurrentMonth = true,
  }) async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote == null || userId == null) {
      if (ensureCurrentMonth) {
        await _ensureCurrentMonthReport();
      }
      return fallbackReports;
    }

    try {
      final rows = await remote.fetchMonthlyReportInsightsByUserId(userId);
      final remoteReports = _parseRemoteReports(rows);
      final currentMonth = MonthKey.fromDate(_now());
      final hasCurrentMonthInRemote = remoteReports.any(
        (report) => report.month == currentMonth,
      );
      _localReports = _mergeReports(
        primary: remoteReports,
        secondary: _localReports,
      );

      if (ensureCurrentMonth) {
        await _ensureCurrentMonthReport(
          remote: remote,
          userId: userId,
          hasCurrentMonthInSource: hasCurrentMonthInRemote,
        );
      }
      return fallbackReports;
    } catch (error, stackTrace) {
      developer.log(
        'fetchReports remote call failed',
        name: 'MonthlyReportRepository',
        error: error,
        stackTrace: stackTrace,
      );
      if (ensureCurrentMonth) {
        await _ensureCurrentMonthReport();
      }
      return fallbackReports;
    }
  }

  Future<void> _ensureCurrentMonthReport({
    SupabaseInsightsService? remote,
    String? userId,
    bool hasCurrentMonthInSource = false,
  }) async {
    if (hasCurrentMonthInSource) {
      return;
    }

    final currentMonth = MonthKey.fromDate(_now());
    final hasCurrent = _localReports.any(
      (report) => report.month == currentMonth,
    );
    final remoteWritable = remote != null && userId != null;
    if (hasCurrent && !remoteWritable) {
      return;
    }

    final generated = await _generateReportForMonth(currentMonth);
    _localReports = _mergeReports(
      primary: [generated],
      secondary: _localReports,
    );

    if (remote == null || userId == null) {
      return;
    }

    try {
      await remote.insertInsight(
        _buildInsertPayload(userId: userId, report: generated),
      );
    } catch (error, stackTrace) {
      developer.log(
        'insert generated monthly report failed',
        name: 'MonthlyReportRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<MonthlyReportRecord> _generateReportForMonth(MonthKey month) async {
    final snapshot = await _resolveDashboardSnapshot();
    final monthlyIncome = await _resolveMonthlyIncome();
    final seedInsight = _buildSeedInsight(snapshot: snapshot, month: month);
    final priceHistory = _buildPriceHistory(
      trend: snapshot.netWorthTrend,
      month: month,
    );
    final benchmarkHistory = _buildBenchmarkHistory(
      priceHistory: priceHistory,
      benchmarkReturnRate: seedInsight.quantMetrics.benchmarkReturnRate,
    );
    final analysis = await _l2AnalysisClient.analyzeMonthly(
      seedInsight: seedInsight,
      monthlyIncome: monthlyIncome,
      priceHistory: priceHistory,
      benchmarkHistory: benchmarkHistory,
    );

    return MonthlyReportRecord(
      insight: analysis.insight.copyWith(month: month),
      source: analysis.usedFallback
          ? MonthlyReportSource.fallback
          : MonthlyReportSource.backend,
      statusMessage: analysis.reason,
    );
  }

  Future<DashboardSnapshot> _resolveDashboardSnapshot() async {
    try {
      return await _dashboardRepository.fetchSnapshot();
    } catch (error, stackTrace) {
      developer.log(
        'fetchSnapshot for monthly report generation failed',
        name: 'MonthlyReportRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return _dashboardRepository.fallbackSnapshot;
    }
  }

  Future<num?> _resolveMonthlyIncome() async {
    final cachedIncome = _incomeStreamRepository.totalMonthlyIncome();
    if (cachedIncome > 0) {
      return cachedIncome;
    }

    try {
      await _incomeStreamRepository.fetchIncomeStreams();
    } catch (error, stackTrace) {
      developer.log(
        'fetchIncomeStreams for monthly report generation failed',
        name: 'MonthlyReportRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final refreshedIncome = _incomeStreamRepository.totalMonthlyIncome();
    if (refreshedIncome <= 0) {
      return null;
    }
    return refreshedIncome;
  }

  List<Map<String, Object?>> _buildPriceHistory({
    required List<num> trend,
    required MonthKey month,
  }) {
    if (trend.isEmpty) {
      return const [];
    }

    final firstDay = DateTime.utc(month.year, month.month, 1);
    final lastDay = DateTime.utc(month.year, month.month + 1, 0);
    final spanDays = (lastDay.difference(firstDay).inDays).clamp(0, 31);
    final rows = <Map<String, Object?>>[];

    for (var i = 0; i < trend.length; i++) {
      final close = trend[i].toDouble();
      if (close <= 0) {
        continue;
      }

      final dayOffset = trend.length == 1
          ? spanDays
          : ((spanDays * i) / (trend.length - 1)).round();
      final date = firstDay.add(Duration(days: dayOffset));
      rows.add({'date': _toIsoDateFromDate(date), 'close': close});
    }

    return rows;
  }

  List<Map<String, Object?>> _buildBenchmarkHistory({
    required List<Map<String, Object?>> priceHistory,
    required double benchmarkReturnRate,
  }) {
    if (priceHistory.isEmpty) {
      return const [];
    }

    final factor = benchmarkReturnRate == 0
        ? 0.95
        : (1 + benchmarkReturnRate).clamp(0.6, 1.4);
    final rows = <Map<String, Object?>>[];
    for (final row in priceHistory) {
      final date = row['date'];
      final close = row['close'];
      if (date is! String || close is! num || close <= 0) {
        continue;
      }
      rows.add({'date': date, 'close': close * factor});
    }
    return rows;
  }

  Map<String, dynamic> _buildInsertPayload({
    required String userId,
    required MonthlyReportRecord report,
  }) {
    final payload = report.insight.toJson()
      ..addAll({
        'analysis_source': report.source == MonthlyReportSource.backend
            ? 'backend'
            : 'fallback',
        'analysis_status_message': report.statusMessage,
        'analysis_context_hash': report.insight.aiTrace.contextHash,
        'ai_trace': report.insight.aiTrace.toJson(
          fallbackContextHash: report.insight.contextHash,
        ),
        'generated_at': _now().toUtc().toIso8601String(),
      });

    return {
      'user_id': userId,
      'snapshot_date': _toIsoDate(report.month),
      'insight_type': _monthlyReportInsightType,
      'title': '${report.month.zhLabel} 月度報告',
      'summary': report.insight.outlook,
      'severity': 'info',
      'payload': payload,
    };
  }

  List<MonthlyReportRecord> _parseRemoteReports(
    List<Map<String, dynamic>> rows,
  ) {
    final records = <MonthlyReportRecord>[];
    final seenMonths = <MonthKey>{};
    for (final row in rows) {
      final type = row['insight_type']?.toString();
      if (type != _monthlyReportInsightType) {
        continue;
      }

      final monthDate = _parseDateTime(row['snapshot_date']);
      if (monthDate == null) {
        continue;
      }
      final month = MonthKey(monthDate.year, monthDate.month);
      if (seenMonths.contains(month)) {
        continue;
      }

      final payload = _parsePayload(row['payload']);
      if (payload == null) {
        continue;
      }

      final insight = MonthlyInsight.fromJson(payload, fallbackMonth: month);
      final source = _sourceFromRaw(
        payload['analysis_source'],
        insight: insight,
      );
      final statusMessage = _statusFromPayload(payload, insight: insight);
      records.add(
        MonthlyReportRecord(
          insight: insight,
          source: source,
          statusMessage: statusMessage,
        ),
      );
      seenMonths.add(month);
    }

    return _mergeReports(primary: records, secondary: const []);
  }

  MonthlyInsight _buildSeedInsight({
    required DashboardSnapshot snapshot,
    required MonthKey month,
  }) {
    final savingsRate = _normalizeRate(snapshot.savingsRate);
    final savingsTarget = _normalizeRate(snapshot.savingsTarget);
    final budgetUsed = snapshot.budgetSummary.fold<num>(
      0,
      (sum, item) => sum + item.used,
    );
    final budgetLimit = snapshot.budgetSummary.fold<num>(
      0,
      (sum, item) => sum + item.limit,
    );
    final budgetCompletion = budgetLimit <= 0
        ? 0.0
        : (budgetUsed / budgetLimit).clamp(0, 1).toDouble();

    final budgetHighlights = [
      for (final item in snapshot.budgetSummary)
        BudgetRecapItem(
          label: item.label,
          completion: item.limit <= 0
              ? 0
              : (item.used / item.limit).clamp(0, 1).toDouble(),
          note: _budgetNote(item.tone),
        ),
    ];

    const defaultTargets = {'股票': 0.6, '債券': 0.25, '現金': 0.15};
    final allocationChanges = [
      for (final item in snapshot.allocationSummary)
        () {
          final currentWeight = _normalizeRate(item.value);
          final targetWeight = defaultTargets[item.label] ?? currentWeight;
          final previousWeight = ((currentWeight + targetWeight) / 2).clamp(
            0,
            1,
          );
          return AllocationChangeItem(
            label: item.label,
            previousWeight: previousWeight.toDouble(),
            currentWeight: currentWeight,
            targetWeight: targetWeight,
          );
        }(),
    ];

    final netWorthDelta = snapshot.netWorthDelta.amount;
    final quantMetrics = _buildQuantMetrics(
      snapshot: snapshot,
      netWorthDelta: netWorthDelta,
    );
    final outlook = netWorthDelta >= 0
        ? '下月建議延續既有定投與預算配置。'
        : '下月建議先穩定現金流，再逐步恢復投入節奏。';

    final insight = MonthlyInsight(
      month: month,
      netWorthCurrent: snapshot.netWorth.amount,
      netWorthDelta: netWorthDelta,
      savingsRate: savingsRate,
      savingsRateTarget: savingsTarget,
      budgetCompletion: budgetCompletion,
      budgetHighlights: budgetHighlights,
      allocationChanges: allocationChanges,
      quantMetrics: quantMetrics,
      aiInterpretation: _buildGovernedSeedLines(
        quantMetrics: quantMetrics,
        savingsRate: savingsRate,
        budgetCompletion: budgetCompletion,
      ),
      outlook: outlook,
    );

    return insight.copyWith(
      aiTrace: AiGovernanceTrace(
        model: 'seed-l1-l2',
        source: 'dashboard_snapshot',
        status: 'seeded',
        contextHash: insight.contextHash,
        generatedAt: _now().toUtc().toIso8601String(),
      ),
    );
  }

  List<MonthlyReportRecord> _mergeReports({
    required List<MonthlyReportRecord> primary,
    required List<MonthlyReportRecord> secondary,
  }) {
    final byMonth = <MonthKey, MonthlyReportRecord>{};
    for (final report in [...primary, ...secondary]) {
      byMonth.putIfAbsent(report.month, () => report);
    }
    final merged = byMonth.values.toList(growable: false)
      ..sort(
        (left, right) =>
            _monthSortValue(right.month).compareTo(_monthSortValue(left.month)),
      );
    return merged;
  }

  String _budgetNote(ProgressTone tone) {
    return switch (tone) {
      ProgressTone.calm => '維持目前節奏即可',
      ProgressTone.near => '接近上限，留意剩餘可用額度',
      ProgressTone.review => '建議下月先檢視這個分類',
    };
  }

  MonthlyReportSource _sourceFromRaw(Object? raw, {MonthlyInsight? insight}) {
    final traceSource = insight?.aiTrace.source.trim().toLowerCase();
    if (traceSource != null && traceSource.isNotEmpty) {
      if (traceSource.contains('backend') ||
          traceSource.contains('fastapi') ||
          traceSource.contains('l2')) {
        return MonthlyReportSource.backend;
      }
      if (traceSource.contains('fallback') || traceSource.contains('local')) {
        return MonthlyReportSource.fallback;
      }
    }

    final value = raw?.toString().trim().toLowerCase();
    if (value == 'backend') {
      return MonthlyReportSource.backend;
    }
    return MonthlyReportSource.fallback;
  }

  String _statusFromPayload(
    Map<String, dynamic> payload, {
    MonthlyInsight? insight,
  }) {
    final traceStatus = insight?.aiTrace.status.trim();
    if (traceStatus != null && traceStatus.isNotEmpty) {
      return traceStatus;
    }
    final value = payload['analysis_status_message']?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return '已載入已儲存月度報告。';
  }

  Map<String, dynamic>? _parsePayload(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  DateTime? _parseDateTime(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  double _normalizeRate(num value) {
    final raw = value.toDouble();
    final normalized = raw > 1 ? raw / 100 : raw;
    return normalized.clamp(0, 1).toDouble();
  }

  String _toIsoDate(MonthKey month) {
    final firstDay = DateTime.utc(month.year, month.month, 1);
    return firstDay.toIso8601String().substring(0, 10);
  }

  String _toIsoDateFromDate(DateTime date) {
    final utc = DateTime.utc(date.year, date.month, date.day);
    return utc.toIso8601String().substring(0, 10);
  }

  int _monthSortValue(MonthKey month) => month.year * 12 + month.month;

  QuantMetrics _buildQuantMetrics({
    required DashboardSnapshot snapshot,
    required num netWorthDelta,
  }) {
    final current = snapshot.netWorth.amount.toDouble();
    final previous = current - netWorthDelta.toDouble();
    final monthlyReturnRate = previous <= 0 ? 0 : (netWorthDelta / previous);
    final monthlyTrendReturns = _trendReturns(snapshot.netWorthTrend);
    final monthlyVolatility = _standardDeviation(monthlyTrendReturns);
    final annualizedVolatility = (monthlyVolatility * math.sqrt(12)).clamp(
      0,
      5,
    );
    final annualizedReturn = monthlyReturnRate * 12;
    final sharpe = annualizedVolatility <= 0
        ? 0
        : ((annualizedReturn - 0.015) / annualizedVolatility);
    final maxDrawdown = _maxDrawdown(snapshot.netWorthTrend);
    final benchmarkReturn = monthlyReturnRate * 0.75;
    final excessReturn = monthlyReturnRate - benchmarkReturn;
    final stressTests = _buildStressTests(
      returnRate: monthlyReturnRate.toDouble(),
      maxDrawdown: maxDrawdown.toDouble(),
    );

    return QuantMetrics(
      returnRate: monthlyReturnRate.toDouble(),
      volatility: annualizedVolatility.toDouble(),
      sharpeRatio: sharpe.toDouble(),
      maxDrawdown: maxDrawdown.toDouble(),
      benchmarkReturnRate: benchmarkReturn.toDouble(),
      benchmarkExcessReturn: excessReturn.toDouble(),
      stressTests: stressTests,
    );
  }

  List<double> _trendReturns(List<num> trend) {
    if (trend.length < 2) {
      return const [];
    }
    final returns = <double>[];
    for (var i = 1; i < trend.length; i++) {
      final previous = trend[i - 1].toDouble();
      final current = trend[i].toDouble();
      if (previous <= 0) {
        continue;
      }
      returns.add((current - previous) / previous);
    }
    return returns;
  }

  double _standardDeviation(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }

  double _maxDrawdown(List<num> trend) {
    if (trend.isEmpty) {
      return 0;
    }
    var peak = trend.first.toDouble();
    var maxDrawdown = 0.0;
    for (final point in trend) {
      final value = point.toDouble();
      if (value > peak) {
        peak = value;
      }
      if (peak <= 0) {
        continue;
      }
      final drawdown = (peak - value) / peak;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
      }
    }
    return maxDrawdown;
  }

  List<StressTestScenario> _buildStressTests({
    required double returnRate,
    required double maxDrawdown,
  }) {
    const scenarios = [('溫和衝擊', -0.08), ('中度衝擊', -0.15), ('極端衝擊', -0.25)];
    return [
      for (final (name, shock) in scenarios)
        StressTestScenario(
          name: name,
          shockRate: shock.abs(),
          projectedDrawdown: (maxDrawdown + shock.abs() * 0.55).clamp(0, 1),
          projectedReturnRate: (returnRate + shock).clamp(-1, 1),
        ),
    ];
  }

  List<String> _buildGovernedSeedLines({
    required QuantMetrics quantMetrics,
    required double savingsRate,
    required double budgetCompletion,
  }) {
    final returnRate = (quantMetrics.returnRate * 100).toStringAsFixed(2);
    final benchmark = (quantMetrics.benchmarkReturnRate * 100).toStringAsFixed(
      2,
    );
    final excess = (quantMetrics.benchmarkExcessReturn * 100).toStringAsFixed(
      2,
    );
    final volatility = (quantMetrics.volatility * 100).toStringAsFixed(2);
    final sharpe = quantMetrics.sharpeRatio.toStringAsFixed(2);
    final drawdown = (quantMetrics.maxDrawdown * 100).toStringAsFixed(2);
    final savings = (savingsRate * 100).toStringAsFixed(1);
    final budget = (budgetCompletion * 100).toStringAsFixed(1);

    return [
      '本月報酬率 $returnRate%，基準 $benchmark%，超額 $excess%。',
      '年化波動率 $volatility%，Sharpe $sharpe，最大回撤 $drawdown%。',
      '儲蓄率 $savings%，預算達成 $budget%，建議延續數字追蹤節奏。',
    ];
  }
}
