import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/routing/app_router.dart';
import 'package:networth_cockpit/core/routing/route_paths.dart';

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

    await tester.tap(find.text('選擇卡片'));
    await tester.pump();
    await tester.tap(find.text('使用範例檔案'));
    await tester.pump();
    await tester.tap(find.text('開始解析'));
    await tester.pumpAndSettle();

    expect(find.text('NTU TIMS Coffee'), findsOneWidget);
    expect(find.text('新商家'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Budget and portfolio pages avoid nested cards', (tester) async {
    tester.view.physicalSize = const Size(1024, 900);
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
