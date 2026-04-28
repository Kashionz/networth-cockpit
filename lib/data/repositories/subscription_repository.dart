import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../features/subscriptions/models/subscription_item.dart';
import '../../shared/models/money.dart';
import '../services/supabase/supabase_client_factory.dart';
import '../services/supabase/supabase_subscriptions_service.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final remoteService = client == null
      ? null
      : SupabaseSubscriptionsService(client: client);

  return SubscriptionRepositoryImpl(remoteService: remoteService);
});

abstract interface class SubscriptionRepository {
  List<SubscriptionItem> get fallbackSubscriptions;

  Future<List<SubscriptionItem>> fetchSubscriptions();

  Future<List<SubscriptionItem>> fetchDueToday({DateTime? onDate});

  Future<List<SubscriptionItem>> createSubscription(SubscriptionItem item);

  Future<List<SubscriptionItem>> updateSubscription(SubscriptionItem item);

  Future<List<SubscriptionItem>> deleteSubscription(String subscriptionId);

  Future<SubscriptionItem?> advanceNextChargeDate(
    String subscriptionId, {
    DateTime? onDate,
  });

  Future<SubscriptionDueProcessResult> processDueSubscriptions({
    DateTime? onDate,
  });
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    SubscriptionsRemoteService? remoteService,
    List<SubscriptionItem>? seedSubscriptions,
  }) : _remoteService = remoteService,
       _localSubscriptions = List<SubscriptionItem>.from(
         seedSubscriptions ?? _seedSubscriptions,
       );

  final SubscriptionsRemoteService? _remoteService;
  List<SubscriptionItem> _localSubscriptions;

  @override
  List<SubscriptionItem> get fallbackSubscriptions =>
      List<SubscriptionItem>.unmodifiable(_localSubscriptions);

  @override
  Future<List<SubscriptionItem>> fetchSubscriptions() async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote == null || userId == null) {
      return _snapshot();
    }

    try {
      final rows = await remote.fetchSubscriptionsByUserId(userId);
      _localSubscriptions = _sorted(
        rows.map(_subscriptionFromRow).toList(growable: false),
      );
      return _snapshot();
    } catch (error, stackTrace) {
      developer.log(
        'fetchSubscriptions remote call failed',
        name: 'SubscriptionRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return _snapshot();
    }
  }

  @override
  Future<List<SubscriptionItem>> fetchDueToday({DateTime? onDate}) async {
    final targetDate = _dayOnlyUtc(onDate ?? DateTime.now());
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote != null && userId != null) {
      try {
        final rows = await remote.fetchDueSubscriptionsByUserId(
          userId: userId,
          onDate: targetDate,
        );
        return _sorted(
          rows
              .map(_subscriptionFromRow)
              .where((item) => _isDue(item, targetDate))
              .toList(growable: false),
        );
      } catch (error, stackTrace) {
        developer.log(
          'fetchDueToday remote call failed',
          name: 'SubscriptionRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return _sorted(
      _localSubscriptions
          .where((item) => _isDue(item, targetDate))
          .toList(growable: false),
    );
  }

  @override
  Future<List<SubscriptionItem>> createSubscription(SubscriptionItem item) {
    return _saveSubscription(item);
  }

  @override
  Future<List<SubscriptionItem>> updateSubscription(SubscriptionItem item) {
    return _saveSubscription(item);
  }

  @override
  Future<List<SubscriptionItem>> deleteSubscription(
    String subscriptionId,
  ) async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote != null && userId != null) {
      try {
        await remote.deleteSubscription(
          userId: userId,
          subscriptionId: subscriptionId,
        );
        return fetchSubscriptions();
      } catch (error, stackTrace) {
        developer.log(
          'deleteSubscription remote call failed',
          name: 'SubscriptionRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _localSubscriptions = _localSubscriptions
        .where((item) => item.id != subscriptionId)
        .toList(growable: false);
    return _snapshot();
  }

  @override
  Future<SubscriptionItem?> advanceNextChargeDate(
    String subscriptionId, {
    DateTime? onDate,
  }) async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;

    SubscriptionItem? current = _findById(subscriptionId);
    if (current == null && remote != null && userId != null) {
      try {
        final rows = await remote.fetchSubscriptionsByUserId(userId);
        _localSubscriptions = _sorted(
          rows.map(_subscriptionFromRow).toList(growable: false),
        );
        current = _findById(subscriptionId);
      } catch (error, stackTrace) {
        developer.log(
          'advanceNextChargeDate refresh failed',
          name: 'SubscriptionRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (current == null) {
      return null;
    }

    final targetDate = _dayOnlyUtc(onDate ?? DateTime.now());
    final schedule = _buildSchedule(item: current, targetDate: targetDate);
    final nextBillingDate = schedule.dueDates.isNotEmpty
        ? schedule.nextBillingDate
        : _nextBillingDate(
            _dayOnlyUtc(current.nextBillingDate),
            current.billingCycle,
          );
    final updated = current.copyWith(nextBillingDate: nextBillingDate);

    if (remote != null && userId != null) {
      try {
        await remote.updateSubscriptionNextBillingDate(
          userId: userId,
          subscriptionId: subscriptionId,
          nextBillingDate: nextBillingDate,
        );
      } catch (error, stackTrace) {
        developer.log(
          'advanceNextChargeDate remote call failed',
          name: 'SubscriptionRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _upsertLocal(updated);
    return updated;
  }

  @override
  Future<SubscriptionDueProcessResult> processDueSubscriptions({
    DateTime? onDate,
  }) async {
    final targetDate = _dayOnlyUtc(onDate ?? DateTime.now());
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;

    if (remote != null && userId != null) {
      try {
        final dueRows = await remote.fetchDueSubscriptionsByUserId(
          userId: userId,
          onDate: targetDate,
        );
        final dueItems = dueRows
            .map(_subscriptionFromRow)
            .where((item) => _isDue(item, targetDate))
            .toList(growable: false);
        final charges = <ProcessedSubscriptionCharge>[];

        for (final item in dueItems) {
          final schedule = _buildSchedule(item: item, targetDate: targetDate);
          if (schedule.dueDates.isEmpty) {
            continue;
          }
          for (final dueDate in schedule.dueDates) {
            final generatedAt = DateTime.now().toUtc();
            final transactionId = await remote.insertTransaction(
              _toTransactionPayload(
                userId: userId,
                item: item,
                dueDate: dueDate,
                generatedAt: generatedAt,
              ),
            );
            charges.add(
              ProcessedSubscriptionCharge(
                subscriptionId: item.id,
                subscriptionName: item.name,
                dueDate: dueDate,
                transactionId: transactionId,
              ),
            );
          }

          await remote.updateSubscriptionNextBillingDate(
            userId: userId,
            subscriptionId: item.id,
            nextBillingDate: schedule.nextBillingDate,
          );
        }

        await fetchSubscriptions();
        return _resultFromCharges(
          charges: charges,
          usedFallback: false,
          persistedToSupabase: true,
          executedAt: DateTime.now().toUtc(),
        );
      } catch (error, stackTrace) {
        developer.log(
          'processDueSubscriptions remote call failed',
          name: 'SubscriptionRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return _processDueLocally(targetDate);
  }

  Future<List<SubscriptionItem>> _saveSubscription(
    SubscriptionItem item,
  ) async {
    final normalized = _normalize(item);
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;

    if (remote != null && userId != null) {
      try {
        await remote.upsertSubscription(
          _toSubscriptionPayload(normalized, userId),
        );
        return fetchSubscriptions();
      } catch (error, stackTrace) {
        developer.log(
          'saveSubscription remote call failed',
          name: 'SubscriptionRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _upsertLocal(normalized);
    return _snapshot();
  }

  SubscriptionDueProcessResult _processDueLocally(DateTime targetDate) {
    final charges = <ProcessedSubscriptionCharge>[];
    final updated = <SubscriptionItem>[];

    for (final item in _localSubscriptions) {
      if (!_isDue(item, targetDate)) {
        updated.add(item);
        continue;
      }

      final schedule = _buildSchedule(item: item, targetDate: targetDate);
      if (schedule.dueDates.isEmpty) {
        updated.add(item);
        continue;
      }

      for (final dueDate in schedule.dueDates) {
        charges.add(
          ProcessedSubscriptionCharge(
            subscriptionId: item.id,
            subscriptionName: item.name,
            dueDate: dueDate,
            transactionId: _generatePseudoUuid(),
          ),
        );
      }

      updated.add(item.copyWith(nextBillingDate: schedule.nextBillingDate));
    }

    _localSubscriptions = _sorted(updated);

    return _resultFromCharges(
      charges: charges,
      usedFallback: true,
      persistedToSupabase: false,
      executedAt: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> _toSubscriptionPayload(
    SubscriptionItem item,
    String userId,
  ) {
    return {
      if (_looksLikeUuid(item.id)) 'id': item.id,
      'user_id': userId,
      'name': item.name,
      'category': item.category,
      'amount': item.amount.amount,
      'currency_code': item.amount.currencyCode,
      'billing_cycle': item.billingCycle.value,
      'next_billing_date': _toDate(item.nextBillingDate),
      'is_active': item.isActive,
      'account_id': item.accountId,
      'credit_card_id': item.creditCardId,
      'reminder_days_before': item.reminderDaysBefore,
      'started_on': _toDateOrNull(item.startedOn),
      'ended_on': _toDateOrNull(item.endedOn),
      'metadata': item.metadata,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _toTransactionPayload({
    required String userId,
    required SubscriptionItem item,
    required DateTime dueDate,
    required DateTime generatedAt,
  }) {
    return {
      'user_id': userId,
      if (item.accountId != null) 'account_id': item.accountId,
      if (item.creditCardId != null) 'credit_card_id': item.creditCardId,
      'transaction_type': 'expense',
      'direction': 'outflow',
      'amount': item.amount.amount,
      'currency_code': item.amount.currencyCode,
      'occurred_at': dueDate.toIso8601String(),
      'merchant': item.name,
      'category': item.category,
      'note': 'Subscription auto charge: ${item.name}',
      'metadata': {
        'source': 'subscription_auto',
        'subscription_id': item.id,
        'billing_cycle': item.billingCycle.value,
        'generated_at': generatedAt.toIso8601String(),
      },
    };
  }

  SubscriptionItem _subscriptionFromRow(Map<String, dynamic> row) {
    final metadata = row['metadata'];
    final metadataMap = metadata is Map
        ? Map<String, dynamic>.from(metadata)
        : const <String, dynamic>{};

    final currencyCode = (row['currency_code']?.toString() ?? 'TWD')
        .trim()
        .toUpperCase();

    return SubscriptionItem(
      id:
          row['id']?.toString() ??
          'sub-local-${DateTime.now().microsecondsSinceEpoch}',
      name: row['name']?.toString() ?? '未命名訂閱',
      category: row['category']?.toString() ?? '其他',
      amount: Money(_toNum(row['amount']) ?? 0, currencyCode: currencyCode),
      billingCycle: SubscriptionBillingCycle.fromRaw(
        row['billing_cycle']?.toString(),
      ),
      nextBillingDate:
          _parseDate(row['next_billing_date']) ?? _dayOnlyUtc(DateTime.now()),
      isActive: _toBool(row['is_active']) ?? true,
      accountId: _normalizeOptional(row['account_id']),
      creditCardId: _normalizeOptional(row['credit_card_id']),
      reminderDaysBefore: _toInt(row['reminder_days_before']) ?? 3,
      startedOn: _parseDate(row['started_on']),
      endedOn: _parseDate(row['ended_on']),
      metadata: metadataMap,
    );
  }

  SubscriptionItem _normalize(SubscriptionItem item) {
    return item.copyWith(
      name: item.name.trim().isEmpty ? '未命名訂閱' : item.name.trim(),
      category: item.category.trim().isEmpty ? '其他' : item.category.trim(),
      amount: Money(
        item.amount.amount,
        currencyCode: item.amount.currencyCode.trim().toUpperCase(),
      ),
      nextBillingDate: _dayOnlyUtc(item.nextBillingDate),
      accountId: _normalizeOptional(item.accountId),
      clearAccountId: _normalizeOptional(item.accountId) == null,
      creditCardId: _normalizeOptional(item.creditCardId),
      clearCreditCardId: _normalizeOptional(item.creditCardId) == null,
      reminderDaysBefore: item.reminderDaysBefore < 0
          ? 0
          : item.reminderDaysBefore,
      startedOn: _dayOnlyOrNull(item.startedOn),
      clearStartedOn: item.startedOn == null,
      endedOn: _dayOnlyOrNull(item.endedOn),
      clearEndedOn: item.endedOn == null,
      metadata: Map<String, dynamic>.from(item.metadata),
    );
  }

  void _upsertLocal(SubscriptionItem item) {
    _localSubscriptions = _sorted([
      item,
      for (final current in _localSubscriptions)
        if (current.id != item.id) current,
    ]);
  }

  SubscriptionItem? _findById(String subscriptionId) {
    return _localSubscriptions.cast<SubscriptionItem?>().firstWhere(
      (item) => item?.id == subscriptionId,
      orElse: () => null,
    );
  }

  _ChargeSchedule _buildSchedule({
    required SubscriptionItem item,
    required DateTime targetDate,
  }) {
    var cursor = _dayOnlyUtc(item.nextBillingDate);
    final dueDates = <DateTime>[];
    var guard = 0;

    while (!cursor.isAfter(targetDate) && _isChargeAllowedOn(item, cursor)) {
      dueDates.add(cursor);
      final next = _nextBillingDate(cursor, item.billingCycle);
      if (!next.isAfter(cursor)) {
        break;
      }
      cursor = next;
      guard += 1;
      if (guard >= 1200) {
        break;
      }
    }

    return _ChargeSchedule(dueDates: dueDates, nextBillingDate: cursor);
  }

  bool _isDue(SubscriptionItem item, DateTime targetDate) {
    if (!item.isActive) {
      return false;
    }
    final nextBillingDate = _dayOnlyUtc(item.nextBillingDate);
    if (nextBillingDate.isAfter(targetDate)) {
      return false;
    }
    if (!_isChargeAllowedOn(item, nextBillingDate)) {
      return false;
    }
    final startedOn = _dayOnlyOrNull(item.startedOn);
    if (startedOn != null && startedOn.isAfter(targetDate)) {
      return false;
    }
    return true;
  }

  bool _isChargeAllowedOn(SubscriptionItem item, DateTime date) {
    final startedOn = _dayOnlyOrNull(item.startedOn);
    if (startedOn != null && date.isBefore(startedOn)) {
      return false;
    }
    final endedOn = _dayOnlyOrNull(item.endedOn);
    if (endedOn != null && date.isAfter(endedOn)) {
      return false;
    }
    return true;
  }

  DateTime _nextBillingDate(DateTime current, SubscriptionBillingCycle cycle) {
    return switch (cycle) {
      SubscriptionBillingCycle.monthly => _addMonthsClamped(current, 1),
      SubscriptionBillingCycle.yearly => _addYearsClamped(current, 1),
    };
  }

  DateTime _addMonthsClamped(DateTime base, int months) {
    final yearOffset = (base.month - 1 + months) ~/ 12;
    final targetYear = base.year + yearOffset;
    final targetMonth = (base.month - 1 + months) % 12 + 1;
    final maxDay = _daysInMonth(targetYear, targetMonth);
    final targetDay = base.day > maxDay ? maxDay : base.day;
    return DateTime.utc(targetYear, targetMonth, targetDay);
  }

  DateTime _addYearsClamped(DateTime base, int years) {
    final targetYear = base.year + years;
    final maxDay = _daysInMonth(targetYear, base.month);
    final targetDay = base.day > maxDay ? maxDay : base.day;
    return DateTime.utc(targetYear, base.month, targetDay);
  }

  int _daysInMonth(int year, int month) {
    return DateTime.utc(year, month + 1, 0).day;
  }

  SubscriptionDueProcessResult _resultFromCharges({
    required List<ProcessedSubscriptionCharge> charges,
    required bool usedFallback,
    required bool persistedToSupabase,
    required DateTime executedAt,
  }) {
    final generatedIds = charges
        .map((charge) => charge.transactionId)
        .toList(growable: false);
    final touched = charges
        .map((charge) => charge.subscriptionId)
        .toSet()
        .length;
    final messages = charges
        .map(
          (charge) =>
              '${charge.subscriptionName} (${_formatDate(charge.dueDate)}) 已建立扣款交易',
        )
        .toList(growable: true);

    if (messages.isEmpty) {
      messages.add('本次沒有需要處理的到期訂閱。');
    }

    return SubscriptionDueProcessResult(
      executedAt: executedAt,
      processedCount: charges.length,
      processedSubscriptionCount: touched,
      generatedTransactionIds: generatedIds,
      messages: messages,
      usedFallback: usedFallback,
      persistedToSupabase: persistedToSupabase,
    );
  }

  List<SubscriptionItem> _snapshot() =>
      List<SubscriptionItem>.unmodifiable(_localSubscriptions);

  List<SubscriptionItem> _sorted(List<SubscriptionItem> items) {
    final sorted = List<SubscriptionItem>.from(items)
      ..sort((a, b) {
        final activeRank = (b.isActive ? 1 : 0) - (a.isActive ? 1 : 0);
        if (activeRank != 0) {
          return activeRank;
        }
        final byDate = a.nextBillingDate.compareTo(b.nextBillingDate);
        if (byDate != 0) {
          return byDate;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return sorted;
  }

  num? _toNum(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString());
  }

  int? _toInt(Object? value) {
    final numValue = _toNum(value);
    if (numValue == null) {
      return null;
    }
    return numValue.toInt();
  }

  bool? _toBool(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return null;
  }

  DateTime? _parseDate(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return null;
    }
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  DateTime _dayOnlyUtc(DateTime value) {
    return DateTime.utc(value.year, value.month, value.day);
  }

  DateTime? _dayOnlyOrNull(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _dayOnlyUtc(value);
  }

  String? _toDateOrNull(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _toDate(value);
  }

  String _toDate(DateTime value) {
    final dayOnly = _dayOnlyUtc(value);
    final year = dayOnly.year.toString().padLeft(4, '0');
    final month = dayOnly.month.toString().padLeft(2, '0');
    final day = dayOnly.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatDate(DateTime value) {
    final dayOnly = _dayOnlyUtc(value);
    return '${dayOnly.year}/${dayOnly.month.toString().padLeft(2, '0')}/${dayOnly.day.toString().padLeft(2, '0')}';
  }

  String? _normalizeOptional(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  String _generatePseudoUuid() {
    final seed = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final normalized = (seed * 3).padRight(32, '0').substring(0, 32);
    return '${normalized.substring(0, 8)}-'
        '${normalized.substring(8, 12)}-'
        '4${normalized.substring(13, 16)}-'
        'a${normalized.substring(17, 20)}-'
        '${normalized.substring(20, 32)}';
  }

  bool _looksLikeUuid(String value) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(value);
  }
}

class ProcessedSubscriptionCharge {
  const ProcessedSubscriptionCharge({
    required this.subscriptionId,
    required this.subscriptionName,
    required this.dueDate,
    required this.transactionId,
  });

  final String subscriptionId;
  final String subscriptionName;
  final DateTime dueDate;
  final String transactionId;
}

class SubscriptionDueProcessResult {
  const SubscriptionDueProcessResult({
    required this.executedAt,
    required this.processedCount,
    required this.processedSubscriptionCount,
    required this.generatedTransactionIds,
    required this.messages,
    required this.usedFallback,
    required this.persistedToSupabase,
  });

  final DateTime executedAt;
  final int processedCount;
  final int processedSubscriptionCount;
  final List<String> generatedTransactionIds;
  final List<String> messages;
  final bool usedFallback;
  final bool persistedToSupabase;
}

class _ChargeSchedule {
  const _ChargeSchedule({
    required this.dueDates,
    required this.nextBillingDate,
  });

  final List<DateTime> dueDates;
  final DateTime nextBillingDate;
}

final _seedSubscriptions = [
  SubscriptionItem(
    id: '33333333-3333-4333-a333-333333333333',
    name: 'Spotify Premium',
    category: '娛樂',
    amount: const Money(149, currencyCode: 'TWD'),
    billingCycle: SubscriptionBillingCycle.monthly,
    nextBillingDate: DateTime.utc(2026, 4, 25),
    isActive: true,
    accountId: null,
    creditCardId: null,
    reminderDaysBefore: 2,
    startedOn: DateTime.utc(2025, 9, 25),
    endedOn: null,
    metadata: {'vendor': 'spotify'},
  ),
  SubscriptionItem(
    id: '44444444-4444-4444-a444-444444444444',
    name: 'Google One',
    category: '雲端服務',
    amount: const Money(650, currencyCode: 'TWD'),
    billingCycle: SubscriptionBillingCycle.yearly,
    nextBillingDate: DateTime.utc(2026, 12, 5),
    isActive: true,
    accountId: null,
    creditCardId: null,
    reminderDaysBefore: 7,
    startedOn: DateTime.utc(2024, 12, 5),
    endedOn: null,
    metadata: {'plan': '2TB'},
  ),
];
