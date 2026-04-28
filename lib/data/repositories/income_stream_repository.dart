import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../features/income/models/income_stream.dart';
import '../services/supabase/supabase_client_factory.dart';
import '../services/supabase/supabase_income_service.dart';

final incomeStreamRepositoryProvider = Provider<IncomeStreamRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final remoteService = client == null
      ? null
      : SupabaseIncomeService(client: client);

  return IncomeStreamRepositoryImpl(remoteService: remoteService);
});

abstract interface class IncomeStreamRepository {
  Future<List<IncomeStream>> fetchIncomeStreams({String? userId});

  Future<IncomeStream> upsertIncomeStream(IncomeStream stream);

  Future<void> deleteIncomeStream(String id);

  num totalMonthlyIncome();
}

class IncomeStreamRepositoryImpl implements IncomeStreamRepository {
  IncomeStreamRepositoryImpl({
    IncomeStreamRemoteService? remoteService,
    List<IncomeStream>? seedStreams,
  }) : _remoteService = remoteService,
       _localStreams = List<IncomeStream>.from(seedStreams ?? const []);

  final IncomeStreamRemoteService? _remoteService;
  List<IncomeStream> _localStreams;

  @override
  Future<List<IncomeStream>> fetchIncomeStreams({String? userId}) async {
    final remote = _remoteService;
    final resolvedUserId = userId ?? remote?.currentUserId;
    if (remote == null || resolvedUserId == null) {
      return _snapshot();
    }

    try {
      final rows = await remote.fetchIncomeStreams(resolvedUserId);
      _localStreams = _sorted([
        for (final row in rows)
          IncomeStream.fromJson({...row, 'user_id': resolvedUserId}),
      ]);
      return _snapshot();
    } catch (error, stackTrace) {
      developer.log(
        'fetchIncomeStreams remote call failed',
        name: 'IncomeStreamRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return _snapshot();
    }
  }

  @override
  Future<IncomeStream> upsertIncomeStream(IncomeStream stream) async {
    final now = DateTime.now().toUtc();
    final normalized = _normalize(stream).copyWith(updatedAt: now);
    final remote = _remoteService;
    final resolvedUserId =
        remote?.currentUserId ??
        (normalized.userId.trim().isEmpty ? null : normalized.userId.trim());

    if (remote != null && resolvedUserId != null) {
      try {
        final payload = normalized.copyWith(userId: resolvedUserId).toJson();
        if (!_looksLikeUuid(normalized.id)) {
          payload.remove('id');
        }
        final row = await remote.upsertIncomeStream(payload);
        final saved = IncomeStream.fromJson({
          ...row,
          'user_id': resolvedUserId,
        });
        _upsertLocal(saved);
        return saved;
      } catch (error, stackTrace) {
        developer.log(
          'upsertIncomeStream remote call failed',
          name: 'IncomeStreamRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final fallback = normalized.copyWith(
      id: normalized.id.trim().isEmpty ? _generatePseudoUuid() : normalized.id,
      userId: resolvedUserId ?? normalized.userId,
      updatedAt: now,
    );
    _upsertLocal(fallback);
    return fallback;
  }

  @override
  Future<void> deleteIncomeStream(String id) async {
    final remote = _remoteService;
    final userId = remote?.currentUserId;
    if (remote != null && userId != null) {
      try {
        await remote.deleteIncomeStream(userId: userId, id: id);
      } catch (error, stackTrace) {
        developer.log(
          'deleteIncomeStream remote call failed',
          name: 'IncomeStreamRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _localStreams = _localStreams
        .where((stream) => stream.id != id)
        .toList(growable: false);
  }

  @override
  num totalMonthlyIncome() {
    final now = DateTime.now().toUtc();
    return _localStreams
        .where((stream) => stream.active)
        .fold<num>(0, (sum, stream) => sum + _monthlyContribution(stream, now));
  }

  IncomeStream _normalize(IncomeStream stream) {
    final normalizedName = stream.name.trim();
    final normalizedUserId = stream.userId.trim();
    final normalizedAmount = stream.amount < 0 ? 0 : stream.amount;
    final normalizedDate = DateTime.utc(
      stream.nextDate.year,
      stream.nextDate.month,
      stream.nextDate.day,
    );
    return stream.copyWith(
      name: normalizedName.isEmpty ? '未命名收入' : normalizedName,
      userId: normalizedUserId,
      amount: normalizedAmount,
      nextDate: normalizedDate,
      createdAt: stream.createdAt.toUtc(),
      updatedAt: stream.updatedAt.toUtc(),
    );
  }

  void _upsertLocal(IncomeStream stream) {
    _localStreams = _sorted([
      stream,
      for (final current in _localStreams)
        if (current.id != stream.id) current,
    ]);
  }

  List<IncomeStream> _snapshot() =>
      List<IncomeStream>.unmodifiable(_localStreams);
}

class MockIncomeStreamRepository implements IncomeStreamRepository {
  MockIncomeStreamRepository({List<IncomeStream>? seedStreams})
    : _streams = List<IncomeStream>.from(seedStreams ?? const []);

  List<IncomeStream> _streams;

  @override
  Future<List<IncomeStream>> fetchIncomeStreams({String? userId}) async {
    if (userId == null || userId.trim().isEmpty) {
      return _snapshot();
    }
    return _sorted(
      _streams
          .where((stream) => stream.userId == userId)
          .toList(growable: false),
    );
  }

  @override
  Future<IncomeStream> upsertIncomeStream(IncomeStream stream) async {
    final now = DateTime.now().toUtc();
    final normalized = _normalizeMock(stream).copyWith(updatedAt: now);
    final saved = normalized.copyWith(
      id: normalized.id.trim().isEmpty ? _generatePseudoUuid() : normalized.id,
    );
    _streams = _sorted([
      saved,
      for (final current in _streams)
        if (current.id != saved.id) current,
    ]);
    return saved;
  }

  @override
  Future<void> deleteIncomeStream(String id) async {
    _streams = _streams
        .where((stream) => stream.id != id)
        .toList(growable: false);
  }

  @override
  num totalMonthlyIncome() {
    final now = DateTime.now().toUtc();
    return _streams
        .where((stream) => stream.active)
        .fold<num>(0, (sum, stream) => sum + _monthlyContribution(stream, now));
  }

  IncomeStream _normalizeMock(IncomeStream stream) {
    final normalizedName = stream.name.trim();
    return stream.copyWith(
      name: normalizedName.isEmpty ? '未命名收入' : normalizedName,
      nextDate: DateTime.utc(
        stream.nextDate.year,
        stream.nextDate.month,
        stream.nextDate.day,
      ),
      createdAt: stream.createdAt.toUtc(),
      updatedAt: stream.updatedAt.toUtc(),
    );
  }

  List<IncomeStream> _snapshot() => List<IncomeStream>.unmodifiable(
    _sorted(List<IncomeStream>.from(_streams)),
  );
}

List<IncomeStream> _sorted(List<IncomeStream> streams) {
  final sorted = List<IncomeStream>.from(streams)
    ..sort((a, b) {
      final activeOrderA = a.active ? 0 : 1;
      final activeOrderB = b.active ? 0 : 1;
      final activeCompare = activeOrderA.compareTo(activeOrderB);
      if (activeCompare != 0) {
        return activeCompare;
      }

      final dateCompare = a.nextDate.compareTo(b.nextDate);
      if (dateCompare != 0) {
        return dateCompare;
      }

      final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
      if (updatedCompare != 0) {
        return updatedCompare;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return sorted;
}

num _monthlyContribution(IncomeStream stream, DateTime nowUtc) {
  return switch (stream.frequency) {
    IncomeFrequency.monthly => stream.amount,
    IncomeFrequency.yearly => stream.amount / 12,
    IncomeFrequency.oneTime =>
      _isSameYearMonth(stream.nextDate, nowUtc) ? stream.amount : 0,
  };
}

bool _isSameYearMonth(DateTime left, DateTime right) {
  return left.year == right.year && left.month == right.month;
}

bool _looksLikeUuid(String value) {
  final uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  return uuidPattern.hasMatch(value);
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
