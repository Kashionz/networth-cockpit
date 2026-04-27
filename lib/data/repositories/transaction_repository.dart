import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../features/transactions/models/transaction_record.dart';
import '../../shared/models/money.dart';
import '../mock/mock_transactions.dart';
import '../services/supabase/supabase_client_factory.dart';
import '../services/supabase/supabase_transactions_service.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final remoteService = client == null
      ? null
      : SupabaseTransactionsService(client: client);
  return TransactionRepository(remoteService: remoteService);
});

class TransactionRepository {
  TransactionRepository({SupabaseTransactionsService? remoteService})
    : _remoteService = remoteService,
      _localRecords = List<TransactionRecord>.from(_seedRecords);

  final SupabaseTransactionsService? _remoteService;
  List<TransactionRecord> _localRecords;

  List<String> getReviewMerchantNames() => MockTransactions.reviewMerchantNames;

  List<TransactionRecord> get fallbackRecords =>
      List<TransactionRecord>.unmodifiable(_localRecords);

  Future<List<TransactionRecord>> fetchManualRecords() async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote == null || userId == null) {
      return _snapshot();
    }

    try {
      final rows = await remote.fetchManualTransactionsByUserId(userId);
      final filtered = rows.where(_isManualRow).map(_recordFromRow).toList(
        growable: false,
      );
      _localRecords = _sorted(filtered);
      return _snapshot();
    } catch (error, stackTrace) {
      developer.log(
        'fetchManualRecords remote call failed',
        name: 'TransactionRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return _snapshot();
    }
  }

  Future<List<TransactionRecord>> addManualRecord(TransactionRecord record) {
    return _upsertManualRecord(record);
  }

  Future<List<TransactionRecord>> updateManualRecord(TransactionRecord record) {
    return _upsertManualRecord(record);
  }

  Future<List<TransactionRecord>> deleteRecord(String recordId) async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote != null && userId != null) {
      try {
        await remote.deleteTransaction(userId: userId, transactionId: recordId);
        return fetchManualRecords();
      } catch (error, stackTrace) {
        developer.log(
          'deleteRecord remote call failed',
          name: 'TransactionRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _localRecords = _localRecords
        .where((record) => record.id != recordId)
        .toList(growable: false);
    return _snapshot();
  }

  Future<List<TransactionRecord>> _upsertManualRecord(
    TransactionRecord record,
  ) async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote != null && userId != null) {
      try {
        await remote.upsertTransaction({
          if (_looksLikeUuid(record.id)) 'id': record.id,
          'user_id': userId,
          'transaction_type': 'expense',
          'direction': 'outflow',
          'occurred_at': record.date.toUtc().toIso8601String(),
          'amount': record.amount.amount,
          'currency_code': record.amount.currencyCode,
          'merchant': record.note ?? '手動記錄',
          'category': record.category,
          'note': record.note,
          'metadata': {'source': 'manual', 'source_account': record.sourceAccount},
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        return fetchManualRecords();
      } catch (error, stackTrace) {
        developer.log(
          'upsertManualRecord remote call failed',
          name: 'TransactionRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _localRecords = _sorted([
      record,
      for (final current in _localRecords)
        if (current.id != record.id) current,
    ]);
    return _snapshot();
  }

  List<TransactionRecord> _snapshot() =>
      List<TransactionRecord>.unmodifiable(_localRecords);

  List<TransactionRecord> _sorted(List<TransactionRecord> records) {
    final sorted = List<TransactionRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  TransactionRecord _recordFromRow(Map<String, dynamic> row) {
    return TransactionRecord(
      id: row['id']?.toString() ?? 'txn-local-${DateTime.now().millisecondsSinceEpoch}',
      amount: Money.twd(_toNum(row['amount']) ?? 0),
      date: _parseDateTime(row['occurred_at']) ?? DateTime.now(),
      category: row['category']?.toString() ?? '其他',
      sourceAccount: _resolveSourceAccount(row),
      note: row['note']?.toString(),
    );
  }

  bool _isManualRow(Map<String, dynamic> row) {
    final metadata = row['metadata'];
    if (metadata is Map && metadata['source'] != null) {
      return metadata['source'].toString() == 'manual';
    }
    return true;
  }

  String _resolveSourceAccount(Map<String, dynamic> row) {
    final metadata = row['metadata'];
    if (metadata is Map && metadata['source_account'] != null) {
      return metadata['source_account'].toString();
    }
    return row['source_account']?.toString() ?? '未分類帳戶';
  }

  num? _toNum(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString());
  }

  DateTime? _parseDateTime(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  bool _looksLikeUuid(String value) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(value);
  }
}

final _seedRecords = [
  TransactionRecord(
    id: 'txn-1',
    amount: const Money.twd(9800),
    date: DateTime(2026, 4, 24),
    category: '生活',
    sourceAccount: '王道銀行帳戶',
    note: '電腦維修',
  ),
  TransactionRecord(
    id: 'txn-2',
    amount: const Money.twd(6200),
    date: DateTime(2026, 4, 19),
    category: '固定',
    sourceAccount: '永豐大戶帳戶',
    note: '年度保費',
  ),
];
