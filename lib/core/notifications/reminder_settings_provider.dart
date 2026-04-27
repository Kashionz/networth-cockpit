import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reminder_model.dart';
import 'reminder_service.dart';

class ReminderSettingsState {
  const ReminderSettingsState({
    required this.enabledMap,
    this.lastScheduledAt,
    this.lastMessages = const [],
    this.usedFallback = false,
  });

  factory ReminderSettingsState.initial() {
    return const ReminderSettingsState(
      enabledMap: {
        ReminderType.billDue: true,
        ReminderType.monthEndReview: true,
        ReminderType.allocationDrift: false,
      },
    );
  }

  final Map<ReminderType, bool> enabledMap;
  final DateTime? lastScheduledAt;
  final List<String> lastMessages;
  final bool usedFallback;

  ReminderSettingsState copyWith({
    Map<ReminderType, bool>? enabledMap,
    DateTime? lastScheduledAt,
    bool clearLastScheduledAt = false,
    List<String>? lastMessages,
    bool? usedFallback,
  }) {
    return ReminderSettingsState(
      enabledMap: enabledMap ?? this.enabledMap,
      lastScheduledAt: clearLastScheduledAt
          ? null
          : (lastScheduledAt ?? this.lastScheduledAt),
      lastMessages: lastMessages ?? this.lastMessages,
      usedFallback: usedFallback ?? this.usedFallback,
    );
  }
}

final reminderSettingsControllerProvider =
    NotifierProvider<ReminderSettingsController, ReminderSettingsState>(
      ReminderSettingsController.new,
    );

class ReminderSettingsController extends Notifier<ReminderSettingsState> {
  @override
  ReminderSettingsState build() => ReminderSettingsState.initial();

  void setReminderEnabled(ReminderType type, bool enabled) {
    final next = Map<ReminderType, bool>.from(state.enabledMap);
    next[type] = enabled;
    state = state.copyWith(enabledMap: next);
  }

  Future<ReminderScheduleResult> scheduleActiveReminders() async {
    final service = ref.read(reminderServiceProvider);
    final enabled = state.enabledMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key);

    final result = await service.schedule(enabledReminders: enabled);
    state = state.copyWith(
      lastScheduledAt: DateTime.now(),
      lastMessages: result.scheduledMessages,
      usedFallback: result.usedFallback,
    );
    return result;
  }
}
