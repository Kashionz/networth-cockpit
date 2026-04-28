import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/monthly_report_repository.dart';
import 'package:networth_cockpit/features/insights/controllers/insights_controller.dart';
import 'package:networth_cockpit/features/insights/models/monthly_insight.dart';
import 'package:networth_cockpit/features/insights/pages/insights_page.dart';
import 'package:networth_cockpit/features/insights/pages/monthly_insight_page.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';

void main() {
  testWidgets('Monthly insight page shows recap sections and disclaimers', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsControllerProvider.overrideWith(
            () => _TestInsightsController(_insightState),
          ),
        ],
        child: const MaterialApp(home: MonthlyInsightPage()),
      ),
    );

    expect(find.text('淨值變化'), findsOneWidget);
    expect(find.text('儲蓄率回顧'), findsOneWidget);
    expect(find.text('預算達成'), findsOneWidget);
    expect(find.text('配置變化'), findsOneWidget);
    expect(find.text('L2 量化指標'), findsOneWidget);
    expect(find.text('Sharpe'), findsOneWidget);
    expect(find.text('壓力測試'), findsOneWidget);
    expect(find.textContaining('中度衝擊'), findsOneWidget);
    expect(find.text('AI 解讀'), findsOneWidget);
    expect(find.text('L1 健康提示'), findsOneWidget);
    expect(find.text('整體狀態穩定'), findsOneWidget);
    expect(find.text('資料來源：FastAPI 後端分析'), findsOneWidget);
    expect(find.text('AI 解讀不構成投資建議'), findsOneWidget);
    expect(find.text('本資訊僅供參考,不構成投資建議'), findsOneWidget);
  });

  testWidgets('Insights page renders monthly insight content', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsControllerProvider.overrideWith(
            () => _TestInsightsController(_insightState),
          ),
        ],
        child: const MaterialApp(home: InsightsPage()),
      ),
    );

    expect(find.text('月度報告'), findsOneWidget);
    expect(find.textContaining('2030 年 1 月'), findsWidgets);
    expect(find.text('建議下月延續固定定投節奏。'), findsOneWidget);
  });

  testWidgets('Monthly insight keeps neutral and forward-looking tone', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsControllerProvider.overrideWith(
            () => _TestInsightsController(_insightState),
          ),
        ],
        child: const MaterialApp(home: MonthlyInsightPage()),
      ),
    );

    expect(find.textContaining('危險'), findsNothing);
    expect(find.textContaining('失敗'), findsNothing);
    expect(find.textContaining('警告'), findsNothing);
    expect(find.text('建議下月延續固定定投節奏。'), findsOneWidget);
  });

  testWidgets('Monthly insight page switches selected month via selector', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsControllerProvider.overrideWith(
            () => _TestInsightsController(_insightState),
          ),
        ],
        child: const MaterialApp(home: MonthlyInsightPage()),
      ),
    );

    expect(find.text('建議下月延續固定定投節奏。'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('insights-month-selector')),
    );
    await tester.tap(find.byKey(const Key('insights-month-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2029 年 12 月').last);
    await tester.pumpAndSettle();

    expect(find.text('下月建議先收斂彈性支出後再提高投入。'), findsOneWidget);
    expect(find.text('資料來源：本地 fallback'), findsOneWidget);
  });
}

class _TestInsightsController extends InsightsController {
  _TestInsightsController(this._state);

  final InsightsState _state;

  @override
  InsightsState build() => _state;
}

const _insightState = InsightsState(
  reports: [_latestReport, _previousReport],
  selectedMonth: MonthKey(2030, 1),
);

const _latestReport = MonthlyReportRecord(
  insight: _latestInsight,
  source: MonthlyReportSource.backend,
  statusMessage: '已套用後端月度分析結果。',
);

const _previousReport = MonthlyReportRecord(
  insight: _previousInsight,
  source: MonthlyReportSource.fallback,
  statusMessage: 'FASTAPI_BASE_URL 未設定，已使用本地月度解讀。',
);

const _latestInsight = MonthlyInsight(
  month: MonthKey(2030, 1),
  netWorthCurrent: 1210000,
  netWorthDelta: 64000,
  savingsRate: 0.284,
  savingsRateTarget: 0.3,
  budgetCompletion: 0.91,
  budgetHighlights: [
    BudgetRecapItem(label: '固定', completion: 0.93, note: '支出與計畫接近'),
    BudgetRecapItem(label: '生活', completion: 0.88, note: '可持續維持'),
    BudgetRecapItem(label: '彈性', completion: 0.97, note: '下月可預留緩衝'),
  ],
  allocationChanges: [
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
  aiInterpretation: [
    '本月淨值與儲蓄率維持穩定，現金流節奏可持續。',
    '預算使用率接近規劃，可在下月延續相同分配。',
    '配置已回到目標區間，建議維持定期檢視。',
  ],
  quantMetrics: QuantMetrics(
    returnRate: 0.038,
    volatility: 0.136,
    sharpeRatio: 1.52,
    maxDrawdown: 0.082,
    benchmarkReturnRate: 0.031,
    benchmarkExcessReturn: 0.007,
    stressTests: [
      StressTestScenario(
        name: '中度衝擊',
        shockRate: 0.15,
        projectedDrawdown: 0.18,
        projectedReturnRate: -0.12,
      ),
    ],
  ),
  aiTrace: AiGovernanceTrace(
    model: 'gpt-5-mini',
    source: 'fastapi_l2',
    status: 'ok',
    contextHash: 'ctx-203001',
  ),
  outlook: '建議下月延續固定定投節奏。',
);

const _previousInsight = MonthlyInsight(
  month: MonthKey(2029, 12),
  netWorthCurrent: 1146000,
  netWorthDelta: -21000,
  savingsRate: 0.25,
  savingsRateTarget: 0.3,
  budgetCompletion: 0.83,
  budgetHighlights: [
    BudgetRecapItem(label: '固定', completion: 0.92, note: '固定項目穩定'),
    BudgetRecapItem(label: '生活', completion: 0.8, note: '生活支出偏高'),
    BudgetRecapItem(label: '彈性', completion: 0.77, note: '彈性項目可再收斂'),
  ],
  allocationChanges: [
    AllocationChangeItem(
      label: '股票',
      previousWeight: 0.61,
      currentWeight: 0.58,
      targetWeight: 0.6,
    ),
    AllocationChangeItem(
      label: '債券',
      previousWeight: 0.23,
      currentWeight: 0.26,
      targetWeight: 0.25,
    ),
    AllocationChangeItem(
      label: '現金',
      previousWeight: 0.16,
      currentWeight: 0.16,
      targetWeight: 0.15,
    ),
  ],
  aiInterpretation: [
    '淨值較上月回落，建議檢查一次性支出來源。',
    '儲蓄率低於目標，先優先收斂彈性預算。',
    '配置仍在可控區間，建議按月回看即可。',
  ],
  quantMetrics: QuantMetrics(
    returnRate: -0.019,
    volatility: 0.214,
    sharpeRatio: -0.41,
    maxDrawdown: 0.143,
    benchmarkReturnRate: -0.012,
    benchmarkExcessReturn: -0.007,
    stressTests: [
      StressTestScenario(
        name: '極端衝擊',
        shockRate: 0.25,
        projectedDrawdown: 0.28,
        projectedReturnRate: -0.27,
      ),
    ],
  ),
  aiTrace: AiGovernanceTrace(
    model: 'local-deterministic',
    source: 'l2_fallback',
    status: 'fallback',
    contextHash: 'ctx-202912',
  ),
  outlook: '下月建議先收斂彈性支出後再提高投入。',
);
