import 'package:supabase/supabase.dart';

abstract interface class AuthRemoteService {
  User? get currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  });

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> upsertProfile({required String userId, required String email});

  Future<Map<String, dynamic>?> getProfileByUserId(String userId);
}

class SupabaseAuthService implements AuthRemoteService {
  SupabaseAuthService({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  @override
  Future<void> upsertProfile({
    required String userId,
    required String email,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'email': email,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<Map<String, dynamic>?> getProfileByUserId(String userId) async {
    final List<dynamic> result = await _client
        .from('profiles')
        .select('id, email, display_name, updated_at')
        .eq('id', userId)
        .limit(1);

    if (result.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(result.first as Map);
  }
}
