import 'package:flutter_riverpod/flutter_riverpod.dart';

final jobRunnerRepositoryProvider = Provider<JobRunnerRepository>((ref) {
  return JobRunnerRepositoryImpl();
});

abstract interface class JobRunnerRepository {
  List<JobRun> getRuns();

  Future<JobRun> trigger(JobKind kind);

  Future<JobRun?> retry(String runId);
}

enum JobKind { updatePrices, dailySnapshot, monthlyReport, healthCheck }

extension JobKindX on JobKind {
  String get code => switch (this) {
    JobKind.updatePrices => 'update_prices',
    JobKind.dailySnapshot => 'daily_snapshot',
    JobKind.monthlyReport => 'monthly_report',
    JobKind.healthCheck => 'health_check',
  };

  String get label => switch (this) {
    JobKind.updatePrices => '更新行情',
    JobKind.dailySnapshot => '每日快照',
    JobKind.monthlyReport => '月報彙整',
    JobKind.healthCheck => '健康檢查',
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

class JobRunnerRepositoryImpl implements JobRunnerRepository {
  JobRunnerRepositoryImpl({
    DateTime Function()? now,
    Duration attemptDelay = const Duration(milliseconds: 100),
  }) : _now = now ?? DateTime.now,
       _attemptDelay = attemptDelay;

  final DateTime Function() _now;
  final Duration _attemptDelay;
  final List<JobRun> _runs = <JobRun>[];
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

    return _runInternal(kind: target.kind, retryOfRunId: target.id);
  }

  Future<JobRun> _runInternal({
    required JobKind kind,
    String? retryOfRunId,
  }) async {
    final runId = 'run-${++_runCounter}';
    final requestedAt = _now().toUtc();
    final attempts = <JobAttempt>[];

    final outcomes = _resolveOutcomes(kind: kind, retryOfRunId: retryOfRunId);
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
      status: latestAttempt.success ? JobRunStatus.succeeded : JobRunStatus.failed,
      requestedAt: requestedAt,
      finishedAt: latestAttempt.finishedAt,
      attempts: List<JobAttempt>.unmodifiable(attempts),
      retryOfRunId: retryOfRunId,
    );
    _runs.insert(0, run);
    return run;
  }

  List<_AttemptOutcome> _resolveOutcomes({
    required JobKind kind,
    required String? retryOfRunId,
  }) {
    if (retryOfRunId != null) {
      return const [
        _AttemptOutcome(success: true, message: '手動重試完成'),
      ];
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
    };
  }
}

class _AttemptOutcome {
  const _AttemptOutcome({required this.success, required this.message});

  final bool success;
  final String message;
}
