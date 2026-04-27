import 'dart:math';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';

import '../../core/config/app_env.dart';
import '../services/supabase/supabase_auth_service.dart';
import '../services/supabase/supabase_client_factory.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = SupabaseClientFactory.create(env);
  final remoteService = client == null
      ? null
      : SupabaseAuthService(client: client);
  return AuthRepositoryImpl(
    remoteService: remoteService,
    allowLocalFallbackWhenRemoteMissing: !env.hasSupabase,
  );
});

abstract interface class AuthRepository {
  Future<AuthResult> signUp({required String email, required String password});

  Future<AuthResult> signIn({required String email, required String password});

  Future<void> signOut();

  Future<UserProfile?> getProfile();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    AuthRemoteService? remoteService,
    bool allowLocalFallbackWhenRemoteMissing = true,
  }) : _remoteService = remoteService,
       _allowLocalFallbackWhenRemoteMissing =
           allowLocalFallbackWhenRemoteMissing;

  final AuthRemoteService? _remoteService;
  final bool _allowLocalFallbackWhenRemoteMissing;
  final Map<String, String> _localCredentials = <String, String>{};
  UserProfile? _localProfile;

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
      return const AuthResult.failure(message: '請輸入有效的帳號與密碼');
    }

    final remote = _remoteService;
    if (remote == null) {
      if (!_allowLocalFallbackWhenRemoteMissing) {
        return const AuthResult.failure(
          message: 'Supabase 設定異常，請確認連線設定後再試。',
          usedFallback: false,
        );
      }
      return _localSignUp(
        email: normalizedEmail,
        password: password,
        message: 'Supabase 未設定，已使用本地測試帳號。',
      );
    }

    try {
      final response = await remote.signUp(
        email: normalizedEmail,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const AuthResult.success(
          message: '註冊請求已送出，請先完成 Email 驗證後再登入。',
          usedFallback: false,
        );
      }

      await remote.upsertProfile(
        userId: user.id,
        email: user.email ?? normalizedEmail,
      );

      final profile =
          await _resolveRemoteProfile(user: user, remote: remote) ??
          UserProfile(
            id: user.id,
            email: user.email ?? normalizedEmail,
            displayName: null,
            updatedAt: DateTime.now().toUtc(),
            source: AuthProfileSource.remote,
          );

      _localCredentials[normalizedEmail] = password;
      _localProfile = profile;

      return AuthResult.success(
        message: '註冊成功，已完成 Supabase 串接。',
        profile: profile,
        usedFallback: false,
      );
    } catch (error, stackTrace) {
      developer.log(
        'signUp remote call failed',
        name: 'AuthRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return AuthResult.failure(
        message: _buildRemoteFailureMessage(action: '註冊', error: error),
        usedFallback: false,
      );
    }
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
      return const AuthResult.failure(message: '請輸入有效的帳號與密碼');
    }

    final remote = _remoteService;
    if (remote == null) {
      if (!_allowLocalFallbackWhenRemoteMissing) {
        return const AuthResult.failure(
          message: 'Supabase 設定異常，請確認連線設定後再試。',
          usedFallback: false,
        );
      }
      return _localSignIn(
        email: normalizedEmail,
        password: password,
        message: 'Supabase 未設定，已使用本地登入。',
      );
    }

    try {
      final response = await remote.signIn(
        email: normalizedEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return const AuthResult.failure(
          message: '登入失敗，請確認帳號密碼或先完成 Email 驗證。',
          usedFallback: false,
        );
      }

      final profile =
          await _resolveRemoteProfile(user: user, remote: remote) ??
          UserProfile(
            id: user.id,
            email: user.email ?? normalizedEmail,
            displayName: null,
            updatedAt: DateTime.now().toUtc(),
            source: AuthProfileSource.remote,
          );

      _localCredentials[normalizedEmail] = password;
      _localProfile = profile;

      return AuthResult.success(
        message: '登入成功。',
        profile: profile,
        usedFallback: false,
      );
    } catch (error, stackTrace) {
      developer.log(
        'signIn remote call failed',
        name: 'AuthRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return AuthResult.failure(
        message: _buildRemoteFailureMessage(action: '登入', error: error),
        usedFallback: false,
      );
    }
  }

  @override
  Future<void> signOut() async {
    final remote = _remoteService;
    if (remote != null) {
      try {
        await remote.signOut();
      } catch (error, stackTrace) {
        developer.log(
          'signOut remote call failed',
          name: 'AuthRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    _localProfile = null;
  }

  @override
  Future<UserProfile?> getProfile() async {
    final remote = _remoteService;
    if (remote == null) {
      return _localProfile;
    }

    try {
      final user = remote.currentUser;
      if (user == null) {
        return _localProfile;
      }

      final profile = await _resolveRemoteProfile(user: user, remote: remote);
      if (profile != null) {
        _localProfile = profile;
        return profile;
      }

      return UserProfile(
        id: user.id,
        email: user.email ?? _localProfile?.email ?? '',
        displayName: _localProfile?.displayName,
        updatedAt: DateTime.now().toUtc(),
        source: AuthProfileSource.remote,
      );
    } catch (error, stackTrace) {
      developer.log(
        'getProfile remote call failed',
        name: 'AuthRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return _localProfile;
    }
  }

  Future<UserProfile?> _resolveRemoteProfile({
    required User user,
    required AuthRemoteService remote,
  }) async {
    final rawProfile = await remote.getProfileByUserId(user.id);
    if (rawProfile == null) {
      return null;
    }

    return UserProfile(
      id: rawProfile['id']?.toString() ?? user.id,
      email:
          rawProfile['email']?.toString() ??
          user.email ??
          _localProfile?.email ??
          '',
      displayName: rawProfile['display_name']?.toString(),
      updatedAt: _tryParseDateTime(rawProfile['updated_at']),
      source: AuthProfileSource.remote,
    );
  }

  AuthResult _localSignUp({
    required String email,
    required String password,
    required String message,
  }) {
    _localCredentials[email] = password;
    _localProfile = _localProfileFromEmail(email);
    return AuthResult.success(
      message: message,
      profile: _localProfile,
      usedFallback: true,
    );
  }

  AuthResult _localSignIn({
    required String email,
    required String password,
    required String message,
  }) {
    final knownPassword = _localCredentials[email];
    if (knownPassword != null && knownPassword != password) {
      return const AuthResult.failure(
        message: '密碼不正確，請再試一次。',
        usedFallback: true,
      );
    }

    _localCredentials.putIfAbsent(email, () => password);
    _localProfile = _localProfileFromEmail(email);

    return AuthResult.success(
      message: message,
      profile: _localProfile,
      usedFallback: true,
    );
  }

  UserProfile _localProfileFromEmail(String email) {
    final seed = email.hashCode.abs();
    return UserProfile(
      id: 'local-${min(seed, 99999999)}',
      email: email,
      displayName: email.split('@').first,
      updatedAt: DateTime.now().toUtc(),
      source: AuthProfileSource.local,
    );
  }

  DateTime? _tryParseDateTime(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  String _buildRemoteFailureMessage({
    required String action,
    required Object error,
  }) {
    if (error is AuthException) {
      final message = error.message.trim();
      if (message.isNotEmpty) {
        return 'Supabase $action失敗：$message';
      }
    }
    return 'Supabase $action失敗，請稍後再試。';
  }
}

class AuthResult {
  const AuthResult._({
    required this.success,
    required this.message,
    required this.profile,
    required this.usedFallback,
  });

  const AuthResult.success({
    required String message,
    UserProfile? profile,
    required bool usedFallback,
  }) : this._(
         success: true,
         message: message,
         profile: profile,
         usedFallback: usedFallback,
       );

  const AuthResult.failure({required String message, bool usedFallback = false})
    : this._(
        success: false,
        message: message,
        profile: null,
        usedFallback: usedFallback,
      );

  final bool success;
  final String message;
  final UserProfile? profile;
  final bool usedFallback;
}

enum AuthProfileSource { remote, local }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.updatedAt,
    required this.source,
  });

  final String id;
  final String email;
  final String? displayName;
  final DateTime? updatedAt;
  final AuthProfileSource source;
}
