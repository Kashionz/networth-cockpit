import 'package:supabase/supabase.dart';

class SupabaseBudgetService {
  SupabaseBudgetService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<Map<String, dynamic>>> fetchMonthlyBudgetsByUserId(
    String userId, {
    required DateTime monthStart,
  }) async {
    final List<dynamic> rows = await _client
        .from('monthly_budgets')
        .select()
        .eq('user_id', userId)
        .eq('budget_month', _toIsoDate(monthStart))
        .order('category');

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchTransactionsByUserIdWithinRange(
    String userId, {
    required DateTime startInclusive,
    required DateTime endExclusive,
    int limit = 200,
  }) async {
    final List<dynamic> rows = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('occurred_at', startInclusive.toUtc().toIso8601String())
        .lt('occurred_at', endExclusive.toUtc().toIso8601String())
        .order('amount', ascending: false)
        .limit(limit);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  String _toIsoDate(DateTime value) {
    final utc = DateTime.utc(value.year, value.month, value.day);
    return utc.toIso8601String().substring(0, 10);
  }
}
