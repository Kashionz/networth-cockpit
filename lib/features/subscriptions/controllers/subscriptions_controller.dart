import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/subscription_repository.dart';
import '../../../shared/models/money.dart';
import '../models/subscription_item.dart';

final subscriptionsControllerProvider =
    NotifierProvider<SubscriptionsController, SubscriptionsState>(
      SubscriptionsController.new,
    );

class SubscriptionsController extends Notifier<SubscriptionsState> {
  late final SubscriptionRepository _repository;

  @override
  SubscriptionsState build() {
    _repository = ref.read(subscriptionRepositoryProvider);
    Future<void>.microtask(_initialize);
    return SubscriptionsState.initial(
      subscriptions: _repository.fallbackSubscriptions,
    );
  }

  Future<void> _initialize() async {
    await reload();
    await processDueSubscriptions(manual: false);
  }

  Future<void> reload() async {
    final loaded = await _repository.fetchSubscriptions();
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(subscriptions: loaded);
  }

  Future<void> createSubscription({
    required String name,
    required String category,
    required num amount,
    required String currencyCode,
    required SubscriptionBillingCycle billingCycle,
    required DateTime nextBillingDate,
    required bool isActive,
    String? accountId,
    String? creditCardId,
    required int reminderDaysBefore,
    DateTime? startedOn,
    DateTime? endedOn,
    Map<String, dynamic>? metadata,
  }) async {
    final created = SubscriptionItem(
      id: _generatePseudoUuid(),
      name: name,
      category: category,
      amount: Money(amount, currencyCode: currencyCode),
      billingCycle: billingCycle,
      nextBillingDate: nextBillingDate,
      isActive: isActive,
      accountId: accountId,
      creditCardId: creditCardId,
      reminderDaysBefore: reminderDaysBefore,
      startedOn: startedOn,
      endedOn: endedOn,
      metadata: metadata ?? const <String, dynamic>{},
    );

    state = state.copyWith(subscriptions: [created, ...state.subscriptions]);

    final next = await _repository.createSubscription(created);
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(subscriptions: next);
  }

  Future<void> updateSubscription(SubscriptionItem updated) async {
    state = state.copyWith(
      subscriptions: [
        for (final item in state.subscriptions)
          if (item.id == updated.id) updated else item,
      ],
    );

    final next = await _repository.updateSubscription(updated);
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(subscriptions: next);
  }

  Future<void> toggleActive(String subscriptionId, bool isActive) async {
    SubscriptionItem? target;
    for (final item in state.subscriptions) {
      if (item.id == subscriptionId) {
        target = item;
        break;
      }
    }
    if (target == null) {
      return;
    }

    await updateSubscription(target.copyWith(isActive: isActive));
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    state = state.copyWith(
      subscriptions: state.subscriptions
          .where((item) => item.id != subscriptionId)
          .toList(growable: false),
    );

    final next = await _repository.deleteSubscription(subscriptionId);
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(subscriptions: next);
  }

  Future<SubscriptionDueProcessResult> processDueSubscriptions({
    DateTime? onDate,
    bool manual = true,
  }) async {
    state = state.copyWith(isProcessingDue: true);

    final result = await _repository.processDueSubscriptions(onDate: onDate);
    final subscriptions = await _repository.fetchSubscriptions();
    if (!ref.mounted) {
      return result;
    }

    state = state.copyWith(
      subscriptions: subscriptions,
      isProcessingDue: false,
      lastDueRunAt: result.executedAt,
      lastDueProcessedCount: result.processedCount,
      lastDueRunMessage: _buildRunMessage(result, manual: manual),
    );

    return result;
  }

  String _buildRunMessage(
    SubscriptionDueProcessResult result, {
    required bool manual,
  }) {
    final sourceLabel = manual ? '手動執行' : '自動檢查';
    final cloudLabel = result.persistedToSupabase ? '已同步雲端' : '本機模式';
    return '$sourceLabel：已處理 ${result.processedCount} 筆扣款 '
        '(涉及 ${result.processedSubscriptionCount} 個訂閱) · $cloudLabel';
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
}

class SubscriptionsState {
  SubscriptionsState({
    required List<SubscriptionItem> subscriptions,
    required this.isProcessingDue,
    this.lastDueRunMessage,
    this.lastDueRunAt,
    required this.lastDueProcessedCount,
  }) : subscriptions = List<SubscriptionItem>.unmodifiable(subscriptions);

  factory SubscriptionsState.initial({List<SubscriptionItem>? subscriptions}) {
    return SubscriptionsState(
      subscriptions: subscriptions ?? const <SubscriptionItem>[],
      isProcessingDue: false,
      lastDueRunMessage: null,
      lastDueRunAt: null,
      lastDueProcessedCount: 0,
    );
  }

  final List<SubscriptionItem> subscriptions;
  final bool isProcessingDue;
  final String? lastDueRunMessage;
  final DateTime? lastDueRunAt;
  final int lastDueProcessedCount;

  SubscriptionsState copyWith({
    List<SubscriptionItem>? subscriptions,
    bool? isProcessingDue,
    String? lastDueRunMessage,
    DateTime? lastDueRunAt,
    int? lastDueProcessedCount,
  }) {
    return SubscriptionsState(
      subscriptions: subscriptions ?? this.subscriptions,
      isProcessingDue: isProcessingDue ?? this.isProcessingDue,
      lastDueRunMessage: lastDueRunMessage ?? this.lastDueRunMessage,
      lastDueRunAt: lastDueRunAt ?? this.lastDueRunAt,
      lastDueProcessedCount:
          lastDueProcessedCount ?? this.lastDueProcessedCount,
    );
  }
}
