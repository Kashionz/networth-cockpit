import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../services/supabase/supabase_cards_service.dart';
import '../services/supabase/supabase_client_factory.dart';
import 'cards_repository.dart';
import 'subscription_repository.dart';
import 'transaction_repository.dart';

final jobRunnerRepositoryProvider = Provider<JobRunnerRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final cardsService = client == null
      ? null
      : SupabaseCardsService(client: client);

  return JobRunnerRepositoryImpl(
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    cardsRepository: ref.watch(cardsRepositoryProvider),
    currentUserIdProvider: () => cardsService?.currentUser?.id,
    closeCurrentStatement: cardsService == null
        ? null
        : ({required String cardId, required String userId, DateTime? onDate}) {
            return cardsService.closeCurrentStatement(
              cardId: cardId,
              userId: userId,
              onDate: onDate,
            );
          },
  );
});

abstract interface class JobRunnerRepository {
  List<JobRun> getRuns();

  Future<JobRun> trigger(JobKind kind);

  Future<JobRun?> retry(String runId);

  List<JobFailureRecord> getFailureRecords({bool includeAcknowledged});

  JobFailureRecord? latestUnacknowledgedFailure();

  bool acknowledgeFailure(String runId);
}

enum JobKind {
  updatePrices,
  dailySnapshot,
  monthlyReport,
  healthCheck,
  subscriptionCharge,
  statementClose,
}

extension JobKindX on JobKind {
  String get code => switch (this) {
    JobKind.updatePrices => 'update_prices',
    JobKind.dailySnapshot => 'daily_snapshot',
    JobKind.monthlyReport => 'monthly_report',
    JobKind.healthCheck => 'health_check',
    JobKind.subscriptionCharge => 'subscription_charge',
    JobKind.statementClose => 'statement_close',
  };

  String get label => switch (this) {
    JobKind.updatePrices => '更新行情',
    JobKind.dailySnapshot => '每日快照',
    JobKind.monthlyReport => '月報彙整',
    JobKind.healthCheck => '健康檢查',
    JobKind.subscriptionCharge => '訂閱扣款',
    JobKind.statementClose => '帳單結算',
  };
}

enum JobRunStatus { succeeded, failed }

extension JobRunStatusX on JobRunStatus {
  String get label => switch (this) {
    JobRunStatus.succeeded => '成功',
    JobRunStatus.failed => '失敗',
  };
}

class JobAttempt {
  const JobAttempt({
    required this.attempt,
    required this.startedAt,
    required this.finishedAt,
    required this.success,
    required this.message,
  });

  final int attempt;
  final DateTime startedAt;
  final DateTime finishedAt;
  final bool success;
  final String message;
}

class JobRun {
  const JobRun({
    required this.id,
    required this.kind,
    required this.status,
    required this.requestedAt,
    required this.finishedAt,
    required this.attempts,
    this.retryOfRunId,
  });

  final String id;
  final JobKind kind;
  final JobRunStatus status;
  final DateTime requestedAt;
  final DateTime finishedAt;
  final List<JobAttempt> attempts;
  final String? retryOfRunId;

  int get retryCount => attempts.length <= 1 ? 0 : attempts.length - 1;
}

class JobFailureRecord {
  const JobFailureRecord({
    required this.runId,
    required this.kind,
    required this.failedAt,
    required this.message,
    this.acknowledgedAt,
  });

  final String runId;
  final JobKind kind;
  final DateTime failedAt;
  final String message;
  final DateTime? acknowledgedAt;

  bool get isAcknowledged => acknowledgedAt != null;

  JobFailureRecord copyWith({DateTime? acknowledgedAt}) {
    return JobFailureRecord(
      runId: runId,
      kind: kind,
      failedAt: failedAt,
      message: message,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }
}

class JobRunnerRepositoryImpl implements JobRunnerRepository {
  JobRunnerRepositoryImpl({
    DateTime Function()? now,
    Duration attemptDelay = const Duration(milliseconds: 100),
    SubscriptionRepository? subscriptionRepository,
    TransactionRepository? transactionRepository,
    CardsRepository? cardsRepository,
    String? Function()? currentUserIdProvider,
    Future<void> Function({
      required String cardId,
      required String userId,
      DateTime? onDate,
    })?
    closeCurrentStatement,
  }) : _now = now ?? DateTime.now,
       _attemptDelay = attemptDelay,
       _subscriptionRepository = subscriptionRepository,
       _transactionRepository = transactionRepository,
       _cardsRepository = cardsRepository,
       _currentUserIdProvider = currentUserIdProvider,
       _closeCurrentStatement = closeCurrentStatement;

  final DateTime Function() _now;
  final Duration _attemptDelay;
  final SubscriptionRepository? _subscriptionRepository;
  final TransactionRepository? _transactionRepository;
  final CardsRepository? _cardsRepository;
  final String? Function()? _currentUserIdProvider;
  final Future<void> Function({
    required String cardId,
    required String userId,
    DateTime? onDate,
  })?
  _closeCurrentStatement;
  final List<JobRun> _runs = <JobRun>[];
  final List<JobFailureRecord> _failureRecords = <JobFailureRecord>[];
  int _runCounter = 0;

  @override
  List<JobRun> getRuns() => List<JobRun>.unmodifiable(_runs);

  @override
  Future<JobRun> trigger(JobKind kind) {
    return _runInternal(kind: kind);
  }

  @override
  Future<JobRun?> retry(String runId) async {
    final target = _runs.cast<JobRun?>().firstWhere(
      (run) => run?.id == runId,
      orElse: () => null,
    );
    if (target == null || target.status != JobRunStatus.failed) {
      return null;
    }

    final retryRun = await _runInternal(
      kind: target.kind,
      retryOfRunId: target.id,
    );
    if (retryRun.status == JobRunStatus.succeeded) {
      acknowledgeFailure(runId);
    }
    return retryRun;
  }

  @override
  List<JobFailureRecord> getFailureRecords({bool includeAcknowledged = false}) {
    final records = includeAcknowledged
        ? _failureRecords
        : _failureRecords.where((record) => !record.isAcknowledged);
    return List<JobFailureRecord>.unmodifiable(records);
  }

  @override
  JobFailureRecord? latestUnacknowledgedFailure() {
    return _failureRecords.cast<JobFailureRecord?>().firstWhere(
      (record) => record != null && !record.isAcknowledged,
      orElse: () => null,
    );
  }

  @override
  bool acknowledgeFailure(String runId) {
    final index = _failureRecords.indexWhere(
      (record) => record.runId == runId && !record.isAcknowledged,
    );
    if (index < 0) {
      return false;
    }
    final now = _now().toUtc();
    _failureRecords[index] = _failureRecords[index].copyWith(
      acknowledgedAt: now,
    );
    return true;
  }

  Future<JobRun> _runInternal({
    required JobKind kind,
    String? retryOfRunId,
  }) async {
    final runId = 'run-${++_runCounter}';
    final requestedAt = _now().toUtc();
    final attempts = <JobAttempt>[];

    final outcomes = await _resolveOutcomes(
      kind: kind,
      retryOfRunId: retryOfRunId,
    );
    for (var i = 0; i < outcomes.length; i++) {
      final outcome = outcomes[i];
      final startedAt = _now().toUtc();
      await Future<void>.delayed(_attemptDelay);
      final finishedAt = _now().toUtc();
      attempts.add(
        JobAttempt(
          attempt: i + 1,
          startedAt: startedAt,
          finishedAt: finishedAt,
          success: outcome.success,
          message: outcome.message,
        ),
      );
      if (outcome.success) {
        break;
      }
    }

    final latestAttempt = attempts.last;
    final run = JobRun(
      id: runId,
      kind: kind,
      status: latestAttempt.success
          ? JobRunStatus.succeeded
          : JobRunStatus.failed,
      requestedAt: requestedAt,
      finishedAt: latestAttempt.finishedAt,
      attempts: List<JobAttempt>.unmodifiable(attempts),
      retryOfRunId: retryOfRunId,
    );
    _runs.insert(0, run);
    if (run.status == JobRunStatus.failed) {
      _failureRecords.insert(
        0,
        JobFailureRecord(
          runId: run.id,
          kind: run.kind,
          failedAt: run.finishedAt,
          message: latestAttempt.message,
        ),
      );
    }
    return run;
  }

  Future<List<_AttemptOutcome>> _resolveOutcomes({
    required JobKind kind,
    required String? retryOfRunId,
  }) async {
    if (retryOfRunId != null) {
      return const [_AttemptOutcome(success: true, message: '手動重試完成')];
    }

    return switch (kind) {
      JobKind.updatePrices => const [
        _AttemptOutcome(success: false, message: '來源 API 暫時無回應'),
        _AttemptOutcome(success: true, message: '第二次重試成功'),
      ],
      JobKind.dailySnapshot => const [
        _AttemptOutcome(success: true, message: '快照已寫入'),
      ],
      JobKind.monthlyReport => const [
        _AttemptOutcome(success: true, message: '月報資料已更新'),
      ],
      JobKind.healthCheck => const [
        _AttemptOutcome(success: false, message: '健康檢查逾時'),
        _AttemptOutcome(success: false, message: '重試 1：資料庫 ping 失敗'),
        _AttemptOutcome(success: false, message: '重試 2：仍未恢復'),
      ],
      JobKind.subscriptionCharge => [await _runSubscriptionCharge()],
      JobKind.statementClose => [await _runStatementClose()],
    };
  }

  Future<_AttemptOutcome> _runSubscriptionCharge() async {
    final subscriptions = _subscriptionRepository;
    final transactions = _transactionRepository;
    if (subscriptions == null || transactions == null) {
      return const _AttemptOutcome(success: false, message: '訂閱扣款依賴未設定');
    }

    final targetDate = _dayOnlyUtc(_now());
    try {
      final dueItems = await subscriptions.fetchDueToday(onDate: targetDate);
      if (dueItems.isEmpty) {
        return const _AttemptOutcome(success: true, message: '本次沒有到期訂閱，略過扣款。');
      }

      var successCount = 0;
      var failedCount = 0;
      final details = <String>[];
      for (final item in dueItems) {
        try {
          final transactionId = await transactions.insertSubscriptionCharge(
            subscription: item,
            occurredAt: targetDate,
          );
          final updated = await subscriptions.advanceNextChargeDate(
            item.id,
            onDate: targetDate,
          );
          successCount += 1;
          details.add(
            'OK ${item.name}（txn:$transactionId，next:${_formatDate(updated?.nextBillingDate ?? item.nextBillingDate)}）',
          );
        } catch (error) {
          failedCount += 1;
          details.add('FAIL ${item.name}（$error）');
        }
      }

      return _AttemptOutcome(
        success: failedCount == 0,
        message: _composeSummary(
          headline:
              '訂閱扣款完成：成功 $successCount / ${dueItems.length}${failedCount > 0 ? '，失敗 $failedCount' : ''}',
          details: details,
        ),
      );
    } catch (error) {
      return _AttemptOutcome(success: false, message: '訂閱扣款執行失敗（$error）');
    }
  }

  Future<_AttemptOutcome> _runStatementClose() async {
    final cards = _cardsRepository;
    if (cards == null) {
      return const _AttemptOutcome(success: false, message: '帳單結算依賴未設定');
    }

    final targetDate = _dayOnlyUtc(_now());
    try {
      final dueCards = await cards.fetchCardsWithStatementDueToday(
        onDate: targetDate,
      );
      if (dueCards.isEmpty) {
        return const _AttemptOutcome(success: true, message: '本次沒有到結帳日的信用卡。');
      }

      final closeCurrentStatement = _closeCurrentStatement;
      final userId = _currentUserIdProvider?.call();
      if (closeCurrentStatement == null || userId == null || userId.isEmpty) {
        return _AttemptOutcome(
          success: false,
          message: _composeSummary(
            headline: '帳單結算失敗：缺少可用的 Supabase 使用者或服務。',
            details: [
              for (final card in dueCards)
                'FAIL ${card.displayName}（無法寫入 card_statements）',
            ],
          ),
        );
      }

      var successCount = 0;
      var failedCount = 0;
      final details = <String>[];
      for (final card in dueCards) {
        try {
          await closeCurrentStatement(
            cardId: card.id,
            userId: userId,
            onDate: targetDate,
          );
          successCount += 1;
          details.add('OK ${card.displayName}（status: pending）');
        } catch (error) {
          failedCount += 1;
          details.add('FAIL ${card.displayName}（$error）');
        }
      }

      return _AttemptOutcome(
        success: failedCount == 0,
        message: _composeSummary(
          headline:
              '帳單結算完成：成功 $successCount / ${dueCards.length}${failedCount > 0 ? '，失敗 $failedCount' : ''}',
          details: details,
        ),
      );
    } catch (error) {
      return _AttemptOutcome(success: false, message: '帳單結算執行失敗（$error）');
    }
  }

  DateTime _dayOnlyUtc(DateTime value) {
    return DateTime.utc(value.year, value.month, value.day);
  }

  String _formatDate(DateTime value) {
    final utc = _dayOnlyUtc(value);
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _composeSummary({
    required String headline,
    required List<String> details,
  }) {
    if (details.isEmpty) {
      return headline;
    }
    return '$headline｜${details.join('；')}';
  }
}

class _AttemptOutcome {
  const _AttemptOutcome({required this.success, required this.message});

  final bool success;
  final String message;
}
