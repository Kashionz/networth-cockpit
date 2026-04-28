import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/cards_repository.dart';
import 'package:networth_cockpit/data/repositories/job_runner_repository.dart';
import 'package:networth_cockpit/data/repositories/subscription_repository.dart';
import 'package:networth_cockpit/data/repositories/transaction_repository.dart';
import 'package:networth_cockpit/features/cards/models/credit_card_account.dart';
import 'package:networth_cockpit/features/cards/models/statement_cycle.dart';
import 'package:networth_cockpit/features/subscriptions/models/subscription_item.dart';
import 'package:networth_cockpit/shared/models/money.dart';

void main() {
  test('job kind mapping includes subscription_charge and statement_close', () {
    expect(JobKind.subscriptionCharge.code, 'subscription_charge');
    expect(JobKind.subscriptionCharge.label, '訂閱扣款');
    expect(JobKind.statementClose.code, 'statement_close');
    expect(JobKind.statementClose.label, '帳單結算');
  });

  test('failed runs are tracked as failure records', () async {
    var now = DateTime.utc(2026, 3, 1, 9);
    final repository = JobRunnerRepositoryImpl(
      now: () {
        now = now.add(const Duration(minutes: 1));
        return now;
      },
      attemptDelay: Duration.zero,
    );

    final run = await repository.trigger(JobKind.healthCheck);

    expect(run.status, JobRunStatus.failed);

    final failures = repository.getFailureRecords();
    expect(failures, hasLength(1));
    expect(failures.first.runId, run.id);
    expect(failures.first.kind, JobKind.healthCheck);
    expect(failures.first.message, '重試 2：仍未恢復');
    expect(repository.latestUnacknowledgedFailure()?.runId, run.id);
  });

  test('retry success acknowledges original failure record', () async {
    var now = DateTime.utc(2026, 3, 2, 9);
    final repository = JobRunnerRepositoryImpl(
      now: () {
        now = now.add(const Duration(minutes: 1));
        return now;
      },
      attemptDelay: Duration.zero,
    );

    final failedRun = await repository.trigger(JobKind.healthCheck);
    final retryRun = await repository.retry(failedRun.id);

    expect(retryRun, isNotNull);
    expect(retryRun!.status, JobRunStatus.succeeded);
    expect(repository.latestUnacknowledgedFailure(), isNull);

    final allFailures = repository.getFailureRecords(includeAcknowledged: true);
    expect(allFailures, hasLength(1));
    expect(allFailures.first.isAcknowledged, isTrue);
  });

  test('successful run does not create failure record', () async {
    var now = DateTime.utc(2026, 3, 3, 9);
    final repository = JobRunnerRepositoryImpl(
      now: () {
        now = now.add(const Duration(minutes: 1));
        return now;
      },
      attemptDelay: Duration.zero,
    );

    final run = await repository.trigger(JobKind.monthlyReport);

    expect(run.status, JobRunStatus.succeeded);
    expect(repository.getFailureRecords(), isEmpty);
  });

  test(
    'subscriptionCharge trigger inserts charges and advances subscriptions',
    () async {
      final subscriptionRepository = _FakeSubscriptionRepository(
        seed: [
          SubscriptionItem(
            id: '11111111-1111-4111-a111-111111111111',
            name: 'Netflix',
            category: '娛樂',
            amount: const Money(390, currencyCode: 'TWD'),
            billingCycle: SubscriptionBillingCycle.monthly,
            nextBillingDate: DateTime.utc(2026, 4, 27),
            isActive: true,
            accountId: null,
            creditCardId: null,
            reminderDaysBefore: 3,
            startedOn: DateTime.utc(2025, 4, 27),
            endedOn: null,
            metadata: const <String, dynamic>{},
          ),
        ],
      );
      final transactionRepository = _FakeTransactionRepository();
      var now = DateTime.utc(2026, 4, 27, 0, 30);
      final repository = JobRunnerRepositoryImpl(
        now: () {
          now = now.add(const Duration(minutes: 1));
          return now;
        },
        attemptDelay: Duration.zero,
        subscriptionRepository: subscriptionRepository,
        transactionRepository: transactionRepository,
      );

      final run = await repository.trigger(JobKind.subscriptionCharge);

      expect(run.status, JobRunStatus.succeeded);
      expect(transactionRepository.insertedSubscriptionIds, [
        '11111111-1111-4111-a111-111111111111',
      ]);
      expect(subscriptionRepository.advancedSubscriptionIds, [
        '11111111-1111-4111-a111-111111111111',
      ]);
      expect(run.attempts.single.message, contains('OK Netflix'));
    },
  );

  test(
    'statementClose trigger closes statements for cards due today',
    () async {
      final cardsRepository = _FakeCardsRepository(
        dueCards: [
          CreditCardAccount(
            id: '11111111-1111-4111-a111-111111111111',
            displayName: '國泰 CUBE',
            statementAmount: const Money.twd(12860),
            statementCycle: StatementCycle(
              statementDate: DateTime(2026, 4, 27),
              dueDate: DateTime(2026, 5, 10),
            ),
            lastFourDigits: '1024',
          ),
        ],
      );
      final closeCalls = <String>[];
      var now = DateTime.utc(2026, 4, 27, 0, 30);
      final repository = JobRunnerRepositoryImpl(
        now: () {
          now = now.add(const Duration(minutes: 1));
          return now;
        },
        attemptDelay: Duration.zero,
        cardsRepository: cardsRepository,
        currentUserIdProvider: () => 'user-1',
        closeCurrentStatement:
            ({
              required String cardId,
              required String userId,
              DateTime? onDate,
            }) async {
              closeCalls.add('$userId:$cardId:${onDate?.toUtc().day}');
            },
      );

      final run = await repository.trigger(JobKind.statementClose);

      expect(run.status, JobRunStatus.succeeded);
      expect(closeCalls, ['user-1:11111111-1111-4111-a111-111111111111:27']);
      expect(run.attempts.single.message, contains('status: pending'));
    },
  );
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository({required List<SubscriptionItem> seed})
    : _items = List<SubscriptionItem>.from(seed);

  final List<SubscriptionItem> _items;
  final List<String> advancedSubscriptionIds = <String>[];

  @override
  List<SubscriptionItem> get fallbackSubscriptions =>
      List<SubscriptionItem>.unmodifiable(_items);

  @override
  Future<SubscriptionItem?> advanceNextChargeDate(
    String subscriptionId, {
    DateTime? onDate,
  }) async {
    final index = _items.indexWhere((item) => item.id == subscriptionId);
    if (index < 0) {
      return null;
    }

    final item = _items[index];
    final nextBillingDate = switch (item.billingCycle) {
      SubscriptionBillingCycle.monthly => DateTime.utc(
        item.nextBillingDate.year,
        item.nextBillingDate.month + 1,
        item.nextBillingDate.day,
      ),
      SubscriptionBillingCycle.yearly => DateTime.utc(
        item.nextBillingDate.year + 1,
        item.nextBillingDate.month,
        item.nextBillingDate.day,
      ),
    };
    final updated = item.copyWith(nextBillingDate: nextBillingDate);
    _items[index] = updated;
    advancedSubscriptionIds.add(subscriptionId);
    return updated;
  }

  @override
  Future<List<SubscriptionItem>> createSubscription(
    SubscriptionItem item,
  ) async {
    _items.add(item);
    return List<SubscriptionItem>.unmodifiable(_items);
  }

  @override
  Future<List<SubscriptionItem>> deleteSubscription(
    String subscriptionId,
  ) async {
    _items.removeWhere((item) => item.id == subscriptionId);
    return List<SubscriptionItem>.unmodifiable(_items);
  }

  @override
  Future<List<SubscriptionItem>> fetchDueToday({DateTime? onDate}) async {
    final target = onDate ?? DateTime.now();
    return _items
        .where(
          (item) =>
              item.isActive &&
              !DateTime.utc(
                item.nextBillingDate.year,
                item.nextBillingDate.month,
                item.nextBillingDate.day,
              ).isAfter(DateTime.utc(target.year, target.month, target.day)),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SubscriptionItem>> fetchSubscriptions() async {
    return List<SubscriptionItem>.unmodifiable(_items);
  }

  @override
  Future<SubscriptionDueProcessResult> processDueSubscriptions({
    DateTime? onDate,
  }) async {
    return SubscriptionDueProcessResult(
      executedAt: DateTime.now().toUtc(),
      processedCount: 0,
      processedSubscriptionCount: 0,
      generatedTransactionIds: const <String>[],
      messages: const <String>[],
      usedFallback: true,
      persistedToSupabase: false,
    );
  }

  @override
  Future<List<SubscriptionItem>> updateSubscription(
    SubscriptionItem item,
  ) async {
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    }
    return List<SubscriptionItem>.unmodifiable(_items);
  }
}

class _FakeCardsRepository implements CardsRepository {
  _FakeCardsRepository({required List<CreditCardAccount> dueCards})
    : _dueCards = List<CreditCardAccount>.from(dueCards);

  final List<CreditCardAccount> _dueCards;

  @override
  List<CreditCardAccount> get fallbackCards =>
      List<CreditCardAccount>.unmodifiable(_dueCards);

  @override
  Future<List<CreditCardAccount>> createCard(CreditCardAccount card) async {
    _dueCards.add(card);
    return List<CreditCardAccount>.unmodifiable(_dueCards);
  }

  @override
  Future<List<CreditCardAccount>> deleteCard(String cardId) async {
    _dueCards.removeWhere((card) => card.id == cardId);
    return List<CreditCardAccount>.unmodifiable(_dueCards);
  }

  @override
  Future<List<CreditCardAccount>> fetchCards() async {
    return List<CreditCardAccount>.unmodifiable(_dueCards);
  }

  @override
  Future<List<CreditCardAccount>> fetchCardsWithStatementDueToday({
    DateTime? onDate,
  }) async {
    return List<CreditCardAccount>.unmodifiable(_dueCards);
  }

  @override
  Future<List<CreditCardAccount>> updateCard(CreditCardAccount card) async {
    final index = _dueCards.indexWhere((entry) => entry.id == card.id);
    if (index >= 0) {
      _dueCards[index] = card;
    }
    return List<CreditCardAccount>.unmodifiable(_dueCards);
  }
}

class _FakeTransactionRepository extends TransactionRepository {
  _FakeTransactionRepository();

  final List<String> insertedSubscriptionIds = <String>[];

  @override
  Future<String> insertSubscriptionCharge({
    required SubscriptionItem subscription,
    DateTime? occurredAt,
  }) async {
    insertedSubscriptionIds.add(subscription.id);
    return 'txn-${insertedSubscriptionIds.length}';
  }
}
