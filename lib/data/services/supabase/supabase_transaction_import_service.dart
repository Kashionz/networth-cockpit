import 'package:supabase/supabase.dart';

abstract interface class TransactionImportRemoteService {
  User? get currentUser;

  Future<String> insertCardStatement(Map<String, dynamic> payload);

  Future<void> insertTransactions(List<Map<String, dynamic>> payloads);
}

class SupabaseTransactionImportService implements TransactionImportRemoteService {
  SupabaseTransactionImportService({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<String> insertCardStatement(Map<String, dynamic> payload) async {
    final response = await _client
        .from('card_statements')
        .insert(payload)
        .select('id')
        .single();
    return response['id'].toString();
  }

  @override
  Future<void> insertTransactions(List<Map<String, dynamic>> payloads) {
    return _client.from('transactions').insert(payloads);
  }
}
