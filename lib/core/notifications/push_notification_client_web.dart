// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'push_notification_client.dart';

class WebPushNotificationClient implements PushNotificationClient {
  const WebPushNotificationClient();

  @override
  Future<PushPermissionStatus> ensurePermission() async {
    if (!html.Notification.supported) {
      return PushPermissionStatus.unavailable;
    }

    final current = _mapPermission(html.Notification.permission ?? 'default');
    if (current == PushPermissionStatus.granted ||
        current == PushPermissionStatus.denied) {
      return current;
    }

    final next = await html.Notification.requestPermission();
    return _mapPermission(next);
  }

  @override
  Future<PushDeliveryResult> send({
    required String title,
    required String body,
    String? tag,
  }) async {
    if (!html.Notification.supported) {
      return const PushDeliveryResult(
        sent: false,
        permissionStatus: PushPermissionStatus.unavailable,
      );
    }

    final permission = await ensurePermission();
    if (permission != PushPermissionStatus.granted) {
      return PushDeliveryResult(
        sent: false,
        permissionStatus: permission,
        reason: permission.label,
      );
    }

    html.Notification(title, body: body, tag: tag);
    return const PushDeliveryResult(
      sent: true,
      permissionStatus: PushPermissionStatus.granted,
    );
  }

  PushPermissionStatus _mapPermission(String raw) {
    return switch (raw) {
      'granted' => PushPermissionStatus.granted,
      'denied' => PushPermissionStatus.denied,
      'default' => PushPermissionStatus.defaultState,
      _ => PushPermissionStatus.unavailable,
    };
  }
}

PushNotificationClient createPlatformPushNotificationClient() {
  return const WebPushNotificationClient();
}
