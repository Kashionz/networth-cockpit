import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/privacy/privacy_mode_provider.dart';
import 'package:networth_cockpit/core/theme/theme_mode_provider.dart';
import 'package:networth_cockpit/features/auth/widgets/auth_form_shell.dart';
import 'package:networth_cockpit/features/settings/pages/account_page.dart';
import 'package:networth_cockpit/features/settings/pages/export_page.dart';
import 'package:networth_cockpit/features/settings/pages/profile_page.dart';

void main() {
  testWidgets('Profile page includes a prominent privacy mode toggle', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    expect(find.text('隱私模式'), findsOneWidget);
    expect(find.textContaining('即時遮罩'), findsOneWidget);
    expect(container.read(privacyModeProvider), isFalse);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    expect(container.read(privacyModeProvider), isTrue);
  });

  testWidgets('Profile page can switch theme mode to dark', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    expect(container.read(themeModeProvider), ThemeMode.system);

    await tester.tap(find.text('暗色模式'));
    await tester.pump();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('Export page offers CSV and JSON format options', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExportPage()));

    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('JSON'), findsOneWidget);
    expect(find.text('匯出資料'), findsOneWidget);
  });

  testWidgets('Account page keeps deletion action visible and calm', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AccountPage()));

    expect(find.text('隱私政策'), findsOneWidget);
    expect(find.text('使用者條款'), findsOneWidget);
    expect(find.text('AI 解讀模板'), findsOneWidget);
    expect(find.text('提醒與推播'), findsOneWidget);
    expect(find.text('安裝 App（PWA）'), findsOneWidget);
    expect(find.text('刪除帳號'), findsOneWidget);
    expect(find.text('若暫時不需要此服務,可先匯出資料後再申請刪除。'), findsOneWidget);
    expect(find.textContaining('危險'), findsNothing);
    expect(find.textContaining('警告'), findsNothing);
  });

  testWidgets('Auth footer keeps legal entrances visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthFormShell(
          title: '測試登入',
          subtitle: '測試內容',
          fields: [SizedBox.shrink()],
          primaryLabel: '送出',
          onPrimaryPressed: null,
        ),
      ),
    );

    expect(find.text('隱私政策'), findsOneWidget);
    expect(find.text('使用者條款'), findsOneWidget);
    expect(find.text('AI 解讀模板'), findsOneWidget);
  });
}
