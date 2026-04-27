import '../../../shared/models/money.dart';
import 'statement_cycle.dart';

class CreditCardAccount {
  const CreditCardAccount({
    required this.id,
    required this.displayName,
    required this.statementAmount,
    required this.statementCycle,
    this.lastFourDigits,
  });

  final String id;
  final String displayName;
  final Money statementAmount;
  final StatementCycle statementCycle;
  final String? lastFourDigits;

  String? get maskedNumber {
    if (lastFourDigits == null || lastFourDigits!.isEmpty) {
      return null;
    }
    return '•••• $lastFourDigits';
  }

  CreditCardAccount copyWith({
    String? id,
    String? displayName,
    Money? statementAmount,
    StatementCycle? statementCycle,
    String? lastFourDigits,
  }) {
    return CreditCardAccount(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      statementAmount: statementAmount ?? this.statementAmount,
      statementCycle: statementCycle ?? this.statementCycle,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
    );
  }
}
