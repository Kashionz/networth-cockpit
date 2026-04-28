import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'pwa_install_client.dart';

class WebPwaInstallClient implements PwaInstallClient {
  const WebPwaInstallClient();

  @override
  Future<PwaInstallStatus> getStatus() async {
    final rawState = _readInstallState();
    final isInstalled = _asBool(rawState['installed']) || _isStandaloneMode();
    final canPromptInstall = _asBool(rawState['canInstall']) && !isInstalled;
    final promptSupported =
        _asBool(rawState['promptSupported']) || _supportsInstallPrompt();

    final availability = switch ((isInstalled, canPromptInstall)) {
      (true, _) => PwaInstallAvailability.installed,
      (false, true) => PwaInstallAvailability.installable,
      (false, false) => PwaInstallAvailability.manual,
    };

    return PwaInstallStatus(
      availability: availability,
      promptSupported: promptSupported,
      canPromptInstall: canPromptInstall,
      isInstalled: isInstalled,
    );
  }

  @override
  Future<PwaInstallPromptResult> promptInstall() async {
    if (!globalContext.has('promptNetworthInstall')) {
      return const PwaInstallPromptResult(
        outcome: PwaInstallPromptOutcome.unavailable,
        prompted: false,
        reason: 'Install prompt is unavailable.',
      );
    }

    try {
      final JSAny? promiseValue = globalContext.callMethodVarArgs<JSAny?>(
        'promptNetworthInstall'.toJS,
      );
      if (promiseValue == null || !promiseValue.isA<JSPromise>()) {
        return const PwaInstallPromptResult(
          outcome: PwaInstallPromptOutcome.unavailable,
          prompted: false,
          reason: 'Install prompt is unavailable.',
        );
      }

      final resolved = await (promiseValue as JSPromise<JSAny?>).toDart;
      final map = _asMap(resolved);
      final prompted = _asBool(map['prompted']);
      final accepted = _asBool(map['accepted']);
      final dismissed = _asBool(map['dismissed']);

      if (!prompted) {
        return PwaInstallPromptResult(
          outcome: PwaInstallPromptOutcome.unavailable,
          prompted: false,
          reason: _asString(map['reason']) ?? 'Install prompt is unavailable.',
        );
      }

      if (accepted) {
        return const PwaInstallPromptResult(
          outcome: PwaInstallPromptOutcome.accepted,
          prompted: true,
        );
      }

      if (dismissed) {
        return const PwaInstallPromptResult(
          outcome: PwaInstallPromptOutcome.dismissed,
          prompted: true,
        );
      }

      return PwaInstallPromptResult(
        outcome: PwaInstallPromptOutcome.dismissed,
        prompted: prompted,
      );
    } catch (error) {
      return PwaInstallPromptResult(
        outcome: PwaInstallPromptOutcome.error,
        prompted: false,
        reason: '$error',
      );
    }
  }

  Map<String, dynamic> _readInstallState() {
    if (globalContext.has('getNetworthInstallState')) {
      final JSAny? raw = globalContext.callMethodVarArgs<JSAny?>(
        'getNetworthInstallState'.toJS,
      );
      return _asMap(raw);
    }

    if (globalContext.has('networthInstallState')) {
      final JSAny? raw = globalContext['networthInstallState'];
      return _asMap(raw);
    }

    return const <String, dynamic>{};
  }

  bool _isStandaloneMode() {
    if (globalContext.has('matchMedia')) {
      final JSAny? mediaQueryList = globalContext.callMethodVarArgs<JSAny?>(
        'matchMedia'.toJS,
        <JSAny?>['(display-mode: standalone)'.toJS],
      );
      if (mediaQueryList != null && mediaQueryList.isA<JSObject>()) {
        final matches = (mediaQueryList as JSObject)['matches']?.dartify();
        if (_asBool(matches)) {
          return true;
        }
      }
    }

    final JSAny? navigator = globalContext['navigator'];
    if (navigator != null && navigator.isA<JSObject>()) {
      final navObj = navigator as JSObject;
      if (navObj.has('standalone')) {
        return _asBool(navObj['standalone']?.dartify());
      }
    }

    return false;
  }

  bool _supportsInstallPrompt() {
    return globalContext.has('onbeforeinstallprompt') ||
        globalContext.has('BeforeInstallPromptEvent');
  }

  Map<String, dynamic> _asMap(JSAny? raw) {
    final converted = raw.dartify();
    if (converted is Map) {
      return converted.cast<String, dynamic>();
    }
    return const <String, dynamic>{};
  }

  bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  String? _asString(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }
}

PwaInstallClient createPlatformPwaInstallClient() {
  return const WebPwaInstallClient();
}
