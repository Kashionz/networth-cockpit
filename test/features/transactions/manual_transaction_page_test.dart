import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/features/transactions/controllers/transactions_controller.dart';
import 'package:networth_cockpit/features/transactions/pages/manual_transaction_page.dart';

void main() {
  test('TransactionsController defaults source account to last used', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(transactionsControllerProvider);
    expect(state.lastUsedSourceAccount, '國泰 CUBE');
    expect(state.sourceAccounts, contains(state.lastUsedSourceAccount));
  });

  test('addManualRecord updates last used source account', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(transactionsControllerProvider.notifier);

    controller.addManualRecord(
      amount: 7600,
      date: DateTime(2026, 4, 27),
      category: '生活',
      sourceAccount: '現金錢包',
      note: '家電採買',
    );

    final state = container.read(transactionsControllerProvider);
    expect(state.lastUsedSourceAccount, '現金錢包');
    expect(state.records.first.amount.amount, 7600);
    expect(state.records.first.note, '家電採買');
  });

  testWidgets(
    'Manual transaction form shows amount/date/category/source account/note and neutral hint',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ManualTransactionPage()),
          ),
        ),
      );

      expect(find.text('手動記錄大額支出'), findsOneWidget);
      expect(find.text('金額'), findsOneWidget);
      expect(find.text('日期'), findsOneWidget);
      expect(find.text('類別'), findsOneWidget);
      expect(find.text('來源帳戶'), findsOneWidget);
      expect(find.text('備註'), findsOneWidget);
      expect(find.textContaining('小額現金支出可以先略過'), findsOneWidget);
      expect(find.text('國泰 CUBE'), findsOneWidget);
    },
  );

  testWidgets(
    'Manual form submits within one flow and keeps last used source',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ManualTransactionPage()),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, '例如：6800'),
        '6800',
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('現金錢包').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, '可選填，例如用途或商家'),
        '家電採買',
      );
      await tester.tap(find.widgetWithText(FilledButton, '30 秒快速記錄'));
      await tester.pump();

      expect(find.text('已加入手動交易紀錄'), findsOneWidget);

      final state = container.read(transactionsControllerProvider);
      expect(state.lastUsedSourceAccount, '現金錢包');
      expect(state.records.first.amount.amount, 6800);
      expect(state.records.first.note, '家電採買');
    },
  );
}
