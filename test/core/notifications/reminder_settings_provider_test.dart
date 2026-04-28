import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/notifications/push_notification_client.dart';
import 'package:networth_cockpit/core/notifications/reminder_model.dart';
import 'package:networth_cockpit/core/notifications/reminder_preferences_repository.dart';
import 'package:networth_cockpit/core/notifications/reminder_service.dart';
import 'package:networth_cockpit/core/notifications/reminder_settings_provider.dart';

void main() {
  test('hydrates persisted reminder settings on build', () async {
    final repository = _FakeReminderPreferencesRepository(
      loadedSnapshot: ReminderPreferencesSnapshot(
        enabledMap: {
          ReminderType.billDue: false,
          ReminderType.monthEndReview: true,
          ReminderType.allocationDrift: true,
        },
        lastScheduledAt: DateTime(2030, 1, 1, 9, 30),
        lastMessages: const ['loaded message'],
        usedFallback: true,
        pushPermissionStatus: PushPermissionStatus.denied,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        reminderPreferencesRepositoryProvider.overrideWithValue(repository),
        reminderServiceProvider.overrideWithValue(
          _FakeReminderService(
            result: const ReminderScheduleResult(
              usedFallback: false,
              scheduledMessages: ['noop'],
              pushPermissionStatus: PushPermissionStatus.granted,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(reminderSettingsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 1));

    final state = container.read(reminderSettingsControllerProvider);
    expect(state.enabledMap[ReminderType.billDue], isFalse);
    expect(state.enabledMap[ReminderType.allocationDrift], isTrue);
    expect(state.lastMessages, ['loaded message']);
    expect(state.usedFallback, isTrue);
    expect(state.pushPermissionStatus, PushPermissionStatus.denied);
    expect(state.isHydrated, isTrue);
  });

  test('persists enabled toggle changes', () async {
    final repository = _FakeReminderPreferencesRepository();
    final container = ProviderContainer(
      overrides: [
        reminderPreferencesRepositoryProvider.overrideWithValue(repository),
        reminderServiceProvider.overrideWithValue(
          _FakeReminderService(
            result: const ReminderScheduleResult(
              usedFallback: false,
              scheduledMessages: ['noop'],
              pushPermissionStatus: PushPermissionStatus.granted,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(reminderSettingsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 1));

    await container
        .read(reminderSettingsControllerProvider.notifier)
        .setReminderEnabled(ReminderType.allocationDrift, true);

    expect(repository.savedEnabledMap?[ReminderType.allocationDrift], isTrue);
  });

  test('saves schedule result after applying reminders', () async {
    final repository = _FakeReminderPreferencesRepository();
    final service = _FakeReminderService(
      result: const ReminderScheduleResult(
        usedFallback: true,
        scheduledMessages: ['fallback message'],
        pushPermissionStatus: PushPermissionStatus.unavailable,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        reminderPreferencesRepositoryProvider.overrideWithValue(repository),
        reminderServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(reminderSettingsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 1));

    final result = await container
        .read(reminderSettingsControllerProvider.notifier)
        .scheduleActiveReminders();

    final state = container.read(reminderSettingsControllerProvider);
    expect(result.usedFallback, isTrue);
    expect(state.lastMessages, ['fallback message']);
    expect(state.pushPermissionStatus, PushPermissionStatus.unavailable);
    expect(repository.lastSavedSchedule, isNotNull);
    expect(
      repository.lastSavedSchedule?.pushPermissionStatus,
      PushPermissionStatus.unavailable,
    );
  });
}

class _FakeReminderService implements ReminderService {
  const _FakeReminderService({required this.result});

  final ReminderScheduleResult result;

  @override
  Future<ReminderScheduleResult> schedule({
    required Iterable<ReminderType> enabledReminders,
  }) async {
    return result;
  }
}

class _SavedScheduleResult {
  const _SavedScheduleResult({
    required this.scheduledAt,
    required this.lastMessages,
    required this.usedFallback,
    required this.pushPermissionStatus,
  });

  final DateTime scheduledAt;
  final List<String> lastMessages;
  final bool usedFallback;
  final PushPermissionStatus pushPermissionStatus;
}

class _FakeReminderPreferencesRepository
    implements ReminderPreferencesRepository {
  _FakeReminderPreferencesRepository({this.loadedSnapshot});

  final ReminderPreferencesSnapshot? loadedSnapshot;

  Map<ReminderType, bool>? savedEnabledMap;
  _SavedScheduleResult? lastSavedSchedule;

  @override
  Future<ReminderPreferencesSnapshot> load({
    required Map<ReminderType, bool> defaults,
  }) async {
    return loadedSnapshot ??
        ReminderPreferencesSnapshot(
          enabledMap: defaults,
          lastScheduledAt: null,
          lastMessages: const [],
          usedFallback: false,
          pushPermissionStatus: PushPermissionStatus.defaultState,
        );
  }

  @override
  Future<void> saveEnabledMap(Map<ReminderType, bool> enabledMap) async {
    savedEnabledMap = Map<ReminderType, bool>.from(enabledMap);
  }

  @override
  Future<void> saveScheduleResult({
    required DateTime scheduledAt,
    required List<String> lastMessages,
    required bool usedFallback,
    required PushPermissionStatus pushPermissionStatus,
  }) async {
    lastSavedSchedule = _SavedScheduleResult(
      scheduledAt: scheduledAt,
      lastMessages: List<String>.from(lastMessages),
      usedFallback: usedFallback,
      pushPermissionStatus: pushPermissionStatus,
    );
  }
}
