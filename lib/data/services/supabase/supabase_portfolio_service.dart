import 'package:supabase/supabase.dart';

abstract interface class PortfolioRemoteService {
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> fetchAssetsByUserId(String userId);

  Future<List<Map<String, dynamic>>> fetchHoldingsByUserId(String userId);

  Future<List<Map<String, dynamic>>> fetchTargetAllocationsByUserId(
    String userId,
  );

  Future<Map<String, dynamic>?> fetchLatestPortfolioSnapshotByUserId(
    String userId,
  );

  Future<List<Map<String, dynamic>>> fetchDailyPricesByAssetIds({
    required List<String> assetIds,
    int lookbackDays,
  });
}

class SupabasePortfolioService implements PortfolioRemoteService {
  SupabasePortfolioService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
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

  @override
  Future<List<Map<String, dynamic>>> fetchHoldingsByUserId(
    String userId,
  ) async {
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

  @override
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

  @override
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

  @override
  Future<List<Map<String, dynamic>>> fetchDailyPricesByAssetIds({
    required List<String> assetIds,
    int lookbackDays = 120,
  }) async {
    if (assetIds.isEmpty) {
      return const [];
    }

    final cutoff = DateTime.now().toUtc().subtract(
      Duration(days: lookbackDays),
    );
    final cutoffText = DateTime.utc(
      cutoff.year,
      cutoff.month,
      cutoff.day,
    ).toIso8601String().substring(0, 10);

    final List<dynamic> rows = await _client
        .from('prices_daily')
        .select('asset_id,price_date,close,adjusted_close')
        .inFilter('asset_id', assetIds)
        .gte('price_date', cutoffText)
        .order('price_date', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }
}
