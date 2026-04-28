import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pwa_install_client_stub.dart'
    if (dart.library.html) 'pwa_install_client_web.dart';

enum PwaInstallAvailability { installable, manual, installed }

extension PwaInstallAvailabilityX on PwaInstallAvailability {
  String get label => switch (this) {
    PwaInstallAvailability.installable => '可安裝（支援一鍵安裝）',
    PwaInstallAvailability.manual => '需手動安裝引導',
    PwaInstallAvailability.installed => '已安裝',
  };
}

class PwaInstallStatus {
  const PwaInstallStatus({
    required this.availability,
    required this.promptSupported,
    required this.canPromptInstall,
    required this.isInstalled,
  });

  final PwaInstallAvailability availability;
  final bool promptSupported;
  final bool canPromptInstall;
  final bool isInstalled;

  bool get needsManualGuidance => availability == PwaInstallAvailability.manual;
}

enum PwaInstallPromptOutcome { accepted, dismissed, unavailable, error }

class PwaInstallPromptResult {
  const PwaInstallPromptResult({
    required this.outcome,
    required this.prompted,
    this.reason,
  });

  final PwaInstallPromptOutcome outcome;
  final bool prompted;
  final String? reason;
}

abstract interface class PwaInstallClient {
  Future<PwaInstallStatus> getStatus();

  Future<PwaInstallPromptResult> promptInstall();
}

PwaInstallClient createPwaInstallClient() => createPlatformPwaInstallClient();

final pwaInstallClientProvider = Provider<PwaInstallClient>(
  (ref) => createPwaInstallClient(),
);
