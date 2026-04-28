import 'package:supabase/supabase.dart';

class SupabaseCardsService {
  SupabaseCardsService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<Map<String, dynamic>>> fetchCardsByUserId(String userId) async {
    final List<dynamic> rows = await _client
        .from('credit_cards')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchCardsWithStatementDueToday({
    required String userId,
    DateTime? onDate,
  }) async {
    final targetDate = _dayOnlyUtc(onDate ?? DateTime.now());
    final List<dynamic> rows = await _client
        .from('credit_cards')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .eq('billing_day', targetDate.day)
        .order('updated_at', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<void> closeCurrentStatement({
    required String cardId,
    required String userId,
    DateTime? onDate,
  }) async {
    final targetDate = _dayOnlyUtc(onDate ?? DateTime.now());
    final card = await _client
        .from('credit_cards')
        .select('id, due_day, metadata')
        .eq('id', cardId)
        .eq('user_id', userId)
        .maybeSingle();
    if (card == null) {
      throw StateError('Card not found for statement close: $cardId');
    }

    final dueDay = _toInt(card['due_day']) ?? 5;
    final statementBalance = _resolveStatementAmount(card);
    final periodEnd = targetDate;
    final previousStatementDate = _addMonthsClamped(targetDate, -1);
    final periodStart = previousStatementDate.add(const Duration(days: 1));
    final dueDate = _resolveDueDate(statementDate: targetDate, dueDay: dueDay);

    await _client.from('card_statements').upsert(
      {
        'user_id': userId,
        'credit_card_id': cardId,
        'statement_period_start': _toDate(periodStart),
        'statement_period_end': _toDate(periodEnd),
        'due_date': _toDate(dueDate),
        'statement_balance': statementBalance,
        'minimum_due': statementBalance,
        'status': 'pending',
        'metadata': {
          'source': 'statement_close_job',
          'closed_on': _toDate(targetDate),
        },
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'credit_card_id,statement_period_start,statement_period_end',
    );
  }

  Future<void> upsertCard(Map<String, dynamic> payload) async {
    await _client.from('credit_cards').upsert(payload, onConflict: 'id');
  }

  Future<void> deleteCard({
    required String userId,
    required String cardId,
  }) async {
    await _client
        .from('credit_cards')
        .delete()
        .eq('id', cardId)
        .eq('user_id', userId);
  }

  DateTime _dayOnlyUtc(DateTime value) {
    return DateTime.utc(value.year, value.month, value.day);
  }

  String _toDate(DateTime value) {
    final dayOnly = _dayOnlyUtc(value);
    final year = dayOnly.year.toString().padLeft(4, '0');
    final month = dayOnly.month.toString().padLeft(2, '0');
    final day = dayOnly.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  int? _toInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  num _resolveStatementAmount(Map<String, dynamic> cardRow) {
    final metadata = cardRow['metadata'];
    if (metadata is Map && metadata['statement_amount'] != null) {
      final amount = num.tryParse(metadata['statement_amount'].toString());
      if (amount != null) {
        return amount;
      }
    }
    return 0;
  }

  DateTime _resolveDueDate({
    required DateTime statementDate,
    required int dueDay,
  }) {
    final dueBase = dueDay >= statementDate.day
        ? DateTime.utc(statementDate.year, statementDate.month)
        : DateTime.utc(statementDate.year, statementDate.month + 1);
    final maxDay = DateTime.utc(dueBase.year, dueBase.month + 1, 0).day;
    final clampedDay = dueDay.clamp(1, maxDay);
    return DateTime.utc(dueBase.year, dueBase.month, clampedDay);
  }

  DateTime _addMonthsClamped(DateTime base, int months) {
    final monthIndex = base.month - 1 + months;
    var targetYear = base.year + monthIndex ~/ 12;
    var targetMonthIndex = monthIndex % 12;
    if (targetMonthIndex < 0) {
      targetMonthIndex += 12;
      targetYear -= 1;
    }
    final targetMonth = targetMonthIndex + 1;
    final maxDay = DateTime.utc(targetYear, targetMonth + 1, 0).day;
    final targetDay = base.day > maxDay ? maxDay : base.day;
    return DateTime.utc(targetYear, targetMonth, targetDay);
  }
}
