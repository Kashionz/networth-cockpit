import 'pwa_install_client.dart';

class StubPwaInstallClient implements PwaInstallClient {
  const StubPwaInstallClient();

  @override
  Future<PwaInstallStatus> getStatus() async {
    return const PwaInstallStatus(
      availability: PwaInstallAvailability.manual,
      promptSupported: false,
      canPromptInstall: false,
      isInstalled: false,
    );
  }

  @override
  Future<PwaInstallPromptResult> promptInstall() async {
    return const PwaInstallPromptResult(
      outcome: PwaInstallPromptOutcome.unavailable,
      prompted: false,
      reason: 'Current platform does not support PWA install prompt.',
    );
  }
}

PwaInstallClient createPlatformPwaInstallClient() {
  return const StubPwaInstallClient();
}
