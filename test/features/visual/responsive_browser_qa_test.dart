import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/routing/app_router.dart';
import 'package:networth_cockpit/core/routing/route_paths.dart';
import 'package:networth_cockpit/features/transactions/import/controllers/transaction_import_controller.dart';

const _csvWithoutCategories = '''
date,merchant,amount,note
2026-04-02,NTU TIMS Coffee,145,早晨咖啡
2026-04-03,Taipei Metro,320,通勤
2026-04-06,Cloud Storage,90,雲端空間
2026-04-07,Bookstore Online,680,線上書店
2026-04-09,Market Weekend,1120,採買
''';

void main() {
  const sizes = [Size(390, 844), Size(768, 1024), Size(1440, 900)];

  for (final size in sizes) {
    testWidgets('Dashboard responsive QA ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = createAppRouter(initialLocation: RoutePaths.dashboard);
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      expect(find.text('本月儲蓄率'), findsOneWidget);
      expect(tester.takeException(), isNull);

      if (size.width >= 1024) {
        final headerX = tester.getTopLeft(find.text('總覽 Dashboard')).dx;
        expect(headerX, greaterThan(220));
        expect(find.byType(NavigationBar), findsNothing);
      } else {
        expect(find.byType(NavigationBar), findsOneWidget);
      }
    });
  }

  testWidgets('Import review row text stays readable on mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(
      initialLocation: RoutePaths.transactionsImport,
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '選擇卡片').first);
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final controller = container.read(
      transactionImportControllerProvider.notifier,
    );
    controller.submitCsvContent(_csvWithoutCategories);
    await tester.pump();
    controller.startParsing();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Cloud Storage'), 120);
    await tester.pumpAndSettle();

    expect(find.text('Cloud Storage'), findsOneWidget);
    expect(find.text('新商家'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Budget and portfolio pages avoid nested cards', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final budgetRouter = createAppRouter(initialLocation: RoutePaths.budget);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: budgetRouter)),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(Card), matching: find.byType(Card)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    final portfolioRouter = createAppRouter(
      initialLocation: RoutePaths.portfolioAllocation,
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: portfolioRouter)),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(Card), matching: find.byType(Card)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
