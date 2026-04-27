import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/routing/route_paths.dart';
import 'package:networth_cockpit/core/theme/app_colors.dart';
import 'package:networth_cockpit/features/budget/controllers/budget_controller.dart';
import 'package:networth_cockpit/features/budget/models/budget_category.dart';
import 'package:networth_cockpit/features/budget/models/budget_month.dart';
import 'package:networth_cockpit/features/budget/pages/budget_history_page.dart';
import 'package:networth_cockpit/features/budget/pages/budget_page.dart';
import 'package:networth_cockpit/shared/models/money.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';
import 'package:networth_cockpit/shared/widgets/data_display/progress_bar.dart';

void main() {
  testWidgets(
    'Budget page renders overview, categories, and planning sections',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: BudgetPage())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('本月預算'), findsOneWidget);
      expect(find.text('本月總覽'), findsOneWidget);
      expect(find.text('三類預算進度'), findsOneWidget);
      expect(find.text('固定'), findsAtLeastNWidgets(1));
      expect(find.text('生活'), findsAtLeastNWidgets(1));
      expect(find.text('彈性'), findsAtLeastNWidgets(1));
      expect(find.text('下月預算規劃'), findsOneWidget);
      expect(find.byType(ProgressBar), findsAtLeastNWidgets(4));
    },
  );

  testWidgets('95% usage is displayed with review tone instead of red text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetControllerProvider.overrideWithValue(_highUsageMonth),
        ],
        child: const MaterialApp(home: Scaffold(body: BudgetPage())),
      ),
    );
    await tester.pumpAndSettle();

    final usageText = tester.widget<Text>(find.text('95%').first);
    expect(usageText.style?.color, AppColors.review);
    expect(usageText.style?.color, isNot(Colors.red));
  });

  testWidgets('Budget page can open budget history page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          initialRoute: RoutePaths.budget,
          routes: {
            RoutePaths.budget: (_) => const Scaffold(body: BudgetPage()),
            RoutePaths.budgetHistory: (_) =>
                const Scaffold(body: BudgetHistoryPage()),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final historyButton = find.widgetWithText(TextButton, '查看歷史月份');
    await tester.ensureVisible(historyButton);
    await tester.tap(historyButton);
    await tester.pumpAndSettle();

    expect(find.text('預算歷史'), findsOneWidget);
    expect(find.textContaining('近期月度回顧'), findsOneWidget);
  });

  testWidgets('Budget history opens month detail page', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: BudgetHistoryPage())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '查看月份詳情').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('月份詳情'), findsOneWidget);
    expect(find.text('下月預算規劃'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _highUsageMonth = BudgetMonth(
  month: const MonthKey(2030, 5),
  categories: const [
    BudgetCategory(
      id: 'high-usage-fixed',
      name: '固定',
      type: BudgetCategoryType.fixed,
      budgetAmount: Money.twd(18000),
      usedAmount: Money.twd(17100),
      rollover: false,
    ),
    BudgetCategory(
      id: 'high-usage-living',
      name: '生活',
      type: BudgetCategoryType.living,
      budgetAmount: Money.twd(15000),
      usedAmount: Money.twd(9000),
      rollover: false,
    ),
    BudgetCategory(
      id: 'high-usage-flex',
      name: '彈性',
      type: BudgetCategoryType.flex,
      budgetAmount: Money.twd(7000),
      usedAmount: Money.twd(3500),
      rollover: true,
    ),
  ],
  largeExpenses: [],
);
