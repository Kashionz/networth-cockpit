import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/models/money.dart';
import '../models/transaction_record.dart';

final transactionsControllerProvider =
    NotifierProvider<TransactionsController, TransactionsState>(
      TransactionsController.new,
    );

class TransactionsController extends Notifier<TransactionsState> {
  late final TransactionRepository _repository;

  @override
  TransactionsState build() {
    _repository = ref.read(transactionRepositoryProvider);
    Future<void>.microtask(reload);
    return TransactionsState.initial(records: _repository.fallbackRecords);
  }

  Future<void> reload() async {
    final loaded = await _repository.fetchManualRecords();
    if (!ref.mounted) {
      return;
    }
    final sourceAccounts = _deriveSourceAccounts(loaded);
    state = state.copyWith(
      records: loaded,
      sourceAccounts: sourceAccounts,
      lastUsedSourceAccount: sourceAccounts.first,
    );
  }

  Future<void> addManualRecord({
    required num amount,
    required DateTime date,
    required String category,
    required String sourceAccount,
    String? note,
  }) {
    final nextRecord = TransactionRecord(
      id: _generatePseudoUuid(),
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

    return _repository.addManualRecord(nextRecord).then((records) {
      if (!ref.mounted) {
        return;
      }
      final sourceAccounts = _deriveSourceAccounts(records);
      state = state.copyWith(
        records: records,
        sourceAccounts: sourceAccounts,
        lastUsedSourceAccount: sourceAccount,
      );
    });
  }

  Future<void> deleteRecord(String recordId) async {
    state = state.copyWith(
      records: state.records.where((record) => record.id != recordId).toList(),
    );
    final records = await _repository.deleteRecord(recordId);
    if (!ref.mounted) {
      return;
    }
    final sourceAccounts = _deriveSourceAccounts(records);
    state = state.copyWith(
      records: records,
      sourceAccounts: sourceAccounts,
      lastUsedSourceAccount: sourceAccounts.first,
    );
  }

  List<String> _deriveSourceAccounts(List<TransactionRecord> records) {
    final dedup = <String>{
      ..._seedSourceAccounts,
      ...records.map((record) => record.sourceAccount),
    };
    final sorted = dedup.toList(growable: false)..sort();
    return sorted.isEmpty ? _seedSourceAccounts : sorted;
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

  factory TransactionsState.initial({List<TransactionRecord>? records}) {
    final initialRecords = records ?? _seedRecords;
    final sourceAccounts = <String>{..._seedSourceAccounts};
    for (final record in initialRecords) {
      sourceAccounts.add(record.sourceAccount);
    }
    final orderedSources = sourceAccounts.toList(growable: false)..sort();
    return TransactionsState(
      records: initialRecords,
      sourceAccounts: orderedSources,
      lastUsedSourceAccount: orderedSources.first,
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
