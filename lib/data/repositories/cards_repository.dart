import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../features/cards/models/credit_card_account.dart';
import '../../features/cards/models/statement_cycle.dart';
import '../../shared/models/money.dart';
import '../services/supabase/supabase_cards_service.dart';
import '../services/supabase/supabase_client_factory.dart';

final cardsRepositoryProvider = Provider<CardsRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final remoteService = client == null ? null : SupabaseCardsService(client: client);
  return CardsRepositoryImpl(remoteService: remoteService);
});

abstract interface class CardsRepository {
  List<CreditCardAccount> get fallbackCards;

  Future<List<CreditCardAccount>> fetchCards();

  Future<List<CreditCardAccount>> createCard(CreditCardAccount card);

  Future<List<CreditCardAccount>> updateCard(CreditCardAccount card);

  Future<List<CreditCardAccount>> deleteCard(String cardId);
}

class CardsRepositoryImpl implements CardsRepository {
  CardsRepositoryImpl({SupabaseCardsService? remoteService})
    : _remoteService = remoteService,
      _localCards = List<CreditCardAccount>.from(_seedCards);

  final SupabaseCardsService? _remoteService;
  List<CreditCardAccount> _localCards;

  @override
  List<CreditCardAccount> get fallbackCards =>
      List<CreditCardAccount>.unmodifiable(_localCards);

  @override
  Future<List<CreditCardAccount>> fetchCards() async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote == null || userId == null) {
      return _snapshot();
    }

    try {
      final rows = await remote.fetchCardsByUserId(userId);
      _localCards = _sorted(rows.map(_cardFromRow).toList(growable: false));
      return _snapshot();
    } catch (error, stackTrace) {
      developer.log(
        'fetchCards remote call failed',
        name: 'CardsRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return _snapshot();
    }
  }

  @override
  Future<List<CreditCardAccount>> createCard(CreditCardAccount card) {
    return _saveCard(card);
  }

  @override
  Future<List<CreditCardAccount>> updateCard(CreditCardAccount card) {
    return _saveCard(card);
  }

  @override
  Future<List<CreditCardAccount>> deleteCard(String cardId) async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;
    if (remote != null && userId != null) {
      try {
        await remote.deleteCard(userId: userId, cardId: cardId);
        return fetchCards();
      } catch (error, stackTrace) {
        developer.log(
          'deleteCard remote call failed',
          name: 'CardsRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _localCards = _localCards
        .where((card) => card.id != cardId)
        .toList(growable: false);
    return _snapshot();
  }

  Future<List<CreditCardAccount>> _saveCard(CreditCardAccount card) async {
    final remote = _remoteService;
    final userId = remote?.currentUser?.id;

    if (remote != null && userId != null) {
      try {
        await remote.upsertCard({
          if (_looksLikeUuid(card.id)) 'id': card.id,
          'user_id': userId,
          'card_name': card.displayName,
          'last4': card.lastFourDigits,
          'billing_day': card.statementCycle.statementDate.day,
          'due_day': card.statementCycle.dueDate.day,
          'metadata': {'statement_amount': card.statementAmount.amount},
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
        return fetchCards();
      } catch (error, stackTrace) {
        developer.log(
          'saveCard remote call failed',
          name: 'CardsRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _upsertLocal(card);
    return _snapshot();
  }

  void _upsertLocal(CreditCardAccount card) {
    _localCards = _sorted([
      card,
      for (final current in _localCards)
        if (current.id != card.id) current,
    ]);
  }

  List<CreditCardAccount> _snapshot() =>
      List<CreditCardAccount>.unmodifiable(_localCards);

  List<CreditCardAccount> _sorted(List<CreditCardAccount> cards) {
    final sorted = List<CreditCardAccount>.from(cards)
      ..sort(
        (a, b) =>
            a.statementCycle.dueDate.compareTo(b.statementCycle.dueDate),
      );
    return sorted;
  }

  CreditCardAccount _cardFromRow(Map<String, dynamic> row) {
    final statementDay = _toInt(row['billing_day']) ?? 18;
    final dueDay = _toInt(row['due_day']) ?? 5;
    final statementDate =
        _parseDateTime(row['statement_date']) ??
        StatementCycle.fromDays(
          statementDay: statementDay,
          dueDay: dueDay,
        ).statementDate;
    final dueDate =
        _parseDateTime(row['due_date']) ??
        StatementCycle.fromDays(
          statementDay: statementDay,
          dueDay: dueDay,
        ).dueDate;

    return CreditCardAccount(
      id: row['id']?.toString() ?? 'card-local-${DateTime.now().millisecondsSinceEpoch}',
      displayName: row['card_name']?.toString() ?? '未命名信用卡',
      statementAmount: Money.twd(_resolveStatementAmount(row)),
      statementCycle: StatementCycle(
        statementDate: statementDate,
        dueDate: dueDate,
      ),
      lastFourDigits: row['last4']?.toString(),
    );
  }

  num _resolveStatementAmount(Map<String, dynamic> row) {
    final fromColumn = _toNum(row['statement_amount']);
    if (fromColumn != null) {
      return fromColumn;
    }
    final metadata = row['metadata'];
    if (metadata is Map && metadata['statement_amount'] != null) {
      return _toNum(metadata['statement_amount']) ?? 0;
    }
    return 0;
  }

  int? _toInt(Object? value) {
    final numValue = _toNum(value);
    if (numValue == null) {
      return null;
    }
    return numValue.toInt();
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
    return DateTime.tryParse(value)?.toUtc();
  }

  bool _looksLikeUuid(String value) {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(value);
  }
}

final _seedCards = [
  CreditCardAccount(
    id: '11111111-1111-4111-a111-111111111111',
    displayName: '國泰 CUBE',
    statementAmount: const Money.twd(12860),
    statementCycle: StatementCycle(
      statementDate: DateTime(2026, 4, 18),
      dueDate: DateTime(2026, 5, 5),
    ),
    lastFourDigits: '1024',
  ),
  CreditCardAccount(
    id: '22222222-2222-4222-a222-222222222222',
    displayName: '台新 FlyGo',
    statementAmount: const Money.twd(6420),
    statementCycle: StatementCycle(
      statementDate: DateTime(2026, 4, 22),
      dueDate: DateTime(2026, 5, 10),
    ),
    lastFourDigits: '7788',
  ),
];
