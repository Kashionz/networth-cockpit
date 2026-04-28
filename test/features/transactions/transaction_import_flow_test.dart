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

Finder _selectCardButton() => find.widgetWithText(FilledButton, '選擇卡片').first;

const _csvWithoutCategories = '''
date,merchant,amount,note
2026-04-02,NTU TIMS Coffee,145,早晨咖啡
2026-04-03,Taipei Metro,320,通勤
2026-04-06,Cloud Storage,90,雲端空間
2026-04-07,Bookstore Online,680,線上書店
2026-04-09,Market Weekend,1120,採買
''';

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
    await tester.tap(_selectCardButton());
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TransactionImportFlowPage)),
    );
    final controller = container.read(
      transactionImportControllerProvider.notifier,
    );
    controller.submitCsvContent(_csvWithoutCategories);
    await tester.pump();
    controller.startParsing();
    await tester.pumpAndSettle();
  }

  testWidgets('Import flow can move from card selection to completed', (
    tester,
  ) async {
    await pumpImportFlow(tester);

    expect(find.text('選擇信用卡'), findsOneWidget);

    await tester.tap(_selectCardButton());
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

    expect(find.text('已自動分類 3 筆'), findsOneWidget);
    expect(find.text('待確認 2 筆'), findsOneWidget);
    expect(find.text('Cloud Storage'), findsOneWidget);
  });

  testWidgets('Import review renders suggested categories with CategoryTag', (
    tester,
  ) async {
    await pumpImportFlow(tester);
    await goToReview(tester);

    final categoryTags = find.byType(CategoryTag);

    expect(categoryTags, findsAtLeastNWidgets(1));
    expect(find.widgetWithText(CategoryTag, '其他'), findsAtLeastNWidgets(1));
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

      expect(find.text('Cloud Storage'), findsOneWidget);
      expect(find.text('新商家'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Cloud Storage'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tapping a category tag opens a sheet and updates one row', (
    tester,
  ) async {
    await pumpImportFlow(tester);
    await goToReview(tester);

    await tester.tap(find.widgetWithText(CategoryTag, '其他').first);
    await tester.pumpAndSettle();

    expect(find.text('選擇分類'), findsOneWidget);

    await tester.tap(find.text('交通').last);
    await tester.pumpAndSettle();

    final ntuRow = find.ancestor(
      of: find.text('Cloud Storage'),
      matching: find.byType(Card),
    );

    expect(
      find.descendant(of: ntuRow, matching: find.text('交通')),
      findsOneWidget,
    );
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

    expect(find.text('將寫入 5 筆'), findsOneWidget);
  });

  testWidgets('Import confirmation shows fixed living and flexible impacts', (
    tester,
  ) async {
    await pumpImportFlow(tester);
    await goToReview(tester);

    await tester.tap(find.text('確認分類'));
    await tester.pump();

    expect(find.text('將寫入 5 筆'), findsOneWidget);
    expect(find.text('預算影響'), findsOneWidget);
    expect(find.text('生活'), findsOneWidget);
    expect(find.text('彈性'), findsAtLeastNWidgets(1));
    expect(find.text('交通'), findsAtLeastNWidgets(1));
    expect(find.textContaining('NT\$'), findsAtLeastNWidgets(3));
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
    await tester.tap(_selectCardButton());
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TransactionImportFlowPage)),
    );
    final controller = container.read(
      transactionImportControllerProvider.notifier,
    );
    controller.markFileUnableToParse();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('這份檔案暫時無法解析'), findsOneWidget);
    expect(find.text('可以換一份 CSV,或稍後再試'), findsOneWidget);
    expect(find.textContaining('錯誤'), findsNothing);
    expect(find.textContaining('失敗!'), findsNothing);
  });
}
