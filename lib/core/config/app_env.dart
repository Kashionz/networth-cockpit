import 'package:flutter_riverpod/flutter_riverpod.dart';

final appEnvProvider = Provider<AppEnv>((ref) => AppEnv.fromEnvironment());

class AppEnv {
  AppEnv._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.fastApiBaseUrl,
    required this.supabaseL1FunctionName,
  });

  final String? supabaseUrl;
  final String? supabaseAnonKey;
  final String fastApiBaseUrl;
  final String supabaseL1FunctionName;

  bool get hasSupabase {
    final url = supabaseUrl;
    final key = supabaseAnonKey;
    return url != null && url.isNotEmpty && key != null && key.isNotEmpty;
  }

  String? get supabaseFunctionsBaseUrl {
    final url = supabaseUrl;
    if (url == null || url.isEmpty) {
      return null;
    }
    return '${_trimTrailingSlash(url)}/functions/v1';
  }

  String? get l1RulesEndpoint {
    final base = supabaseFunctionsBaseUrl;
    final key = supabaseAnonKey;
    if (base == null || key == null || key.isEmpty) {
      return null;
    }
    return '$base/$supabaseL1FunctionName';
  }

  factory AppEnv.fromEnvironment() {
    final supabaseUrl = _normalize(
      const String.fromEnvironment('SUPABASE_URL'),
    );
    final supabaseAnonKey = _normalize(
      const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
    final fastApiBaseUrl =
        _normalize(const String.fromEnvironment('FASTAPI_BASE_URL')) ??
        'http://localhost:8000';
    final l1FunctionName =
        _normalize(const String.fromEnvironment('SUPABASE_L1_FUNCTION_NAME')) ??
        'l1_health_rules';

    return AppEnv._(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      fastApiBaseUrl: _trimTrailingSlash(fastApiBaseUrl),
      supabaseL1FunctionName: l1FunctionName,
    );
  }

  static String? _normalize(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _trimTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
