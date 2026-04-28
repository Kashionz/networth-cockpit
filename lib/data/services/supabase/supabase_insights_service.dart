import 'package:supabase/supabase.dart';

class SupabaseInsightsService {
  SupabaseInsightsService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<Map<String, dynamic>>> fetchMonthlyReportInsightsByUserId(
    String userId, {
    int limit = 48,
  }) async {
    final List<dynamic> rows = await _client
        .from('insights')
        .select()
        .eq('user_id', userId)
        .eq('insight_type', 'monthly_report')
        .order('snapshot_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchMilestoneInsightsByUserId(
    String userId, {
    int limit = 100,
  }) async {
    final List<dynamic> rows = await _client
        .from('insights')
        .select()
        .eq('user_id', userId)
        .eq('insight_type', 'milestone')
        .order('snapshot_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<void> insertInsight(Map<String, dynamic> payload) async {
    await _client.from('insights').insert(payload);
  }

  Future<void> updateInsightById({
    required String insightId,
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    await _client
        .from('insights')
        .update(payload)
        .eq('id', insightId)
        .eq('user_id', userId);
  }
}
