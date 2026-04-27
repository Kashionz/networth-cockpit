import 'package:flutter_riverpod/flutter_riverpod.dart';

final privacyModeControllerProvider =
    NotifierProvider<PrivacyModeController, bool>(PrivacyModeController.new);

final privacyModeProvider = Provider<bool>(
  (ref) => ref.watch(privacyModeControllerProvider),
);

class PrivacyModeController extends Notifier<bool> {
  @override
  bool build() => false;

  void setHidden(bool hidden) {
    state = hidden;
  }

  void toggle() {
    state = !state;
  }
}
