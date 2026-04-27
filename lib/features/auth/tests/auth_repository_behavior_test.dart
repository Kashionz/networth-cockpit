// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/auth_repository.dart';
import 'package:networth_cockpit/data/services/supabase/supabase_auth_service.dart';
import 'package:supabase/supabase.dart';

void main() {
  group('AuthRepositoryImpl fallback behavior', () {
    test('Supabase 未設定時允許 local fallback', () async {
      final repository = AuthRepositoryImpl(remoteService: null);

      final result = await repository.signUp(
        email: 'local-user@example.com',
        password: 'safe-pass',
      );

      expect(result.success, isTrue);
      expect(result.usedFallback, isTrue);
      expect(result.profile, isNotNull);
      expect(result.profile?.source, AuthProfileSource.local);
    });

    test('Supabase 已設定且遠端登入失敗時回傳失敗', () async {
      final repository = AuthRepositoryImpl(
        remoteService: _ThrowingRemoteService(),
      );

      final result = await repository.signIn(
        email: 'remote-user@example.com',
        password: 'safe-pass',
      );

      expect(result.success, isFalse);
      expect(result.usedFallback, isFalse);
      expect(result.message, contains('Supabase'));
    });

    test('Supabase 已設定且遠端註冊失敗時回傳失敗', () async {
      final repository = AuthRepositoryImpl(
        remoteService: _ThrowingRemoteService(),
      );

      final result = await repository.signUp(
        email: 'remote-user@example.com',
        password: 'safe-pass',
      );

      expect(result.success, isFalse);
      expect(result.usedFallback, isFalse);
      expect(result.message, contains('Supabase'));
    });
  });
}

class _ThrowingRemoteService implements AuthRemoteService {
  @override
  User? get currentUser => null;

  @override
  Future<Map<String, dynamic>?> getProfileByUserId(String userId) async => null;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    throw Exception('simulated signIn failure');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    throw Exception('simulated signUp failure');
  }

  @override
  Future<void> upsertProfile({
    required String userId,
    required String email,
  }) async {}
}
