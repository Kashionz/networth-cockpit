import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_env.dart';
import 'health_models.dart';
import 'local_health_rule_engine.dart';

final l1RulesHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final l1HealthRulesServiceProvider = Provider<L1HealthRulesService>((ref) {
  final env = ref.watch(appEnvProvider);
  final client = ref.watch(l1RulesHttpClientProvider);
  return L1HealthRulesService(
    endpoint: env.l1RulesEndpoint,
    anonKey: env.supabaseAnonKey,
    fallbackEngine: const LocalHealthRuleEngine(),
    httpClient: client,
  );
});

class L1HealthRulesService {
  L1HealthRulesService({
    required this.endpoint,
    required this.anonKey,
    required this.fallbackEngine,
    required http.Client httpClient,
  }) : _httpClient = httpClient;

  final String? endpoint;
  final String? anonKey;
  final LocalHealthRuleEngine fallbackEngine;
  final http.Client _httpClient;

  Future<HealthRuleEvaluation> evaluate(HealthDashboardMetrics metrics) async {
    final target = endpoint;
    final key = anonKey;
    if (target == null || key == null || key.isEmpty) {
      return fallbackEngine.evaluate(
        metrics,
        reason: 'Edge Function 端點或金鑰未設定。',
      );
    }

    try {
      final response = await _httpClient
          .post(
            Uri.parse(target),
            headers: {
              'Content-Type': 'application/json',
              'apikey': key,
              'Authorization': 'Bearer $key',
            },
            body: jsonEncode({'metrics': metrics.toJson()}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallbackEngine.evaluate(
          metrics,
          reason: 'Edge Function 回傳狀態碼 ${response.statusCode}。',
        );
      }

      final parsed = jsonDecode(response.body);
      if (parsed is! Map<String, dynamic>) {
        return fallbackEngine.evaluate(
          metrics,
          reason: 'Edge Function 回應格式不符。',
        );
      }

      final hints = _parseHints(parsed['hints']);
      return HealthRuleEvaluation(
        summary: parsed['summary']?.toString() ?? '已由 L1 規則層產生健康提示。',
        hints: hints,
        source: HealthRuleSource.edgeFunction,
        usedFallback: false,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Edge function call failed',
        name: 'L1HealthRulesService',
        error: error,
        stackTrace: stackTrace,
      );
      return fallbackEngine.evaluate(
        metrics,
        reason: 'Edge Function 呼叫失敗，已回退本地規則。',
      );
    }
  }

  List<HealthHint> _parseHints(Object? rawHints) {
    if (rawHints is! List) {
      return const [
        HealthHint(
          id: 'edge-default',
          title: '本月健康提示已更新',
          detail: '建議持續追蹤收支、負債與現金流穩定度。',
          level: HealthHintLevel.info,
        ),
      ];
    }

    final parsedHints = rawHints
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry(key.toString(), value)))
        .map(HealthHint.fromJson)
        .toList(growable: false);

    if (parsedHints.isEmpty) {
      return const [
        HealthHint(
          id: 'edge-empty',
          title: '本月健康提示已更新',
          detail: '目前沒有額外提醒，可維持既有策略。',
          level: HealthHintLevel.info,
        ),
      ];
    }

    return parsedHints;
  }
}
