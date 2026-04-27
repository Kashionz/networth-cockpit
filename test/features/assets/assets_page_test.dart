import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/features/assets/controllers/assets_controller.dart';
import 'package:networth_cockpit/features/assets/models/asset_type.dart';
import 'package:networth_cockpit/features/assets/pages/assets_page.dart';
import 'package:networth_cockpit/shared/models/money.dart';
import 'package:networth_cockpit/shared/widgets/data_display/money_display.dart';

void main() {
  test('AssetsController keeps mock CRUD in memory', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(assetsControllerProvider.notifier);
    final original = container.read(assetsControllerProvider);
    expect(original, isNotEmpty);

    controller.addAsset(
      name: '測試資產',
      type: AssetType.stockEtf,
      value: const Money.twd(55000),
    );
    final afterAdd = container.read(assetsControllerProvider);
    expect(afterAdd.first.name, '測試資產');

    final added = afterAdd.first;
    controller.updateAsset(added.copyWith(value: const Money.twd(72000)));
    final afterUpdate = container.read(assetsControllerProvider);
    expect(afterUpdate.first.value.amount, 72000);

    controller.deleteAsset(added.id);
    final afterDelete = container.read(assetsControllerProvider);
    expect(afterDelete.length, original.length);
    expect(afterDelete.where((asset) => asset.id == added.id), isEmpty);
  });

  testWidgets('Assets page groups by category and shows name/value/ratio', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AssetsPage())),
      ),
    );

    expect(find.text('資產總覽'), findsOneWidget);
    expect(find.text('現金與存款'), findsOneWidget);
    expect(find.text('投資資產'), findsOneWidget);
    expect(find.text('台幣活存'), findsOneWidget);
    expect(find.text('0050 ETF'), findsOneWidget);
    expect(find.byType(MoneyDisplay), findsAtLeastNWidgets(6));
    expect(find.textContaining('%'), findsAtLeastNWidgets(5));
  });

  testWidgets('Assets page can remove one asset row through mock actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AssetsPage())),
      ),
    );

    expect(find.text('台幣活存'), findsOneWidget);

    await tester.tap(find.byTooltip('移除資產').first);
    await tester.pump();

    expect(find.text('台幣活存'), findsNothing);
    expect(find.byType(MoneyDisplay), findsAtLeastNWidgets(3));
  });
}
