import '../../../shared/models/money.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    required this.sourceAccount,
    this.note,
  });

  final String id;
  final Money amount;
  final DateTime date;
  final String category;
  final String sourceAccount;
  final String? note;

  TransactionRecord copyWith({
    String? id,
    Money? amount,
    DateTime? date,
    String? category,
    String? sourceAccount,
    String? note,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      sourceAccount: sourceAccount ?? this.sourceAccount,
      note: note ?? this.note,
    );
  }
}
