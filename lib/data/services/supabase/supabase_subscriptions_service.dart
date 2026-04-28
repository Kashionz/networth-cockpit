import 'package:supabase/supabase.dart';

abstract interface class SubscriptionsRemoteService {
  User? get currentUser;

  Future<List<Map<String, dynamic>>> fetchSubscriptionsByUserId(String userId);

  Future<List<Map<String, dynamic>>> fetchDueSubscriptionsByUserId({
    required String userId,
    required DateTime onDate,
  });

  Future<void> upsertSubscription(Map<String, dynamic> payload);

  Future<void> deleteSubscription({
    required String userId,
    required String subscriptionId,
  });

  Future<String> insertTransaction(Map<String, dynamic> payload);

  Future<void> updateSubscriptionNextBillingDate({
    required String userId,
    required String subscriptionId,
    required DateTime nextBillingDate,
  });
}

class SupabaseSubscriptionsService implements SubscriptionsRemoteService {
  SupabaseSubscriptionsService({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<List<Map<String, dynamic>>> fetchSubscriptionsByUserId(
    String userId,
  ) async {
    final List<dynamic> rows = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .order('is_active', ascending: false)
        .order('next_billing_date', ascending: true);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDueSubscriptionsByUserId({
    required String userId,
    required DateTime onDate,
  }) async {
    final List<dynamic> rows = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .lte('next_billing_date', _toDate(onDate))
        .order('next_billing_date', ascending: true);

    return rows
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  @override
  Future<void> upsertSubscription(Map<String, dynamic> payload) async {
    await _client.from('subscriptions').upsert(payload, onConflict: 'id');
  }

  @override
  Future<void> deleteSubscription({
    required String userId,
    required String subscriptionId,
  }) async {
    await _client
        .from('subscriptions')
        .delete()
        .eq('id', subscriptionId)
        .eq('user_id', userId);
  }

  @override
  Future<String> insertTransaction(Map<String, dynamic> payload) async {
    final response = await _client
        .from('transactions')
        .insert(payload)
        .select('id')
        .single();
    return response['id'].toString();
  }

  @override
  Future<void> updateSubscriptionNextBillingDate({
    required String userId,
    required String subscriptionId,
    required DateTime nextBillingDate,
  }) async {
    await _client
        .from('subscriptions')
        .update({'next_billing_date': _toDate(nextBillingDate)})
        .eq('id', subscriptionId)
        .eq('user_id', userId);
  }
}

String _toDate(DateTime value) {
  final utc = DateTime.utc(value.year, value.month, value.day);
  final year = utc.year.toString().padLeft(4, '0');
  final month = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
