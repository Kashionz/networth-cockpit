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
}
