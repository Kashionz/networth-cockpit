import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_notification_client_stub.dart'
    if (dart.library.html) 'push_notification_client_web.dart';

enum PushPermissionStatus { granted, denied, unavailable, defaultState }

extension PushPermissionStatusX on PushPermissionStatus {
  String get label => switch (this) {
    PushPermissionStatus.granted => '已允許推播',
    PushPermissionStatus.denied => '已封鎖推播',
    PushPermissionStatus.unavailable => '裝置不支援推播',
    PushPermissionStatus.defaultState => '尚未授權推播',
  };
}

class PushDeliveryResult {
  const PushDeliveryResult({
    required this.sent,
    required this.permissionStatus,
    this.reason,
  });

  final bool sent;
  final PushPermissionStatus permissionStatus;
  final String? reason;
}

abstract interface class PushNotificationClient {
  Future<PushPermissionStatus> ensurePermission();

  Future<PushDeliveryResult> send({
    required String title,
    required String body,
    String? tag,
  });
}

PushNotificationClient createPushNotificationClient() =>
    createPlatformPushNotificationClient();

final pushNotificationClientProvider = Provider<PushNotificationClient>(
  (ref) => createPushNotificationClient(),
);
