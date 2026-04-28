import 'package:supabase/supabase.dart';

abstract interface class IncomeStreamRemoteService {
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> fetchIncomeStreams(String userId);

  Future<Map<String, dynamic>> upsertIncomeStream(Map<String, dynamic> payload);

  Future<void> deleteIncomeStream({required String userId, required String id});
}

class SupabaseIncomeService implements IncomeStreamRemoteService {
  SupabaseIncomeService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  @override
  String? get currentUserId => currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> fetchIncomeStreams(String userId) async {
    final List<dynamic> rows = await _client
        .from('income_streams')
        .select()
        .eq('user_id', userId)
        .order('active', ascending: false)
        .order('next_date', ascending: true)
        .order('updated_at', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> upsertIncomeStream(
    Map<String, dynamic> payload,
  ) async {
    final response = await _client
        .from('income_streams')
        .upsert(payload, onConflict: 'id')
        .select()
        .single();
    return Map<String, dynamic>.from(response as Map);
  }

  @override
  Future<void> deleteIncomeStream({
    required String userId,
    required String id,
  }) async {
    await _client
        .from('income_streams')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
}
