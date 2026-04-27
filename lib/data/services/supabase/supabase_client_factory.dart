import 'dart:developer' as developer;

import 'package:supabase/supabase.dart';

import '../../../core/config/app_env.dart';

class SupabaseClientFactory {
  const SupabaseClientFactory._();

  static SupabaseClient? create(AppEnv env) {
    if (!env.hasSupabase) {
      return null;
    }

    final url = env.supabaseUrl;
    final anonKey = env.supabaseAnonKey;
    if (url == null || anonKey == null) {
      return null;
    }

    try {
      return SupabaseClient(url, anonKey);
    } catch (error, stackTrace) {
      developer.log(
        'Supabase client init failed',
        name: 'SupabaseClientFactory',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
