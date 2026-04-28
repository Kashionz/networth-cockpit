import '../../../shared/models/money.dart';

enum SubscriptionBillingCycle {
  monthly,
  yearly;

  String get value => switch (this) {
    SubscriptionBillingCycle.monthly => 'monthly',
    SubscriptionBillingCycle.yearly => 'yearly',
  };

  String get label => switch (this) {
    SubscriptionBillingCycle.monthly => '每月',
    SubscriptionBillingCycle.yearly => '每年',
  };

  static SubscriptionBillingCycle fromRaw(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'yearly' => SubscriptionBillingCycle.yearly,
      _ => SubscriptionBillingCycle.monthly,
    };
  }
}

class SubscriptionItem {
  const SubscriptionItem({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.isActive,
    this.accountId,
    this.creditCardId,
    required this.reminderDaysBefore,
    this.startedOn,
    this.endedOn,
    required this.metadata,
  });

  final String id;
  final String name;
  final String category;
  final Money amount;
  final String? accountId;
  final String? creditCardId;
  final SubscriptionBillingCycle billingCycle;
  final DateTime nextBillingDate;
  final bool isActive;
  final int reminderDaysBefore;
  final DateTime? startedOn;
  final DateTime? endedOn;
  final Map<String, dynamic> metadata;

  SubscriptionItem copyWith({
    String? id,
    String? name,
    String? category,
    Money? amount,
    String? accountId,
    bool clearAccountId = false,
    String? creditCardId,
    bool clearCreditCardId = false,
    SubscriptionBillingCycle? billingCycle,
    DateTime? nextBillingDate,
    bool? isActive,
    int? reminderDaysBefore,
    DateTime? startedOn,
    bool clearStartedOn = false,
    DateTime? endedOn,
    bool clearEndedOn = false,
    Map<String, dynamic>? metadata,
  }) {
    return SubscriptionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      accountId: clearAccountId ? null : accountId ?? this.accountId,
      creditCardId: clearCreditCardId
          ? null
          : creditCardId ?? this.creditCardId,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      isActive: isActive ?? this.isActive,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      startedOn: clearStartedOn ? null : startedOn ?? this.startedOn,
      endedOn: clearEndedOn ? null : endedOn ?? this.endedOn,
      metadata: metadata ?? this.metadata,
    );
  }
}
