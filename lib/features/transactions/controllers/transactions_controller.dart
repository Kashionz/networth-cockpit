import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/money.dart';
import '../models/transaction_record.dart';

final transactionsControllerProvider =
    NotifierProvider<TransactionsController, TransactionsState>(
      TransactionsController.new,
    );

class TransactionsController extends Notifier<TransactionsState> {
  int _idSeed = _seedRecords.length;

  @override
  TransactionsState build() => TransactionsState.initial();

  void addManualRecord({
    required num amount,
    required DateTime date,
    required String category,
    required String sourceAccount,
    String? note,
  }) {
    final nextRecord = TransactionRecord(
      id: 'txn-${_idSeed++}',
      amount: Money.twd(amount),
      date: date,
      category: category,
      sourceAccount: sourceAccount,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
    );
    final nextSources = state.sourceAccounts.contains(sourceAccount)
        ? state.sourceAccounts
        : [...state.sourceAccounts, sourceAccount];

    state = state.copyWith(
      records: [nextRecord, ...state.records],
      sourceAccounts: nextSources,
      lastUsedSourceAccount: sourceAccount,
    );
  }

  void deleteRecord(String recordId) {
    state = state.copyWith(
      records: state.records.where((record) => record.id != recordId).toList(),
    );
  }
}

class TransactionsState {
  TransactionsState({
    required List<TransactionRecord> records,
    required List<String> sourceAccounts,
    required this.lastUsedSourceAccount,
    required List<String> categoryOptions,
  }) : records = List<TransactionRecord>.unmodifiable(records),
       sourceAccounts = List<String>.unmodifiable(sourceAccounts),
       categoryOptions = List<String>.unmodifiable(categoryOptions);

  factory TransactionsState.initial() {
    return TransactionsState(
      records: _seedRecords,
      sourceAccounts: _seedSourceAccounts,
      lastUsedSourceAccount: '王道銀行帳戶',
      categoryOptions: _categoryOptions,
    );
  }

  final List<TransactionRecord> records;
  final List<String> sourceAccounts;
  final String lastUsedSourceAccount;
  final List<String> categoryOptions;

  TransactionsState copyWith({
    List<TransactionRecord>? records,
    List<String>? sourceAccounts,
    String? lastUsedSourceAccount,
    List<String>? categoryOptions,
  }) {
    return TransactionsState(
      records: records ?? this.records,
      sourceAccounts: sourceAccounts ?? this.sourceAccounts,
      lastUsedSourceAccount:
          lastUsedSourceAccount ?? this.lastUsedSourceAccount,
      categoryOptions: categoryOptions ?? this.categoryOptions,
    );
  }
}

const _categoryOptions = ['固定', '生活', '彈性', '醫療', '教育', '其他'];

const _seedSourceAccounts = ['王道銀行帳戶', '現金錢包', '永豐大戶帳戶', '國泰 CUBE'];

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
