import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/pwa/pwa_install_client.dart';
import 'package:networth_cockpit/core/pwa/pwa_install_client_stub.dart';
import 'package:networth_cockpit/features/settings/pages/pwa_install_page.dart';

void main() {
  test('Stub PWA install client falls back to manual guidance', () async {
    const client = StubPwaInstallClient();

    final status = await client.getStatus();
    expect(status.availability, PwaInstallAvailability.manual);
    expect(status.canPromptInstall, isFalse);
    expect(status.promptSupported, isFalse);

    final result = await client.promptInstall();
    expect(result.outcome, PwaInstallPromptOutcome.unavailable);
    expect(result.prompted, isFalse);
  });

  testWidgets('PWA page shows immediate install button when installable', (
    tester,
  ) async {
    final fakeClient = _FakePwaInstallClient(
      status: const PwaInstallStatus(
        availability: PwaInstallAvailability.installable,
        promptSupported: true,
        canPromptInstall: true,
        isInstalled: false,
      ),
      promptResult: const PwaInstallPromptResult(
        outcome: PwaInstallPromptOutcome.accepted,
        prompted: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [pwaInstallClientProvider.overrideWithValue(fakeClient)],
        child: const MaterialApp(home: Scaffold(body: PwaInstallPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('目前狀態'), findsOneWidget);
    expect(find.textContaining('可安裝'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '立即安裝'), findsOneWidget);
    expect(find.text('beforeinstallprompt 支援: 是'), findsOneWidget);
  });

  testWidgets('PWA page install button triggers prompt and feedback', (
    tester,
  ) async {
    final fakeClient = _FakePwaInstallClient(
      status: const PwaInstallStatus(
        availability: PwaInstallAvailability.installable,
        promptSupported: true,
        canPromptInstall: true,
        isInstalled: false,
      ),
      promptResult: const PwaInstallPromptResult(
        outcome: PwaInstallPromptOutcome.accepted,
        prompted: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [pwaInstallClientProvider.overrideWithValue(fakeClient)],
        child: const MaterialApp(home: Scaffold(body: PwaInstallPage())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '立即安裝'));
    await tester.pumpAndSettle();

    expect(fakeClient.promptCalls, 1);
    expect(find.text('已送出安裝請求，請依瀏覽器提示完成安裝。'), findsOneWidget);
  });

  testWidgets('PWA page shows manual guidance state when not installable', (
    tester,
  ) async {
    final fakeClient = _FakePwaInstallClient(
      status: const PwaInstallStatus(
        availability: PwaInstallAvailability.manual,
        promptSupported: false,
        canPromptInstall: false,
        isInstalled: false,
      ),
      promptResult: const PwaInstallPromptResult(
        outcome: PwaInstallPromptOutcome.unavailable,
        prompted: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [pwaInstallClientProvider.overrideWithValue(fakeClient)],
        child: const MaterialApp(home: Scaffold(body: PwaInstallPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('需手動安裝引導'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '立即安裝'), findsNothing);
    expect(find.text('beforeinstallprompt 支援: 否'), findsOneWidget);
    expect(find.text('安裝步驟'), findsOneWidget);
  });
}

class _FakePwaInstallClient implements PwaInstallClient {
  _FakePwaInstallClient({required this.status, required this.promptResult});

  final PwaInstallStatus status;
  final PwaInstallPromptResult promptResult;
  int promptCalls = 0;

  @override
  Future<PwaInstallStatus> getStatus() async {
    return status;
  }

  @override
  Future<PwaInstallPromptResult> promptInstall() async {
    promptCalls += 1;
    return promptResult;
  }
}
