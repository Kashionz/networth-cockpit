import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../services/supabase/supabase_client_factory.dart';
import '../services/supabase/supabase_transaction_import_service.dart';

final transactionImportRepositoryProvider = Provider<TransactionImportRepository>(
  (ref) {
    final env = ref.watch(appEnvProvider);
    final client = SupabaseClientFactory.create(env);
    final remote = client == null
        ? null
        : SupabaseTransactionImportService(client: client);

    return TransactionImportRepository(
      remoteService: remote,
      allowFallbackWhenRemoteMissing: !env.hasSupabase,
    );
  },
);

class TransactionImportRepository {
  TransactionImportRepository({
    TransactionImportRemoteService? remoteService,
    bool allowFallbackWhenRemoteMissing = true,
  }) : _remoteService = remoteService,
       _allowFallbackWhenRemoteMissing = allowFallbackWhenRemoteMissing;

  final TransactionImportRemoteService? _remoteService;
  final bool _allowFallbackWhenRemoteMissing;

  Future<TransactionImportWriteResult> writeImportedStatement({
    required String cardId,
    required String cardName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<TransactionImportWriteRow> rows,
  }) async {
    if (rows.isEmpty) {
      return const TransactionImportWriteResult.failure(
        message: '沒有可寫入的交易資料。',
      );
    }

    final statementTotal = rows.fold<num>(0, (sum, row) => sum + row.amount);
    final dueDate = periodEnd.add(const Duration(days: 14));
    final remote = _remoteService;
    if (remote == null) {
      if (!_allowFallbackWhenRemoteMissing) {
        return const TransactionImportWriteResult.failure(
          message: 'Supabase 設定異常，請確認連線設定後再試。',
        );
      }
      return TransactionImportWriteResult.successWithFallback(
        transactionCount: rows.length,
        statementTotal: statementTotal,
        message:
            'Supabase 未設定，已完成匯入流程（卡片：$cardName），但尚未寫入雲端資料表。',
      );
    }

    try {
      final user = remote.currentUser;
      if (user == null) {
        return const TransactionImportWriteResult.failure(
          message: '尚未登入，無法寫入匯入資料。',
        );
      }
      if (!_looksLikeUuid(cardId)) {
        return TransactionImportWriteResult.successWithFallback(
          transactionCount: rows.length,
          statementTotal: statementTotal,
          message: '所選卡片尚未同步到雲端（ID 非 UUID），已保留匯入結果但未寫入雲端。',
        );
      }

      final statementPayload = <String, dynamic>{
        'user_id': user.id,
        'credit_card_id': cardId,
        'statement_period_start': _toDate(periodStart),
        'statement_period_end': _toDate(periodEnd),
        'statement_balance': statementTotal,
        'minimum_due': statementTotal,
        'due_date': _toDate(dueDate),
        'status': 'open',
      };
      final statementId = await remote.insertCardStatement(statementPayload);

      final transactionPayloads = rows.map((row) {
        final noteSuffix = row.note?.trim().isNotEmpty == true
            ? '；備註: ${row.note!.trim()}'
            : '';
        return <String, dynamic>{
          'user_id': user.id,
          'credit_card_id': cardId,
          'card_statement_id': statementId,
          'transaction_type': 'expense',
          'direction': 'outflow',
          'amount': row.amount,
          'currency_code': 'TWD',
          'occurred_at': row.transactedAt.toUtc().toIso8601String(),
          'merchant': row.merchant,
          'category': row.category,
          'note': '分類: ${row.category}$noteSuffix',
          'metadata': {'source': 'csv_import'},
        };
      }).toList(growable: false);

      await remote.insertTransactions(transactionPayloads);
      return TransactionImportWriteResult.success(
        transactionCount: rows.length,
        statementTotal: statementTotal,
        message: '已寫入 transactions ${rows.length} 筆，並建立 card_statements 1 筆。',
      );
    } catch (error, stackTrace) {
      developer.log(
        'transaction import remote write failed',
        name: 'TransactionImportRepository',
        error: error,
        stackTrace: stackTrace,
      );

      return TransactionImportWriteResult.successWithFallback(
        transactionCount: rows.length,
        statementTotal: statementTotal,
        message:
            'Supabase 寫入暫時失敗，已完成匯入審核流程但未寫入雲端。可稍後重試同步。',
      );
    }
  }

  String _toDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _looksLikeUuid(String value) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(value);
  }
}

class TransactionImportWriteRow {
  const TransactionImportWriteRow({
    required this.transactedAt,
    required this.amount,
    required this.merchant,
    required this.category,
    this.note,
  });

  final DateTime transactedAt;
  final num amount;
  final String merchant;
  final String category;
  final String? note;
}

class TransactionImportWriteResult {
  const TransactionImportWriteResult._({
    required this.completed,
    required this.usedFallback,
    required this.persistedToSupabase,
    required this.transactionCount,
    required this.statementTotal,
    required this.message,
  });

  const TransactionImportWriteResult.success({
    required int transactionCount,
    required num statementTotal,
    required String message,
  }) : this._(
         completed: true,
         usedFallback: false,
         persistedToSupabase: true,
         transactionCount: transactionCount,
         statementTotal: statementTotal,
         message: message,
       );

  const TransactionImportWriteResult.successWithFallback({
    required int transactionCount,
    required num statementTotal,
    required String message,
  }) : this._(
         completed: true,
         usedFallback: true,
         persistedToSupabase: false,
         transactionCount: transactionCount,
         statementTotal: statementTotal,
         message: message,
       );

  const TransactionImportWriteResult.failure({required String message})
    : this._(
        completed: false,
        usedFallback: false,
        persistedToSupabase: false,
        transactionCount: 0,
        statementTotal: 0,
        message: message,
      );

  final bool completed;
  final bool usedFallback;
  final bool persistedToSupabase;
  final int transactionCount;
  final num statementTotal;
  final String message;
}
