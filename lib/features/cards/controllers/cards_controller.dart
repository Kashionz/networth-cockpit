import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/money.dart';
import '../models/credit_card_account.dart';
import '../models/statement_cycle.dart';

final cardsControllerProvider =
    NotifierProvider<CardsController, List<CreditCardAccount>>(
      CardsController.new,
    );

class CardsController extends Notifier<List<CreditCardAccount>> {
  int _idSeed = _seedCards.length + 1;

  @override
  List<CreditCardAccount> build() =>
      List<CreditCardAccount>.unmodifiable(_seedCards);

  void addCard({
    required String displayName,
    required num statementAmount,
    required int statementDay,
    required int dueDay,
    String? lastFourDigits,
  }) {
    final created = CreditCardAccount(
      id: 'card-${_idSeed++}',
      displayName: displayName,
      statementAmount: Money.twd(statementAmount),
      statementCycle: StatementCycle.fromDays(
        statementDay: statementDay,
        dueDay: dueDay,
      ),
      lastFourDigits: lastFourDigits,
    );
    state = List<CreditCardAccount>.unmodifiable([created, ...state]);
  }

  void updateCard(CreditCardAccount updated) {
    state = List<CreditCardAccount>.unmodifiable([
      for (final card in state)
        if (card.id == updated.id) updated else card,
    ]);
  }

  void deleteCard(String cardId) {
    state = List<CreditCardAccount>.unmodifiable(
      state.where((card) => card.id != cardId),
    );
  }
}

final _seedCards = [
  CreditCardAccount(
    id: 'card-1',
    displayName: '國泰 CUBE',
    statementAmount: const Money.twd(12860),
    statementCycle: StatementCycle(
      statementDate: DateTime(2026, 4, 18),
      dueDate: DateTime(2026, 5, 5),
    ),
    lastFourDigits: '1024',
  ),
  CreditCardAccount(
    id: 'card-2',
    displayName: '台新 FlyGo',
    statementAmount: const Money.twd(6420),
    statementCycle: StatementCycle(
      statementDate: DateTime(2026, 4, 22),
      dueDate: DateTime(2026, 5, 10),
    ),
    lastFourDigits: '7788',
  ),
];
