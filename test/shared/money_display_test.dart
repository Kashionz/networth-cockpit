import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/privacy/privacy_mode_provider.dart';
import 'package:networth_cockpit/shared/models/money.dart';
import 'package:networth_cockpit/shared/widgets/data_display/money_display.dart';

void main() {
  testWidgets('MoneyDisplay formats Taiwan dollars with stable prefix', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: MoneyDisplay(amount: 2450000))),
      ),
    );

    expect(find.text('NT\$ 2,450,000'), findsOneWidget);
  });

  testWidgets('MoneyDisplay accepts Money value objects', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: MoneyDisplay(amount: Money.twd(2450000))),
        ),
      ),
    );

    expect(find.text('NT\$ 2,450,000'), findsOneWidget);
  });

  testWidgets('MoneyDisplay masks only the amount in privacy mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [privacyModeProvider.overrideWith((ref) => true)],
        child: const MaterialApp(
          home: Scaffold(body: MoneyDisplay(amount: 2450000)),
        ),
      ),
    );

    expect(find.text('NT\$ ¥¥¥¥¥'), findsOneWidget);
    expect(find.text('NT\$ 2,450,000'), findsNothing);
  });
}
