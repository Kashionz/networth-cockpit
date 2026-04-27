import 'package:supabase/supabase.dart';

class SupabaseAssetsService {
  SupabaseAssetsService({required SupabaseClient client}) : _client = client;

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

  Future<void> upsertAsset(Map<String, dynamic> payload) async {
    await _client.from('assets').upsert(
      payload,
      onConflict: 'user_id,symbol,market,asset_type,currency_code',
    );
  }

  Future<void> upsertHolding(Map<String, dynamic> payload) async {
    await _client
        .from('holdings')
        .upsert(payload, onConflict: 'user_id,asset_id');
  }

  Future<void> upsertDailyPrice(Map<String, dynamic> payload) async {
    await _client
        .from('prices_daily')
        .upsert(payload, onConflict: 'asset_id,price_date');
  }

  Future<void> deleteAsset({
    required String userId,
    required String assetId,
  }) async {
    await _client
        .from('assets')
        .delete()
        .eq('id', assetId)
        .eq('user_id', userId);
  }

  Future<void> deleteHoldingByAssetId({
    required String userId,
    required String assetId,
  }) async {
    await _client
        .from('holdings')
        .delete()
        .eq('asset_id', assetId)
        .eq('user_id', userId);
  }
}
