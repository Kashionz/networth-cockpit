import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/notifications/push_notification_client.dart';
import 'package:networth_cockpit/core/notifications/reminder_model.dart';
import 'package:networth_cockpit/core/notifications/reminder_service.dart';

void main() {
  test('returns fallback when no reminder is enabled', () async {
    final service = PushReminderService(client: _FakePushNotificationClient());

    final result = await service.schedule(enabledReminders: const []);

    expect(result.usedFallback, isTrue);
    expect(result.pushPermissionStatus, PushPermissionStatus.defaultState);
    expect(result.scheduledMessages, ['尚未啟用任何提醒項目。']);
  });

  test('falls back when push permission is denied', () async {
    final service = PushReminderService(
      client: _FakePushNotificationClient(
        ensurePermissionResult: PushPermissionStatus.denied,
      ),
    );

    final result = await service.schedule(
      enabledReminders: const [ReminderType.billDue],
    );

    expect(result.usedFallback, isTrue);
    expect(result.pushPermissionStatus, PushPermissionStatus.denied);
    expect(
      result.scheduledMessages.first,
      contains('目前無法啟用推播（已封鎖推播），已切換為應用內提醒。'),
    );
    expect(result.scheduledMessages.last, contains('帳單到期提醒'));
  });

  test('sends push when permission is granted', () async {
    final client = _FakePushNotificationClient(
      ensurePermissionResult: PushPermissionStatus.granted,
    );
    final service = PushReminderService(client: client);

    final result = await service.schedule(
      enabledReminders: const [
        ReminderType.billDue,
        ReminderType.monthEndReview,
      ],
    );

    expect(result.usedFallback, isFalse);
    expect(result.pushPermissionStatus, PushPermissionStatus.granted);
    expect(result.scheduledMessages, hasLength(2));
    expect(client.sentRequests, hasLength(2));
  });
}

class _FakePushNotificationClient implements PushNotificationClient {
  _FakePushNotificationClient({
    this.ensurePermissionResult = PushPermissionStatus.unavailable,
  });

  final PushPermissionStatus ensurePermissionResult;
  final List<_PushRequest> sentRequests = <_PushRequest>[];

  @override
  Future<PushPermissionStatus> ensurePermission() async {
    return ensurePermissionResult;
  }

  @override
  Future<PushDeliveryResult> send({
    required String title,
    required String body,
    String? tag,
  }) async {
    sentRequests.add(_PushRequest(title: title, body: body, tag: tag));
    return const PushDeliveryResult(
      sent: true,
      permissionStatus: PushPermissionStatus.granted,
    );
  }
}

class _PushRequest {
  const _PushRequest({required this.title, required this.body, this.tag});

  final String title;
  final String body;
  final String? tag;
}
