import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('AI 解讀'), findsOneWidget);
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
    expect(find.textContaining('2030 年 1 月'), findsOneWidget);
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
}

class _TestInsightsController extends InsightsController {
  _TestInsightsController(this._state);

  final InsightsState _state;

  @override
  InsightsState build() => _state;
}

const _insightState = InsightsState(
  fallbackInsight: _insight,
  backendInsight: _insight,
  source: InsightSource.backend,
  statusMessage: '已套用後端月度分析結果。',
);

const _insight = MonthlyInsight(
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
  outlook: '建議下月延續固定定投節奏。',
);
