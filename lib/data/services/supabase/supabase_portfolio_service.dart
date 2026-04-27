import 'package:supabase/supabase.dart';

class SupabasePortfolioService {
  SupabasePortfolioService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

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

  Future<List<Map<String, dynamic>>> fetchHoldingsByUserId(String userId) async {
    final List<dynamic> rows = await _client
        .from('holdings')
        .select(
          'id,user_id,asset_id,quantity,market_value,metadata,updated_at,assets(id,name,symbol,asset_type,market,currency_code,metadata)',
        )
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
        .select(
          'id,user_id,asset_id,target_percentage,effective_from,effective_to,metadata,updated_at,assets(id,asset_type,metadata)',
        )
        .eq('user_id', userId)
        .order('effective_from', ascending: false)
        .order('updated_at', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>?> fetchLatestPortfolioSnapshotByUserId(
    String userId,
  ) async {
    final List<dynamic> rows = await _client
        .from('portfolio_snapshots')
        .select()
        .eq('user_id', userId)
        .order('snapshot_date', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(rows.first as Map);
  }
}
