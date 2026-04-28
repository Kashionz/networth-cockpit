import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_notification_client.dart';
import 'reminder_model.dart';

abstract class ReminderService {
  Future<ReminderScheduleResult> schedule({
    required Iterable<ReminderType> enabledReminders,
  });
}

class FallbackReminderService implements ReminderService {
  const FallbackReminderService();

  @override
  Future<ReminderScheduleResult> schedule({
    required Iterable<ReminderType> enabledReminders,
  }) async {
    final reminders = enabledReminders.toList(growable: false);
    if (reminders.isEmpty) {
      return const ReminderScheduleResult(
        usedFallback: true,
        scheduledMessages: ['尚未啟用任何提醒項目。'],
        pushPermissionStatus: PushPermissionStatus.defaultState,
      );
    }

    return ReminderScheduleResult(
      usedFallback: true,
      scheduledMessages: [
        for (final reminder in reminders) '已排程提醒：${reminder.label}（應用內提醒骨架）',
      ],
      pushPermissionStatus: PushPermissionStatus.unavailable,
    );
  }
}

class PushReminderService implements ReminderService {
  const PushReminderService({required PushNotificationClient client})
    : _client = client;

  final PushNotificationClient _client;

  @override
  Future<ReminderScheduleResult> schedule({
    required Iterable<ReminderType> enabledReminders,
  }) async {
    final reminders = enabledReminders.toList(growable: false);
    if (reminders.isEmpty) {
      return const ReminderScheduleResult(
        usedFallback: true,
        scheduledMessages: ['尚未啟用任何提醒項目。'],
        pushPermissionStatus: PushPermissionStatus.defaultState,
      );
    }

    final permission = await _client.ensurePermission();
    if (permission != PushPermissionStatus.granted) {
      return ReminderScheduleResult(
        usedFallback: true,
        scheduledMessages: [
          '目前無法啟用推播（${permission.label}），已切換為應用內提醒。',
          for (final reminder in reminders)
            '已排程提醒：${reminder.label}（應用內 fallback）',
        ],
        pushPermissionStatus: permission,
      );
    }

    final messages = <String>[];
    var usedFallback = false;
    for (final reminder in reminders) {
      final body = _buildPushBody(reminder);
      final result = await _client.send(
        title: reminder.label,
        body: body,
        tag: 'networth-${reminder.name}',
      );
      if (result.sent) {
        messages.add('已啟用推播：${reminder.label}');
        continue;
      }

      usedFallback = true;
      final reason = result.reason ?? result.permissionStatus.label;
      messages.add('推播失敗：${reminder.label}（$reason），改為應用內提醒。');
    }

    if (messages.isEmpty) {
      usedFallback = true;
      messages.add('目前無法送出推播，已切換為應用內提醒。');
    }

    return ReminderScheduleResult(
      usedFallback: usedFallback,
      scheduledMessages: messages,
      pushPermissionStatus: permission,
    );
  }

  String _buildPushBody(ReminderType reminder) {
    return switch (reminder) {
      ReminderType.billDue => '本週有帳單到期，建議先完成繳款安排。',
      ReminderType.monthEndReview => '月底回顧時間到了，檢查本月收支與儲蓄率。',
      ReminderType.allocationDrift => '資產配置可能偏離目標，建議檢視再平衡。',
    };
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final client = ref.watch(pushNotificationClientProvider);
  return PushReminderService(client: client);
});
