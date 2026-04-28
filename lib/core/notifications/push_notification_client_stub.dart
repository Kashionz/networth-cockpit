import 'push_notification_client.dart';

class StubPushNotificationClient implements PushNotificationClient {
  const StubPushNotificationClient();

  @override
  Future<PushPermissionStatus> ensurePermission() async {
    return PushPermissionStatus.unavailable;
  }

  @override
  Future<PushDeliveryResult> send({
    required String title,
    required String body,
    String? tag,
  }) async {
    return const PushDeliveryResult(
      sent: false,
      permissionStatus: PushPermissionStatus.unavailable,
      reason: 'Current platform does not support browser push notifications.',
    );
  }
}

PushNotificationClient createPlatformPushNotificationClient() {
  return const StubPushNotificationClient();
}
