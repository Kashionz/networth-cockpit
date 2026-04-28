import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:networth_cockpit/data/repositories/dashboard_repository.dart';
import 'package:networth_cockpit/data/repositories/monthly_report_repository.dart';
import 'package:networth_cockpit/data/services/ai/l2_analysis_client.dart';
import 'package:networth_cockpit/features/insights/controllers/insights_controller.dart';
import 'package:networth_cockpit/features/insights/models/monthly_insight.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';

void main() {
  test('auto-generates current month report when missing', () async {
    final currentMonth = MonthKey.fromDate(DateTime.now());
    final previousMonth = _addMonths(currentMonth, -1);
    final repository = MonthlyReportRepositoryImpl(
      remoteService: null,
      dashboardRepository: const MockDashboardRepository(),
      l2AnalysisClient: _offlineL2Client(),
      seedReports: [
        MonthlyReportRecord(
          insight: _insightForMonth(previousMonth),
          source: MonthlyReportSource.fallback,
          statusMessage: '既有歷史月報。',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        monthlyReportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(insightsControllerProvider.notifier);
    await notifier.refresh();

    final state = container.read(insightsControllerProvider);
    expect(state.availableMonths, contains(currentMonth));
    expect(state.selectedMonth, currentMonth);
    expect(state.displayInsight.quantMetrics.stressTests, isNotEmpty);
    expect(state.displayInsight.aiTrace.contextHash, isNot('unknown'));
  });

  test('controller switches selected month and report content', () async {
    final currentMonth = MonthKey.fromDate(DateTime.now());
    final previousMonth = _addMonths(currentMonth, -1);
    final repository = MonthlyReportRepositoryImpl(
      remoteService: null,
      dashboardRepository: const MockDashboardRepository(),
      l2AnalysisClient: _offlineL2Client(),
      seedReports: [
        MonthlyReportRecord(
          insight: _insightForMonth(currentMonth, outlook: '維持目前節奏。'),
          source: MonthlyReportSource.backend,
          statusMessage: '已套用後端月度分析結果。',
        ),
        MonthlyReportRecord(
          insight: _insightForMonth(previousMonth, outlook: '先控制彈性支出。'),
          source: MonthlyReportSource.fallback,
          statusMessage: '已使用本地月度解讀。',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        monthlyReportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(insightsControllerProvider.notifier);
    await notifier.refresh();
    notifier.selectMonth(previousMonth);

    final state = container.read(insightsControllerProvider);
    expect(state.selectedMonth, previousMonth);
    expect(state.displayInsight.month, previousMonth);
    expect(state.displayInsight.outlook, '先控制彈性支出。');
  });

  test('falls back to local report when remote is unavailable', () async {
    final currentMonth = MonthKey.fromDate(DateTime.now());
    final previousMonth = _addMonths(currentMonth, -1);
    final repository = MonthlyReportRepositoryImpl(
      remoteService: null,
      dashboardRepository: const MockDashboardRepository(),
      l2AnalysisClient: _offlineL2Client(),
      seedReports: [
        MonthlyReportRecord(
          insight: _insightForMonth(previousMonth),
          source: MonthlyReportSource.fallback,
          statusMessage: '歷史月報。',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        monthlyReportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(insightsControllerProvider.notifier);
    await notifier.refresh();

    final state = container.read(insightsControllerProvider);
    expect(state.usedFallback, isTrue);
    expect(state.sourceLabel, '本地 fallback');
    expect(state.statusMessage, contains('FASTAPI_BASE_URL'));
  });
}

L2AnalysisClient _offlineL2Client() {
  return L2AnalysisClient(
    baseUrl: null,
    httpClient: MockClient((_) async => http.Response('{}', 500)),
  );
}

MonthlyInsight _insightForMonth(MonthKey month, {String? outlook}) {
  return MonthlyInsight(
    month: month,
    netWorthCurrent: 1000000,
    netWorthDelta: 12000,
    savingsRate: 0.28,
    savingsRateTarget: 0.3,
    budgetCompletion: 0.9,
    budgetHighlights: const [
      BudgetRecapItem(label: '固定', completion: 0.95, note: '維持既有安排'),
      BudgetRecapItem(label: '生活', completion: 0.88, note: '可持續觀察'),
      BudgetRecapItem(label: '彈性', completion: 0.9, note: '留意剩餘額度'),
    ],
    allocationChanges: const [
      AllocationChangeItem(
        label: '股票',
        previousWeight: 0.58,
        currentWeight: 0.6,
        targetWeight: 0.6,
      ),
      AllocationChangeItem(
        label: '債券',
        previousWeight: 0.27,
        currentWeight: 0.25,
        targetWeight: 0.25,
      ),
      AllocationChangeItem(
        label: '現金',
        previousWeight: 0.15,
        currentWeight: 0.15,
        targetWeight: 0.15,
      ),
    ],
    aiInterpretation: const ['本月淨值維持穩定。', '儲蓄率接近目標。', '配置接近目標區間。'],
    outlook: outlook ?? '維持目前節奏。',
  );
}

MonthKey _addMonths(MonthKey month, int delta) {
  final date = DateTime(month.year, month.month + delta, 1);
  return MonthKey(date.year, date.month);
}
