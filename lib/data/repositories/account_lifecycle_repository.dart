import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountLifecycleRepositoryProvider = Provider<AccountLifecycleRepository>((
  ref,
) {
  return AccountLifecycleRepositoryImpl();
});

abstract interface class AccountLifecycleRepository {
  AccountDeletionLifecycle getStatus();

  AccountDeletionLifecycle requestDeletion();

  AccountDeletionLifecycle cancelDeletion();
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

class AccountLifecycleRepositoryImpl implements AccountLifecycleRepository {
  AccountLifecycleRepositoryImpl({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _state = AccountDeletionLifecycle.initial((now ?? DateTime.now)());

  final DateTime Function() _now;
  AccountDeletionLifecycle _state;

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
}
