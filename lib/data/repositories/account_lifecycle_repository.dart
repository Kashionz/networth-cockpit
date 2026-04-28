import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountLifecycleRepositoryProvider = Provider<AccountLifecycleRepository>(
  (ref) {
    return AccountLifecycleRepositoryImpl();
  },
);

abstract interface class AccountLifecycleRepository {
  AccountDeletionLifecycle getStatus();

  AccountDeletionLifecycle requestDeletion();

  AccountDeletionLifecycle cancelDeletion();

  RiskReassessmentLifecycle getRiskReassessmentStatus();

  RiskReassessmentLifecycle updateRiskPreferenceLevel(double level);

  RiskReassessmentLifecycle triggerMajorEventReassessment({
    required String note,
  });

  RiskReassessmentLifecycle completeRiskReassessmentTask({
    required String taskId,
    String? note,
  });
}

enum AccountDeletionStatus { none, pending, cancelled, expired }

extension AccountDeletionStatusX on AccountDeletionStatus {
  String get label => switch (this) {
    AccountDeletionStatus.none => '未申請',
    AccountDeletionStatus.pending => '等待刪除',
    AccountDeletionStatus.cancelled => '已取消',
    AccountDeletionStatus.expired => '已過期',
  };
}

enum AccountLifecycleEventType { requested, cancelled, expired }

extension AccountLifecycleEventTypeX on AccountLifecycleEventType {
  String get label => switch (this) {
    AccountLifecycleEventType.requested => '已送出刪帳申請',
    AccountLifecycleEventType.cancelled => '已取消刪帳申請',
    AccountLifecycleEventType.expired => '刪帳申請已到期',
  };
}

class AccountLifecycleEvent {
  const AccountLifecycleEvent({
    required this.type,
    required this.createdAt,
    required this.note,
  });

  final AccountLifecycleEventType type;
  final DateTime createdAt;
  final String note;
}

class AccountDeletionLifecycle {
  const AccountDeletionLifecycle({
    required this.status,
    required this.updatedAt,
    required this.events,
    this.requestedAt,
    this.expiresAt,
    this.cancelledAt,
  });

  factory AccountDeletionLifecycle.initial(DateTime now) {
    return AccountDeletionLifecycle(
      status: AccountDeletionStatus.none,
      updatedAt: now.toUtc(),
      events: const <AccountLifecycleEvent>[],
    );
  }

  final AccountDeletionStatus status;
  final DateTime updatedAt;
  final DateTime? requestedAt;
  final DateTime? expiresAt;
  final DateTime? cancelledAt;
  final List<AccountLifecycleEvent> events;

  bool get isPending => status == AccountDeletionStatus.pending;

  AccountDeletionLifecycle copyWith({
    AccountDeletionStatus? status,
    DateTime? updatedAt,
    DateTime? requestedAt,
    DateTime? expiresAt,
    DateTime? cancelledAt,
    List<AccountLifecycleEvent>? events,
  }) {
    return AccountDeletionLifecycle(
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      requestedAt: requestedAt ?? this.requestedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      events: events ?? this.events,
    );
  }
}

enum RiskReassessmentTaskType { annual, majorEvent }

extension RiskReassessmentTaskTypeX on RiskReassessmentTaskType {
  String get label => switch (this) {
    RiskReassessmentTaskType.annual => '12 個月定期再評估',
    RiskReassessmentTaskType.majorEvent => '重大事件觸發',
  };
}

enum RiskReassessmentTaskStatus { pending, overdue, completed }

extension RiskReassessmentTaskStatusX on RiskReassessmentTaskStatus {
  String get label => switch (this) {
    RiskReassessmentTaskStatus.pending => '待完成',
    RiskReassessmentTaskStatus.overdue => '逾期待完成',
    RiskReassessmentTaskStatus.completed => '已完成',
  };
}

class RiskReassessmentTask {
  const RiskReassessmentTask({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.dueAt,
    this.completedAt,
    this.note,
  });

  final String id;
  final RiskReassessmentTaskType type;
  final RiskReassessmentTaskStatus status;
  final DateTime createdAt;
  final DateTime dueAt;
  final DateTime? completedAt;
  final String? note;

  bool get isActionable =>
      status == RiskReassessmentTaskStatus.pending ||
      status == RiskReassessmentTaskStatus.overdue;

  RiskReassessmentTask copyWith({
    RiskReassessmentTaskType? type,
    RiskReassessmentTaskStatus? status,
    DateTime? createdAt,
    DateTime? dueAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? note,
  }) {
    return RiskReassessmentTask(
      id: id,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      note: note ?? this.note,
    );
  }
}

class RiskReassessmentLifecycle {
  const RiskReassessmentLifecycle({
    required this.riskPreferenceLevel,
    required this.lastUpdatedAt,
    required this.tasks,
    this.lastCompletedAt,
    this.lastCompletionNote,
  });

  factory RiskReassessmentLifecycle.initial(DateTime now) {
    final utcNow = now.toUtc();
    return RiskReassessmentLifecycle(
      riskPreferenceLevel: 3,
      lastUpdatedAt: utcNow,
      lastCompletedAt: utcNow,
      tasks: const <RiskReassessmentTask>[],
    );
  }

  final double riskPreferenceLevel;
  final DateTime lastUpdatedAt;
  final DateTime? lastCompletedAt;
  final String? lastCompletionNote;
  final List<RiskReassessmentTask> tasks;

  int get pendingTaskCount => tasks
      .where((task) => task.status != RiskReassessmentTaskStatus.completed)
      .length;

  int get completedTaskCount => tasks
      .where((task) => task.status == RiskReassessmentTaskStatus.completed)
      .length;

  DateTime? get nextAnnualDueAt {
    DateTime? earliest;
    for (final task in tasks) {
      if (task.type != RiskReassessmentTaskType.annual ||
          task.status == RiskReassessmentTaskStatus.completed) {
        continue;
      }
      if (earliest == null || task.dueAt.isBefore(earliest)) {
        earliest = task.dueAt;
      }
    }
    return earliest;
  }

  RiskReassessmentLifecycle copyWith({
    double? riskPreferenceLevel,
    DateTime? lastUpdatedAt,
    DateTime? lastCompletedAt,
    bool clearLastCompletedAt = false,
    String? lastCompletionNote,
    bool clearLastCompletionNote = false,
    List<RiskReassessmentTask>? tasks,
  }) {
    return RiskReassessmentLifecycle(
      riskPreferenceLevel: riskPreferenceLevel ?? this.riskPreferenceLevel,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastCompletedAt: clearLastCompletedAt
          ? null
          : (lastCompletedAt ?? this.lastCompletedAt),
      lastCompletionNote: clearLastCompletionNote
          ? null
          : (lastCompletionNote ?? this.lastCompletionNote),
      tasks: tasks ?? this.tasks,
    );
  }
}

class AccountLifecycleRepositoryImpl implements AccountLifecycleRepository {
  AccountLifecycleRepositoryImpl({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _state = AccountDeletionLifecycle.initial((now ?? DateTime.now)()),
      _riskLifecycle = RiskReassessmentLifecycle.initial(
        (now ?? DateTime.now)(),
      );

  final DateTime Function() _now;
  AccountDeletionLifecycle _state;
  RiskReassessmentLifecycle _riskLifecycle;
  int _riskTaskCounter = 0;

  @override
  AccountDeletionLifecycle getStatus() {
    _syncExpiry();
    return _state;
  }

  @override
  AccountDeletionLifecycle requestDeletion() {
    _syncExpiry();
    final now = _now().toUtc();
    final expiresAt = now.add(const Duration(days: 30));

    _state = _state.copyWith(
      status: AccountDeletionStatus.pending,
      updatedAt: now,
      requestedAt: now,
      expiresAt: expiresAt,
      cancelledAt: null,
      events: [
        AccountLifecycleEvent(
          type: AccountLifecycleEventType.requested,
          createdAt: now,
          note: '刪除申請已排程，將於 30 天後生效。',
        ),
        ..._state.events,
      ],
    );
    return _state;
  }

  @override
  AccountDeletionLifecycle cancelDeletion() {
    _syncExpiry();
    if (_state.status != AccountDeletionStatus.pending) {
      return _state;
    }

    final now = _now().toUtc();
    _state = _state.copyWith(
      status: AccountDeletionStatus.cancelled,
      updatedAt: now,
      cancelledAt: now,
      events: [
        AccountLifecycleEvent(
          type: AccountLifecycleEventType.cancelled,
          createdAt: now,
          note: '刪除申請已取消，帳號維持啟用。',
        ),
        ..._state.events,
      ],
    );
    return _state;
  }

  @override
  RiskReassessmentLifecycle getRiskReassessmentStatus() {
    _syncRiskReassessment();
    return _riskLifecycle;
  }

  @override
  RiskReassessmentLifecycle updateRiskPreferenceLevel(double level) {
    _syncRiskReassessment();
    final now = _now().toUtc();
    _riskLifecycle = _riskLifecycle.copyWith(
      riskPreferenceLevel: level.clamp(1, 5).toDouble(),
      lastUpdatedAt: now,
    );
    return _riskLifecycle;
  }

  @override
  RiskReassessmentLifecycle triggerMajorEventReassessment({
    required String note,
  }) {
    _syncRiskReassessment();
    final now = _now().toUtc();
    final trimmed = note.trim();
    final task = RiskReassessmentTask(
      id: _nextRiskTaskId(),
      type: RiskReassessmentTaskType.majorEvent,
      status: RiskReassessmentTaskStatus.pending,
      createdAt: now,
      dueAt: now,
      note: trimmed.isEmpty ? '重大事件變動' : trimmed,
    );
    _riskLifecycle = _riskLifecycle.copyWith(
      lastUpdatedAt: now,
      tasks: [task, ..._riskLifecycle.tasks],
    );
    return _riskLifecycle;
  }

  @override
  RiskReassessmentLifecycle completeRiskReassessmentTask({
    required String taskId,
    String? note,
  }) {
    _syncRiskReassessment();
    final now = _now().toUtc();
    var completedTaskType = RiskReassessmentTaskType.majorEvent;
    var changed = false;
    final nextTasks = <RiskReassessmentTask>[];
    for (final task in _riskLifecycle.tasks) {
      if (task.id != taskId || !task.isActionable) {
        nextTasks.add(task);
        continue;
      }
      changed = true;
      completedTaskType = task.type;
      nextTasks.add(
        task.copyWith(
          status: RiskReassessmentTaskStatus.completed,
          completedAt: now,
          note: note ?? task.note,
        ),
      );
    }
    if (!changed) {
      return _riskLifecycle;
    }

    _riskLifecycle = _riskLifecycle.copyWith(
      lastUpdatedAt: now,
      lastCompletedAt: now,
      lastCompletionNote: note?.trim().isNotEmpty == true
          ? note!.trim()
          : _riskLifecycle.lastCompletionNote,
      tasks: nextTasks,
    );

    if (completedTaskType == RiskReassessmentTaskType.annual) {
      _appendAnnualTask(dueFrom: now);
    } else {
      _ensureAnnualTask();
    }

    return _riskLifecycle;
  }

  void _syncExpiry() {
    if (_state.status != AccountDeletionStatus.pending) {
      return;
    }
    final expiresAt = _state.expiresAt;
    if (expiresAt == null) {
      return;
    }
    final now = _now().toUtc();
    if (now.isBefore(expiresAt)) {
      return;
    }

    _state = _state.copyWith(
      status: AccountDeletionStatus.expired,
      updatedAt: now,
      events: [
        AccountLifecycleEvent(
          type: AccountLifecycleEventType.expired,
          createdAt: now,
          note: '申請已超過 30 天保留期，請重新送出。',
        ),
        ..._state.events,
      ],
    );
  }

  void _syncRiskReassessment() {
    _ensureAnnualTask();
    final now = _now().toUtc();
    _riskLifecycle = _riskLifecycle.copyWith(
      tasks: [
        for (final task in _riskLifecycle.tasks)
          if (task.status == RiskReassessmentTaskStatus.completed)
            task
          else if (now.isAfter(task.dueAt))
            task.copyWith(status: RiskReassessmentTaskStatus.overdue)
          else
            task.copyWith(status: RiskReassessmentTaskStatus.pending),
      ],
      lastUpdatedAt: now,
    );
  }

  void _ensureAnnualTask() {
    final hasPendingAnnual = _riskLifecycle.tasks.any(
      (task) =>
          task.type == RiskReassessmentTaskType.annual &&
          task.status != RiskReassessmentTaskStatus.completed,
    );
    if (hasPendingAnnual) {
      return;
    }
    final dueFrom = _riskLifecycle.lastCompletedAt ?? _now().toUtc();
    _appendAnnualTask(dueFrom: dueFrom);
  }

  void _appendAnnualTask({required DateTime dueFrom}) {
    final now = _now().toUtc();
    final dueAt = DateTime.utc(
      dueFrom.year,
      dueFrom.month + 12,
      dueFrom.day,
      dueFrom.hour,
      dueFrom.minute,
      dueFrom.second,
      dueFrom.millisecond,
      dueFrom.microsecond,
    );
    final task = RiskReassessmentTask(
      id: _nextRiskTaskId(),
      type: RiskReassessmentTaskType.annual,
      status: now.isAfter(dueAt)
          ? RiskReassessmentTaskStatus.overdue
          : RiskReassessmentTaskStatus.pending,
      createdAt: now,
      dueAt: dueAt,
      note: '定期風險問卷再評估',
    );
    _riskLifecycle = _riskLifecycle.copyWith(
      tasks: [task, ..._riskLifecycle.tasks],
    );
  }

  String _nextRiskTaskId() => 'risk-task-${++_riskTaskCounter}';
}
