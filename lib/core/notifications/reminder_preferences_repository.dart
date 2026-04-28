import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'push_notification_client.dart';
import 'reminder_model.dart';

final reminderPreferencesRepositoryProvider =
    Provider<ReminderPreferencesRepository>((ref) {
      return SharedPrefsReminderPreferencesRepository();
    });

class ReminderPreferencesSnapshot {
  const ReminderPreferencesSnapshot({
    required this.enabledMap,
    required this.lastScheduledAt,
    required this.lastMessages,
    required this.usedFallback,
    required this.pushPermissionStatus,
  });

  final Map<ReminderType, bool> enabledMap;
  final DateTime? lastScheduledAt;
  final List<String> lastMessages;
  final bool usedFallback;
  final PushPermissionStatus pushPermissionStatus;
}

abstract interface class ReminderPreferencesRepository {
  Future<ReminderPreferencesSnapshot> load({
    required Map<ReminderType, bool> defaults,
  });

  Future<void> saveEnabledMap(Map<ReminderType, bool> enabledMap);

  Future<void> saveScheduleResult({
    required DateTime scheduledAt,
    required List<String> lastMessages,
    required bool usedFallback,
    required PushPermissionStatus pushPermissionStatus,
  });
}

class SharedPrefsReminderPreferencesRepository
    implements ReminderPreferencesRepository {
  static const _kEnabledPrefix = 'reminder_enabled_';
  static const _kLastScheduledAt = 'reminder_last_scheduled_at';
  static const _kLastMessages = 'reminder_last_messages';
  static const _kUsedFallback = 'reminder_last_used_fallback';
  static const _kPushPermission = 'reminder_push_permission';

  @override
  Future<ReminderPreferencesSnapshot> load({
    required Map<ReminderType, bool> defaults,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = <ReminderType, bool>{};

    for (final type in ReminderType.values) {
      final stored = prefs.getBool(_enabledKey(type));
      enabled[type] = stored ?? (defaults[type] ?? false);
    }

    final lastScheduledRaw = prefs.getString(_kLastScheduledAt);
    final lastScheduledAt = lastScheduledRaw == null
        ? null
        : DateTime.tryParse(lastScheduledRaw)?.toLocal();
    final lastMessagesRaw = prefs.getString(_kLastMessages);
    final lastMessages = _decodeMessages(lastMessagesRaw);
    final usedFallback = prefs.getBool(_kUsedFallback) ?? false;
    final pushPermission = _decodePushPermission(
      prefs.getString(_kPushPermission),
    );

    return ReminderPreferencesSnapshot(
      enabledMap: enabled,
      lastScheduledAt: lastScheduledAt,
      lastMessages: lastMessages,
      usedFallback: usedFallback,
      pushPermissionStatus: pushPermission,
    );
  }

  @override
  Future<void> saveEnabledMap(Map<ReminderType, bool> enabledMap) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in enabledMap.entries) {
      await prefs.setBool(_enabledKey(entry.key), entry.value);
    }
  }

  @override
  Future<void> saveScheduleResult({
    required DateTime scheduledAt,
    required List<String> lastMessages,
    required bool usedFallback,
    required PushPermissionStatus pushPermissionStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kLastScheduledAt,
      scheduledAt.toUtc().toIso8601String(),
    );
    await prefs.setString(_kLastMessages, jsonEncode(lastMessages));
    await prefs.setBool(_kUsedFallback, usedFallback);
    await prefs.setString(_kPushPermission, pushPermissionStatus.name);
  }

  String _enabledKey(ReminderType type) => '$_kEnabledPrefix${type.name}';

  List<String> _decodeMessages(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((message) => message.toString())
            .where((message) => message.trim().isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {
      // Ignore invalid local cache format.
    }
    return const [];
  }

  PushPermissionStatus _decodePushPermission(String? raw) {
    if (raw == null) {
      return PushPermissionStatus.defaultState;
    }
    for (final status in PushPermissionStatus.values) {
      if (status.name == raw) {
        return status;
      }
    }
    return PushPermissionStatus.defaultState;
  }
}
