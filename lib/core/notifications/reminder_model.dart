import 'push_notification_client.dart';

enum ReminderType { billDue, monthEndReview, allocationDrift }

extension ReminderTypeX on ReminderType {
  String get label {
    return switch (this) {
      ReminderType.billDue => '帳單到期提醒',
      ReminderType.monthEndReview => '月底回顧提醒',
      ReminderType.allocationDrift => '配置偏離提醒',
    };
  }

  String get description {
    return switch (this) {
      ReminderType.billDue => '帳單繳款日前 3 天提醒。',
      ReminderType.monthEndReview => '每月最後一天提醒檢查收支與投資紀律。',
      ReminderType.allocationDrift => '當實際配置偏離目標時提醒你回顧。',
    };
  }
}

class ReminderScheduleResult {
  const ReminderScheduleResult({
    required this.usedFallback,
    required this.scheduledMessages,
    required this.pushPermissionStatus,
  });

  final bool usedFallback;
  final List<String> scheduledMessages;
  final PushPermissionStatus pushPermissionStatus;
}
