import 'package:supabase/supabase.dart';

class SupabaseDashboardService {
  SupabaseDashboardService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<Map<String, dynamic>>> fetchLatestPortfolioSnapshotsByUserId(
    String userId, {
    int limit = 8,
  }) async {
    final List<dynamic> rows = await _client
        .from('portfolio_snapshots')
        .select()
        .eq('user_id', userId)
        .order('snapshot_date', ascending: false)
        .limit(limit);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchLatestMonthlyBudgetsByUserId(
    String userId, {
    int limit = 48,
  }) async {
    final List<dynamic> rows = await _client
        .from('monthly_budgets')
        .select()
        .eq('user_id', userId)
        .order('budget_month', ascending: false)
        .limit(limit);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchHoldingsByUserId(String userId) async {
    final List<dynamic> rows = await _client
        .from('holdings')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchAssetsByUserId(String userId) async {
    final List<dynamic> rows = await _client
        .from('assets')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchTargetAllocationsByUserId(
    String userId,
  ) async {
    final List<dynamic> rows = await _client
        .from('target_allocations')
        .select()
        .eq('user_id', userId)
        .order('effective_from', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchOpenCardStatementsByUserId(
    String userId,
  ) async {
    final List<dynamic> rows = await _client
        .from('card_statements')
        .select()
        .eq('user_id', userId)
        .eq('status', 'open')
        .order('statement_period_end', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchLatestCardStatementsByUserId(
    String userId, {
    int limit = 1,
  }) async {
    final List<dynamic> rows = await _client
        .from('card_statements')
        .select()
        .eq('user_id', userId)
        .order('statement_period_end', ascending: false)
        .limit(limit);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }
}
