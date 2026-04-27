import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      );
    }

    return ReminderScheduleResult(
      usedFallback: true,
      scheduledMessages: [
        for (final reminder in reminders) '已排程提醒：${reminder.label}（應用內提醒骨架）',
      ],
    );
  }
}

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => const FallbackReminderService(),
);
