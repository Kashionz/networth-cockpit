import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/features/auth/pages/signup_page.dart';

void main() {
  testWidgets('Signup submit is disabled until investment disclaimer checked', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignupPage()));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'tester@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.pump();

    FilledButton submitBefore = tester.widget(
      find.widgetWithText(FilledButton, '建立帳號'),
    );
    expect(submitBefore.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    FilledButton submitAfter = tester.widget(
      find.widgetWithText(FilledButton, '建立帳號'),
    );
    expect(submitAfter.onPressed, isNotNull);
  });

  testWidgets('Signup includes Google OAuth placeholder and legal footer', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignupPage()));

    expect(find.text('使用 Google 繼續'), findsOneWidget);
    expect(find.text('隱私政策'), findsOneWidget);
    expect(find.text('使用者條款'), findsOneWidget);
    expect(find.text('我了解本服務不提供投資建議'), findsOneWidget);
  });
}
