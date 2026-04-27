import 'package:supabase/supabase.dart';

class SupabaseTransactionsService {
  SupabaseTransactionsService({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<Map<String, dynamic>>> fetchManualTransactionsByUserId(
    String userId,
  ) async {
    final List<dynamic> rows = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .eq('transaction_type', 'expense')
        .order('occurred_at', ascending: false);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<void> upsertTransaction(Map<String, dynamic> payload) async {
    await _client.from('transactions').upsert(payload, onConflict: 'id');
  }

  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    await _client
        .from('transactions')
        .delete()
        .eq('id', transactionId)
        .eq('user_id', userId);
  }
}
