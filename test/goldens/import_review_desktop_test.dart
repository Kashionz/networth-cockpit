import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/routing/app_router.dart';
import 'package:networth_cockpit/core/routing/route_paths.dart';

void main() {
  testWidgets('import review desktop golden', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
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

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('baselines/import_review_desktop.png'),
    );
  });
}
