import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/routing/app_router.dart';
import 'package:networth_cockpit/core/routing/route_paths.dart';
import 'package:networth_cockpit/data/mock/mock_dashboard_data.dart';
import 'package:networth_cockpit/features/dashboard/controllers/dashboard_controller.dart';
import 'package:networth_cockpit/features/dashboard/models/dashboard_snapshot.dart';
import 'package:networth_cockpit/features/dashboard/pages/dashboard_page.dart';
import 'package:networth_cockpit/shared/models/money.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';
import 'package:networth_cockpit/shared/widgets/data_display/trend_sparkline.dart';
import 'package:networth_cockpit/shared/widgets/feedback/health_alert_card.dart';

void main() {
  test('mock dashboard snapshot includes all dashboard sections', () {
    expect(mockDashboardSnapshot.month.zhLabel, isNotEmpty);
    expect(mockDashboardSnapshot.savingsRate, isPositive);
    expect(mockDashboardSnapshot.netWorth.amount, isPositive);
    expect(mockDashboardSnapshot.netWorthTrend, hasLength(8));
    expect(mockDashboardSnapshot.budgetSummary, isNotEmpty);
    expect(mockDashboardSnapshot.allocationSummary, isNotEmpty);
    expect(mockDashboardSnapshot.attentionItems, isNotEmpty);
    expect(mockDashboardSnapshot.statementSummary.amount, isPositive);
    expect(mockDashboardSnapshot.lastSyncedAt, isA<DateTime>());
  });

  testWidgets('Dashboard reads its snapshot from dashboardControllerProvider', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWithValue(_fakeDashboardSnapshot),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardPage())),
      ),
    );

    expect(find.text('2030 年 1 月'), findsOneWidget);
    expect(find.text('41.5%'), findsOneWidget);
    expect(find.text('測試檢視'), findsOneWidget);
    expect(find.byType(HealthAlertCard), findsOneWidget);
    expect(
      tester.widget<TrendSparkline>(find.byType(TrendSparkline)).points,
      _fakeDashboardSnapshot.netWorthTrend,
    );
  });

  testWidgets('Dashboard leads with savings rate and keeps compliance copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DashboardPage())),
      ),
    );

    expect(find.text('本月儲蓄率'), findsOneWidget);
    expect(find.text('28.4%'), findsOneWidget);
    expect(find.textContaining('本資訊僅供參考'), findsOneWidget);

    final savingsTop = tester.getTopLeft(find.text('本月儲蓄率')).dy;
    final netWorthTop = tester.getTopLeft(find.text('淨資產')).dy;
    expect(savingsTop, lessThan(netWorthTop));
  });

  testWidgets('Dashboard keeps savings rate visible at 390px width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DashboardPage())),
      ),
    );

    expect(find.text('本月儲蓄率'), findsOneWidget);
    expect(find.text('28.4%'), findsOneWidget);
    expect(tester.getTopLeft(find.text('本月儲蓄率')).dy, lessThan(844));
    expect(tester.getTopLeft(find.text('28.4%')).dy, lessThan(844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Statement CTA opens credit card statement import flow', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: RoutePaths.dashboard);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    final cta = find.widgetWithText(TextButton, '匯入本期帳單');
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();

    expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));

    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(find.text('信用卡帳單匯入'), findsOneWidget);
    expect(find.text('選擇信用卡'), findsOneWidget);
  });
}

final _fakeDashboardSnapshot = DashboardSnapshot(
  month: const MonthKey(2030, 1),
  savingsRate: 41.5,
  savingsTarget: 30,
  netWorth: const Money.twd(1000000),
  netWorthDelta: const Money.twd(12000),
  netWorthTrend: const [760, 780, 810, 805, 860, 900, 940, 1000],
  budgetSummary: const [],
  allocationSummary: const [],
  attentionItems: const [AttentionItem(title: '測試檢視', body: '測試內容')],
  statementSummary: const Money.twd(3200),
  lastSyncedAt: DateTime(2030, 1, 20, 8),
);
