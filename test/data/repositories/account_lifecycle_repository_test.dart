import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/account_lifecycle_repository.dart';

void main() {
  test('account deletion lifecycle supports request and cancel tracking', () {
    final base = DateTime.utc(2026, 1, 1, 9);
    var now = base;
    final repository = AccountLifecycleRepositoryImpl(now: () => now);

    final initial = repository.getStatus();
    expect(initial.status, AccountDeletionStatus.none);

    final requested = repository.requestDeletion();
    expect(requested.status, AccountDeletionStatus.pending);
    expect(requested.expiresAt, base.add(const Duration(days: 30)));
    expect(requested.events.first.type, AccountLifecycleEventType.requested);

    now = now.add(const Duration(days: 1));
    final cancelled = repository.cancelDeletion();
    expect(cancelled.status, AccountDeletionStatus.cancelled);
    expect(cancelled.cancelledAt, now.toUtc());
    expect(cancelled.events.first.type, AccountLifecycleEventType.cancelled);
  });

  test(
    'risk reassessment creates annual task, supports major event, and completion',
    () {
      var now = DateTime.utc(2026, 2, 10, 8);
      final repository = AccountLifecycleRepositoryImpl(now: () => now);

      final initial = repository.getRiskReassessmentStatus();
      final annualTask = initial.tasks.firstWhere(
        (task) => task.type == RiskReassessmentTaskType.annual,
      );

      expect(annualTask.status, RiskReassessmentTaskStatus.pending);
      expect(annualTask.dueAt, DateTime.utc(2027, 2, 10, 8));
      expect(initial.pendingTaskCount, 1);

      final afterMajorEvent = repository.triggerMajorEventReassessment(
        note: '收入結構調整',
      );
      final majorEventTask = afterMajorEvent.tasks.firstWhere(
        (task) => task.type == RiskReassessmentTaskType.majorEvent,
      );

      expect(majorEventTask.status, RiskReassessmentTaskStatus.pending);
      expect(majorEventTask.note, '收入結構調整');

      now = now.add(const Duration(hours: 2));
      final completedMajor = repository.completeRiskReassessmentTask(
        taskId: majorEventTask.id,
        note: '已完成重大事件再評估',
      );
      final completedTask = completedMajor.tasks.firstWhere(
        (task) => task.id == majorEventTask.id,
      );

      expect(completedTask.status, RiskReassessmentTaskStatus.completed);
      expect(completedTask.completedAt, now.toUtc());
      expect(completedMajor.lastCompletedAt, now.toUtc());

      now = DateTime.utc(2027, 2, 11, 8);
      final overdueLifecycle = repository.getRiskReassessmentStatus();
      final overdueAnnualTask = overdueLifecycle.tasks.firstWhere(
        (task) =>
            task.type == RiskReassessmentTaskType.annual &&
            task.status != RiskReassessmentTaskStatus.completed,
      );

      expect(overdueAnnualTask.status, RiskReassessmentTaskStatus.overdue);

      now = now.add(const Duration(hours: 1));
      final completedAnnual = repository.completeRiskReassessmentTask(
        taskId: overdueAnnualTask.id,
        note: '已完成年度風險問卷',
      );

      final newAnnualPending = completedAnnual.tasks.firstWhere(
        (task) =>
            task.type == RiskReassessmentTaskType.annual &&
            task.status != RiskReassessmentTaskStatus.completed,
      );
      expect(newAnnualPending.dueAt, DateTime.utc(2028, 2, 11, 9));
    },
  );
}
