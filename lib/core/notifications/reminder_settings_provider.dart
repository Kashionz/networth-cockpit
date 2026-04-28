import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_notification_client.dart';
import 'reminder_model.dart';
import 'reminder_preferences_repository.dart';
import 'reminder_service.dart';

class ReminderSettingsState {
  const ReminderSettingsState({
    required this.enabledMap,
    this.lastScheduledAt,
    this.lastMessages = const [],
    this.usedFallback = false,
    this.pushPermissionStatus = PushPermissionStatus.defaultState,
    this.isHydrated = false,
  });

  factory ReminderSettingsState.initial() {
    return const ReminderSettingsState(enabledMap: _defaults);
  }

  static const Map<ReminderType, bool> _defaults = {
    ReminderType.billDue: true,
    ReminderType.monthEndReview: true,
    ReminderType.allocationDrift: false,
  };

  static Map<ReminderType, bool> defaultEnabledMap() =>
      Map<ReminderType, bool>.from(_defaults);

  final Map<ReminderType, bool> enabledMap;
  final DateTime? lastScheduledAt;
  final List<String> lastMessages;
  final bool usedFallback;
  final PushPermissionStatus pushPermissionStatus;
  final bool isHydrated;

  ReminderSettingsState copyWith({
    Map<ReminderType, bool>? enabledMap,
    DateTime? lastScheduledAt,
    bool clearLastScheduledAt = false,
    List<String>? lastMessages,
    bool? usedFallback,
    PushPermissionStatus? pushPermissionStatus,
    bool? isHydrated,
  }) {
    return ReminderSettingsState(
      enabledMap: enabledMap ?? this.enabledMap,
      lastScheduledAt: clearLastScheduledAt
          ? null
          : (lastScheduledAt ?? this.lastScheduledAt),
      lastMessages: lastMessages ?? this.lastMessages,
      usedFallback: usedFallback ?? this.usedFallback,
      pushPermissionStatus: pushPermissionStatus ?? this.pushPermissionStatus,
      isHydrated: isHydrated ?? this.isHydrated,
    );
  }
}

final reminderSettingsControllerProvider =
    NotifierProvider<ReminderSettingsController, ReminderSettingsState>(
      ReminderSettingsController.new,
    );

class ReminderSettingsController extends Notifier<ReminderSettingsState> {
  bool _startedHydration = false;

  @override
  ReminderSettingsState build() {
    _hydrateFromPreferences();
    return ReminderSettingsState.initial();
  }

  Future<void> setReminderEnabled(ReminderType type, bool enabled) async {
    final next = Map<ReminderType, bool>.from(state.enabledMap);
    next[type] = enabled;
    state = state.copyWith(enabledMap: next);
    await ref
        .read(reminderPreferencesRepositoryProvider)
        .saveEnabledMap(state.enabledMap);
  }

  Future<ReminderScheduleResult> scheduleActiveReminders() async {
    final service = ref.read(reminderServiceProvider);
    final preferencesRepository = ref.read(
      reminderPreferencesRepositoryProvider,
    );
    final enabled = state.enabledMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key);

    final result = await service.schedule(enabledReminders: enabled);
    final scheduledAt = DateTime.now();
    state = state.copyWith(
      lastScheduledAt: scheduledAt,
      lastMessages: result.scheduledMessages,
      usedFallback: result.usedFallback,
      pushPermissionStatus: result.pushPermissionStatus,
    );
    await preferencesRepository.saveScheduleResult(
      scheduledAt: scheduledAt,
      lastMessages: result.scheduledMessages,
      usedFallback: result.usedFallback,
      pushPermissionStatus: result.pushPermissionStatus,
    );
    return result;
  }

  void _hydrateFromPreferences() {
    if (_startedHydration) {
      return;
    }
    _startedHydration = true;
    unawaited(_loadPersistedState());
  }

  Future<void> _loadPersistedState() async {
    final repository = ref.read(reminderPreferencesRepositoryProvider);
    final snapshot = await repository.load(
      defaults: ReminderSettingsState.defaultEnabledMap(),
    );
    state = state.copyWith(
      enabledMap: snapshot.enabledMap,
      lastScheduledAt: snapshot.lastScheduledAt,
      lastMessages: snapshot.lastMessages,
      usedFallback: snapshot.usedFallback,
      pushPermissionStatus: snapshot.pushPermissionStatus,
      isHydrated: true,
    );
  }
}
