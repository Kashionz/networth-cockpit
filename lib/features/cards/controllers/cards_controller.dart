import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/cards_repository.dart';
import '../../../shared/models/money.dart';
import '../models/credit_card_account.dart';
import '../models/statement_cycle.dart';

final cardsControllerProvider =
    NotifierProvider<CardsController, List<CreditCardAccount>>(
      CardsController.new,
    );

class CardsController extends Notifier<List<CreditCardAccount>> {
  late final CardsRepository _repository;

  @override
  List<CreditCardAccount> build() {
    _repository = ref.read(cardsRepositoryProvider);
    Future<void>.microtask(reload);
    return List<CreditCardAccount>.unmodifiable(_repository.fallbackCards);
  }

  Future<void> reload() async {
    final loaded = await _repository.fetchCards();
    if (!ref.mounted) {
      return;
    }
    state = List<CreditCardAccount>.unmodifiable(loaded);
  }

  Future<void> addCard({
    required String displayName,
    required num statementAmount,
    required int statementDay,
    required int dueDay,
    String? lastFourDigits,
  }) async {
    final created = CreditCardAccount(
      id: _generatePseudoUuid(),
      displayName: displayName,
      statementAmount: Money.twd(statementAmount),
      statementCycle: StatementCycle.fromDays(
        statementDay: statementDay,
        dueDay: dueDay,
      ),
      lastFourDigits: lastFourDigits,
    );
    state = List<CreditCardAccount>.unmodifiable([created, ...state]);

    final next = await _repository.createCard(created);
    if (!ref.mounted) {
      return;
    }
    state = List<CreditCardAccount>.unmodifiable(next);
  }

  Future<void> updateCard(CreditCardAccount updated) async {
    state = List<CreditCardAccount>.unmodifiable([
      for (final card in state)
        if (card.id == updated.id) updated else card,
    ]);

    final next = await _repository.updateCard(updated);
    if (!ref.mounted) {
      return;
    }
    state = List<CreditCardAccount>.unmodifiable(next);
  }

  Future<void> deleteCard(String cardId) async {
    state = List<CreditCardAccount>.unmodifiable(
      state.where((card) => card.id != cardId),
    );

    final next = await _repository.deleteCard(cardId);
    if (!ref.mounted) {
      return;
    }
    state = List<CreditCardAccount>.unmodifiable(next);
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
