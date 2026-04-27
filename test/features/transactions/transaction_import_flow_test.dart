import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:networth_cockpit/data/services/ai/l2_analysis_client.dart';
import 'package:networth_cockpit/features/transactions/import/controllers/transaction_import_controller.dart';
import 'package:networth_cockpit/features/transactions/import/pages/transaction_import_flow_page.dart';
import 'package:networth_cockpit/features/transactions/import/widgets/import_summary_band.dart';
import 'package:networth_cockpit/shared/widgets/forms/category_tag.dart';

void main() {
  final fallbackL2Client = L2AnalysisClient(
    baseUrl: null,
    httpClient: MockClient((_) async => http.Response('{}', 500)),
  );

  Future<void> pumpImportFlow(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          l2AnalysisClientProvider.overrideWithValue(fallbackL2Client),
        ],
        child: MaterialApp(home: TransactionImportFlowPage()),
      ),
    );
  }

  Future<void> goToReview(WidgetTester tester) async {
    await tester.tap(find.text('選擇卡片'));
    await tester.pump();
    await tester.tap(find.text('使用範例檔案'));
    await tester.pump();
    await tester.tap(find.text('開始解析'));
    await tester.pumpAndSettle();
  }

  testWidgets('Import flow can move from card selection to completed', (
    tester,
  ) async {
    await pumpImportFlow(tester);

    expect(find.text('選擇信用卡'), findsOneWidget);

    await tester.tap(find.text('選擇卡片'));
    await tester.pump();
    expect(find.text('上傳帳單'), findsOneWidget);
    expect(find.textContaining('支援 CSV / PDF'), findsOneWidget);

    await tester.tap(find.text('使用範例檔案'));
    await tester.pump();
    expect(find.text('解析帳單'), findsOneWidget);

    await tester.tap(find.text('開始解析'));
    await tester.pumpAndSettle();
    expect(find.text('確認分類建議'), findsOneWidget);

    await tester.tap(find.text('確認分類'));
    await tester.pump();
    expect(find.text('寫入前確認'), findsOneWidget);

    await tester.tap(find.text('完成寫入'));
    await tester.pump();
    expect(find.text('完成匯入'), findsOneWidget);
  });

  testWidgets('Import review separates auto-classified and review rows', (
    tester,
  ) async {
    await pumpImportFlow(tester);
    await goToReview(tester);

    expect(find.text('已自動分類 9 筆'), findsOneWidget);
    expect(find.text('待確認 5 筆'), findsOneWidget);
    expect(find.text('NTU TIMS Coffee'), findsOneWidget);
    expect(find.text('越用越快'), findsOneWidget);
  });

  testWidgets('Import review renders suggested categories with CategoryTag', (
    tester,
  ) async {
    await pumpImportFlow(tester);
    await goToReview(tester);

    final categoryTags = find.byType(CategoryTag);

    expect(categoryTags, findsAtLeastNWidgets(1));
    expect(
      find.descendant(of: categoryTags.first, matching: find.text('生活')),
      findsOneWidget,
    );
  });

  testWidgets('Import review can accept all suggestions without a dialog', (
    tester,
  ) async {
    await pumpImportFlow(tester);
    await goToReview(tester);

    await tester.tap(find.text('接受全部建議'));
    await tester.pump();

    expect(find.text('待確認 0 筆'), findsOneWidget);
    expect(find.text('分類建議已套用'), findsOneWidget);
  });

  testWidgets(
    'Review rows expand low-confidence or new merchants and collapse high confidence rows',
    (tester) async {
      await pumpImportFlow(tester);
      await goToReview(tester);

      expect(find.textContaining('保留本地分類'), findsOneWidget);
      expect(find.text('與通勤支出相近'), findsNothing);

      await tester.scrollUntilVisible(find.text('Taipei Metro'), 80);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Taipei Metro'));
      await tester.pumpAndSettle();

      expect(find.text('與通勤支出相近'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Cloud Storage'), 120);
      await tester.pumpAndSettle();

      expect(find.textContaining('保留本地分類'), findsWidgets);
    },
  );

  testWidgets('Tapping a category tag opens a sheet and updates one row', (
    tester,
  ) async {
    await pumpImportFlow(tester);
    await goToReview(tester);

    await tester.tap(find.widgetWithText(CategoryTag, '生活').first);
    await tester.pumpAndSettle();

    expect(find.text('選擇分類'), findsOneWidget);

    await tester.tap(find.text('交通').last);
    await tester.pumpAndSettle();

    final ntuRow = find.ancestor(
      of: find.text('NTU TIMS Coffee'),
      matching: find.byType(Card),
    );

    expect(
      find.descendant(of: ntuRow, matching: find.text('交通')),
      findsOneWidget,
    );
    expect(find.text('已記住規則'), findsOneWidget);
  });

  testWidgets('Import confirmation keeps accepted review rows in write count', (
    tester,
  ) async {
    await pumpImportFlow(tester);
    await goToReview(tester);

    await tester.tap(find.text('接受全部建議'));
    await tester.pump();
    await tester.tap(find.text('確認分類'));
    await tester.pump();

    expect(find.text('將寫入 14 筆'), findsOneWidget);
  });

  testWidgets('Import confirmation shows fixed living and flexible impacts', (
    tester,
  ) async {
    await pumpImportFlow(tester);
    await goToReview(tester);

    await tester.tap(find.text('確認分類'));
    await tester.pump();

    expect(find.text('將寫入 14 筆'), findsOneWidget);
    expect(find.text('預算影響'), findsOneWidget);
    expect(find.text('固定'), findsOneWidget);
    expect(find.text('生活'), findsOneWidget);
    expect(find.text('彈性'), findsOneWidget);
    expect(find.text('NT\$ 2,490'), findsOneWidget);
    expect(find.text('NT\$ 12,860'), findsOneWidget);
    expect(find.text('NT\$ 4,800'), findsOneWidget);
  });

  testWidgets('Import summary band avoids overflow in a narrow layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          l2AnalysisClientProvider.overrideWithValue(fallbackL2Client),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              child: ImportSummaryBand(
                writeCount: 128,
                budgetImpacts: [
                  BudgetImpact(label: '固定', amount: 2490000),
                  BudgetImpact(label: '生活', amount: 1286000),
                  BudgetImpact(label: '彈性', amount: 480000),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Import failed page uses calm recovery copy', (tester) async {
    await pumpImportFlow(tester);
    await tester.tap(find.text('選擇卡片'));
    await tester.pump();
    await tester.tap(find.text('這份檔案暫時無法解析'));
    await tester.pump();

    expect(find.text('這份檔案暫時無法解析'), findsOneWidget);
    expect(find.text('可以換一份 CSV,或稍後再試'), findsOneWidget);
    expect(find.textContaining('錯誤'), findsNothing);
    expect(find.textContaining('失敗!'), findsNothing);
  });
}
