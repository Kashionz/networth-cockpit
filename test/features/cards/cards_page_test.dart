import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/routing/app_router.dart';
import 'package:networth_cockpit/core/routing/route_paths.dart';
import 'package:networth_cockpit/features/cards/controllers/cards_controller.dart';
import 'package:networth_cockpit/features/cards/pages/cards_page.dart';

void main() {
  test('CardsController supports in-memory add and delete', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(cardsControllerProvider.notifier);
    final original = container.read(cardsControllerProvider);

    controller.addCard(
      displayName: '測試卡',
      statementAmount: 3200,
      statementDay: 20,
      dueDay: 5,
      lastFourDigits: '5566',
    );

    final afterAdd = container.read(cardsControllerProvider);
    expect(afterAdd.first.displayName, '測試卡');
    expect(afterAdd.first.statementAmount.amount, 3200);

    controller.deleteCard(afterAdd.first.id);
    final afterDelete = container.read(cardsControllerProvider);
    expect(afterDelete.length, original.length);
  });

  testWidgets('Cards page shows statement amount and statement cycle dates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: CardsPage())),
      ),
    );

    expect(find.text('信用卡'), findsOneWidget);
    expect(find.text('國泰 CUBE'), findsOneWidget);
    expect(find.text('台新 FlyGo'), findsOneWidget);
    expect(find.text('NT\$ 12,860'), findsOneWidget);
    expect(find.textContaining('結帳日'), findsAtLeastNWidgets(2));
    expect(find.textContaining('繳款日'), findsAtLeastNWidgets(2));
  });

  testWidgets('Card detail can enter /transactions/import from cards page', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: RoutePaths.cards);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('國泰 CUBE').first);
    await tester.pumpAndSettle();

    expect(find.text('卡片詳情'), findsOneWidget);
    expect(find.text('匯入本期帳單'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '匯入本期帳單'));
    await tester.pumpAndSettle();

    expect(find.text('信用卡帳單匯入'), findsOneWidget);
    expect(find.text('選擇信用卡'), findsOneWidget);
  });
}
