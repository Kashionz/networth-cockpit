import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/subscription_repository.dart';
import 'package:networth_cockpit/features/subscriptions/models/subscription_item.dart';
import 'package:networth_cockpit/shared/models/money.dart';

void main() {
  test(
    'fetchDueToday returns only active subscriptions due on/before date',
    () async {
      final repository = SubscriptionRepositoryImpl(
        seedSubscriptions: [
          SubscriptionItem(
            id: '11111111-1111-4111-a111-111111111111',
            name: 'Netflix',
            category: '娛樂',
            amount: const Money(390, currencyCode: 'TWD'),
            billingCycle: SubscriptionBillingCycle.monthly,
            nextBillingDate: DateTime.utc(2026, 4, 20),
            isActive: true,
            accountId: null,
            creditCardId: null,
            reminderDaysBefore: 3,
            startedOn: DateTime.utc(2025, 4, 20),
            endedOn: null,
            metadata: const <String, dynamic>{},
          ),
          SubscriptionItem(
            id: '22222222-2222-4222-a222-222222222222',
            name: 'YouTube Premium',
            category: '娛樂',
            amount: const Money(199, currencyCode: 'TWD'),
            billingCycle: SubscriptionBillingCycle.monthly,
            nextBillingDate: DateTime.utc(2026, 5, 1),
            isActive: true,
            accountId: null,
            creditCardId: null,
            reminderDaysBefore: 3,
            startedOn: DateTime.utc(2025, 1, 1),
            endedOn: null,
            metadata: const <String, dynamic>{},
          ),
          SubscriptionItem(
            id: '33333333-3333-4333-a333-333333333333',
            name: 'Dropbox',
            category: '雲端',
            amount: const Money(350, currencyCode: 'TWD'),
            billingCycle: SubscriptionBillingCycle.monthly,
            nextBillingDate: DateTime.utc(2026, 4, 15),
            isActive: false,
            accountId: null,
            creditCardId: null,
            reminderDaysBefore: 3,
            startedOn: DateTime.utc(2025, 1, 1),
            endedOn: null,
            metadata: const <String, dynamic>{},
          ),
        ],
      );

      final dueItems = await repository.fetchDueToday(
        onDate: DateTime.utc(2026, 4, 27),
      );

      expect(dueItems.map((item) => item.id), [
        '11111111-1111-4111-a111-111111111111',
      ]);
    },
  );

  test(
    'advanceNextChargeDate moves due subscription to its next cycle',
    () async {
      final repository = SubscriptionRepositoryImpl(
        seedSubscriptions: [
          SubscriptionItem(
            id: '11111111-1111-4111-a111-111111111111',
            name: 'Monthly Edge Case',
            category: '工具',
            amount: const Money(120, currencyCode: 'TWD'),
            billingCycle: SubscriptionBillingCycle.monthly,
            nextBillingDate: DateTime.utc(2026, 1, 31),
            isActive: true,
            accountId: null,
            creditCardId: null,
            reminderDaysBefore: 3,
            startedOn: DateTime.utc(2025, 1, 31),
            endedOn: null,
            metadata: const <String, dynamic>{},
          ),
        ],
      );

      final updated = await repository.advanceNextChargeDate(
        '11111111-1111-4111-a111-111111111111',
        onDate: DateTime.utc(2026, 1, 31),
      );

      expect(updated, isNotNull);
      expect(updated!.nextBillingDate, DateTime.utc(2026, 2, 28));

      final items = await repository.fetchSubscriptions();
      expect(items.single.nextBillingDate, DateTime.utc(2026, 2, 28));
    },
  );

  test(
    'processDueSubscriptions creates due transactions and advances next billing date',
    () async {
      final repository = SubscriptionRepositoryImpl(
        seedSubscriptions: [
          SubscriptionItem(
            id: '11111111-1111-4111-a111-111111111111',
            name: 'Netflix',
            category: '娛樂',
            amount: const Money(390, currencyCode: 'TWD'),
            billingCycle: SubscriptionBillingCycle.monthly,
            nextBillingDate: DateTime.utc(2026, 4, 20),
            isActive: true,
            accountId: null,
            creditCardId: null,
            reminderDaysBefore: 3,
            startedOn: DateTime.utc(2025, 4, 20),
            endedOn: null,
            metadata: const <String, dynamic>{},
          ),
        ],
      );

      final result = await repository.processDueSubscriptions(
        onDate: DateTime.utc(2026, 4, 27),
      );

      expect(result.processedCount, 1);
      expect(result.processedSubscriptionCount, 1);
      expect(result.generatedTransactionIds, hasLength(1));

      final items = await repository.fetchSubscriptions();
      expect(items.single.nextBillingDate, DateTime.utc(2026, 5, 20));

      final rerun = await repository.processDueSubscriptions(
        onDate: DateTime.utc(2026, 4, 27),
      );
      expect(rerun.processedCount, 0);
      expect(rerun.generatedTransactionIds, isEmpty);
    },
  );

  test(
    'processDueSubscriptions ignores non-due and inactive subscriptions',
    () async {
      final repository = SubscriptionRepositoryImpl(
        seedSubscriptions: [
          SubscriptionItem(
            id: '22222222-2222-4222-a222-222222222222',
            name: 'YouTube Premium',
            category: '娛樂',
            amount: const Money(199, currencyCode: 'TWD'),
            billingCycle: SubscriptionBillingCycle.monthly,
            nextBillingDate: DateTime.utc(2026, 5, 1),
            isActive: true,
            accountId: null,
            creditCardId: null,
            reminderDaysBefore: 3,
            startedOn: DateTime.utc(2025, 1, 1),
            endedOn: null,
            metadata: const <String, dynamic>{},
          ),
          SubscriptionItem(
            id: '33333333-3333-4333-a333-333333333333',
            name: 'Dropbox',
            category: '雲端',
            amount: const Money(350, currencyCode: 'TWD'),
            billingCycle: SubscriptionBillingCycle.monthly,
            nextBillingDate: DateTime.utc(2026, 4, 15),
            isActive: false,
            accountId: null,
            creditCardId: null,
            reminderDaysBefore: 3,
            startedOn: DateTime.utc(2025, 1, 1),
            endedOn: null,
            metadata: const <String, dynamic>{},
          ),
        ],
      );

      final result = await repository.processDueSubscriptions(
        onDate: DateTime.utc(2026, 4, 27),
      );

      expect(result.processedCount, 0);
      expect(result.generatedTransactionIds, isEmpty);

      final items = await repository.fetchSubscriptions();
      expect(
        items.firstWhere((item) => item.id.startsWith('2222')).nextBillingDate,
        DateTime.utc(2026, 5, 1),
      );
      expect(
        items.firstWhere((item) => item.id.startsWith('3333')).nextBillingDate,
        DateTime.utc(2026, 4, 15),
      );
    },
  );
}
