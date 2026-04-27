import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../features/insights/models/monthly_insight.dart';

const _fastApiBaseUrlFromEnv = String.fromEnvironment('FASTAPI_BASE_URL');

final l2AnalysisHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final l2AnalysisClientProvider = Provider<L2AnalysisClient>((ref) {
  final client = ref.watch(l2AnalysisHttpClientProvider);
  return L2AnalysisClient(httpClient: client);
});

class L2AnalysisClient {
  L2AnalysisClient({String? baseUrl, required http.Client httpClient})
    : baseUrl = _normalize(baseUrl) ?? _normalize(_fastApiBaseUrlFromEnv),
      _httpClient = httpClient;

  final String? baseUrl;
  final http.Client _httpClient;

  Future<MonthlyAnalysisResult> analyzeMonthly({
    required MonthlyInsight seedInsight,
  }) async {
    final fallbackInsight = _buildMonthlyFallback(seedInsight);
    final base = baseUrl;
    if (base == null) {
      return MonthlyAnalysisResult(
        insight: fallbackInsight,
        source: L2ResultSource.fallback,
        reason: 'FASTAPI_BASE_URL 未設定，已使用本地月度解讀。',
      );
    }

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$base/analysis/monthly'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(_buildMonthlyPayload(seedInsight)),
          )
          .timeout(const Duration(seconds: 8));
      if (!_isSuccess(response.statusCode)) {
        return MonthlyAnalysisResult(
          insight: fallbackInsight,
          source: L2ResultSource.fallback,
          reason: '月度分析服務回傳 ${response.statusCode}，已改用本地解讀。',
        );
      }

      final decoded = jsonDecode(response.body);
      final merged = _mergeMonthlyInsight(seedInsight, decoded);
      if (merged == null) {
        return MonthlyAnalysisResult(
          insight: fallbackInsight,
          source: L2ResultSource.fallback,
          reason: '月度分析回應格式不完整，已改用本地解讀。',
        );
      }

      return MonthlyAnalysisResult(
        insight: merged,
        source: L2ResultSource.backend,
        reason: '已套用後端月度分析結果。',
      );
    } catch (error, stackTrace) {
      developer.log(
        'FastAPI monthly analysis failed.',
        name: 'L2AnalysisClient',
        error: error,
        stackTrace: stackTrace,
      );
      return MonthlyAnalysisResult(
        insight: fallbackInsight,
        source: L2ResultSource.fallback,
        reason: '月度分析服務暫時不可用，已改用本地解讀。',
      );
    }
  }

  Future<MerchantClassificationResult> classifyMerchant({
    required String merchantName,
    required num amount,
    required String fallbackCategory,
    required double fallbackConfidence,
  }) async {
    final localFallback = MerchantClassificationResult(
      category: fallbackCategory,
      confidence: fallbackConfidence,
      reason: 'FASTAPI /classify/merchant 無法使用，保留本地分類。',
      source: L2ResultSource.fallback,
    );

    final base = baseUrl;
    if (base == null) {
      return localFallback;
    }

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$base/classify/merchant'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'merchant_name': merchantName,
              'amount': amount,
              'fallback_category': fallbackCategory,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (!_isSuccess(response.statusCode)) {
        return localFallback.copyWith(
          reason: '商家分類服務回傳 ${response.statusCode}，保留本地分類。',
        );
      }

      final decoded = jsonDecode(response.body);
      final parsed = _parseClassificationResponse(decoded);
      if (parsed == null) {
        return localFallback.copyWith(reason: '商家分類回應格式不完整，保留本地分類。');
      }

      return parsed;
    } catch (error, stackTrace) {
      developer.log(
        'FastAPI merchant classification failed.',
        name: 'L2AnalysisClient',
        error: error,
        stackTrace: stackTrace,
      );
      return localFallback.copyWith(reason: '商家分類服務暫時不可用，保留本地分類。');
    }
  }

  Map<String, dynamic> _buildMonthlyPayload(MonthlyInsight insight) {
    final month =
        '${insight.month.year}-${insight.month.month.toString().padLeft(2, '0')}';
    final income = _estimateIncome(insight);
    final expense = _estimateExpense(income, insight.savingsRate);
    final topCategories = _buildTopCategories(insight, expense: expense);
    final notes = _buildNotes(insight);

    return {
      'month': month,
      'income': income,
      'expense': expense,
      'top_categories': topCategories,
      'notes': notes,
    };
  }

  MonthlyInsight _buildMonthlyFallback(MonthlyInsight seed) {
    final netWorthLine = seed.netWorthDelta >= 0
        ? '淨值較上月穩定增加，可延續目前記錄與追蹤節奏。'
        : '淨值較上月回落，建議先檢查本月一次性支出因素。';
    final savingsLine = seed.savingsRate >= seed.savingsRateTarget
        ? '儲蓄率達到目標，可維持現有自動化轉帳安排。'
        : '儲蓄率略低於目標，可在下月先控管彈性支出。';
    final budgetLine = seed.budgetCompletion >= 0.9
        ? '預算執行接近規劃，下月可沿用相同分類節奏。'
        : '預算執行仍有差距，建議優先檢視生活與彈性項目。';

    final outlook = seed.netWorthDelta >= 0
        ? '下月可維持既有定投與預算節奏，並持續每週追蹤一次。'
        : '下月建議先以現金流穩定為主，再逐步恢復原定投節奏。';

    return MonthlyInsight(
      month: seed.month,
      netWorthCurrent: seed.netWorthCurrent,
      netWorthDelta: seed.netWorthDelta,
      savingsRate: seed.savingsRate,
      savingsRateTarget: seed.savingsRateTarget,
      budgetCompletion: seed.budgetCompletion,
      budgetHighlights: seed.budgetHighlights,
      allocationChanges: seed.allocationChanges,
      aiInterpretation: [netWorthLine, savingsLine, budgetLine],
      outlook: outlook,
    );
  }

  MonthlyInsight? _mergeMonthlyInsight(MonthlyInsight seed, Object? decoded) {
    if (decoded is! Map) {
      return null;
    }

    final map = decoded.map((key, value) => MapEntry(key.toString(), value));
    final candidate = map['result'] is Map ? map['result'] : map;
    final payload = (candidate as Map).map(
      (key, value) => MapEntry(key.toString(), value),
    );

    final lines = _extractMonthlyLines(payload);
    if (lines.isEmpty) {
      return null;
    }

    final outlook = payload['outlook']?.toString().trim().isNotEmpty == true
        ? payload['outlook'].toString().trim()
        : _extractOutlookFromRecommendations(payload) ?? seed.outlook;

    return MonthlyInsight(
      month: seed.month,
      netWorthCurrent: seed.netWorthCurrent,
      netWorthDelta: seed.netWorthDelta,
      savingsRate: seed.savingsRate,
      savingsRateTarget: seed.savingsRateTarget,
      budgetCompletion: seed.budgetCompletion,
      budgetHighlights: seed.budgetHighlights,
      allocationChanges: seed.allocationChanges,
      aiInterpretation: lines,
      outlook: outlook,
    );
  }

  List<String> _extractMonthlyLines(Map<String, dynamic> payload) {
    final llmInsight = _extractLlmInsight(payload);
    final recommendations = _extractRecommendations(payload);
    final lines = <String>[
      if (llmInsight != null && llmInsight.isNotEmpty) llmInsight,
      ...recommendations,
    ];
    if (lines.isNotEmpty) {
      return lines;
    }

    const keys = [
      'aiInterpretation',
      'interpretation',
      'analysis',
      'highlights',
    ];
    for (final key in keys) {
      final value = payload[key];
      if (value is List) {
        final lines = value
            .map((item) => item.toString().trim())
            .where((text) => text.isNotEmpty)
            .toList(growable: false);
        if (lines.isNotEmpty) {
          return lines;
        }
      }

      if (value is String) {
        final lines = value
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(growable: false);
        if (lines.isNotEmpty) {
          return lines;
        }
      }
    }
    return const [];
  }

  String? _extractLlmInsight(Map<String, dynamic> payload) {
    final candidates = [
      payload['llm_insight'],
      payload['llmInsight'],
      payload['insight'],
    ];
    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }
      if (candidate is Map) {
        final text = candidate['text']?.toString().trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
      final text = candidate.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  List<String> _extractRecommendations(Map<String, dynamic> payload) {
    final value = payload['recommendations'];
    if (value is List) {
      return value
          .map((item) {
            if (item is Map) {
              final text =
                  item['text'] ?? item['recommendation'] ?? item['title'];
              return text?.toString().trim() ?? '';
            }
            return item.toString().trim();
          })
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
    }

    if (value is String) {
      final line = value.trim();
      return line.isEmpty ? const [] : [line];
    }

    return const [];
  }

  String? _extractOutlookFromRecommendations(Map<String, dynamic> payload) {
    final recommendations = _extractRecommendations(payload);
    if (recommendations.isEmpty) {
      return null;
    }
    return recommendations.first;
  }

  MerchantClassificationResult? _parseClassificationResponse(Object? decoded) {
    if (decoded is! Map) {
      return null;
    }

    final map = decoded.map((key, value) => MapEntry(key.toString(), value));
    final candidate = map['result'] is Map ? map['result'] : map;
    final payload = (candidate as Map).map(
      (key, value) => MapEntry(key.toString(), value),
    );

    final category = payload['category']?.toString().trim();
    if (category == null || category.isEmpty) {
      return null;
    }

    final confidence = _parseDouble(payload['confidence']) ?? 0.8;
    final reason = payload['reason']?.toString().trim().isNotEmpty == true
        ? payload['reason'].toString().trim()
        : '已使用後端商家分類結果。';

    return MerchantClassificationResult(
      category: category,
      confidence: confidence,
      reason: reason,
      source: L2ResultSource.backend,
    );
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  num _estimateIncome(MonthlyInsight insight) {
    final baseline = insight.netWorthCurrent * 0.035;
    final driftAdjustment = insight.netWorthDelta.abs();
    final estimated = baseline + driftAdjustment;
    return estimated < 0 ? 0 : estimated.round();
  }

  num _estimateExpense(num income, double savingsRate) {
    final retained = income * savingsRate.clamp(0, 1);
    final expense = income - retained;
    return expense < 0 ? 0 : expense.round();
  }

  List<Map<String, Object>> _buildTopCategories(
    MonthlyInsight insight, {
    required num expense,
  }) {
    final sorted = [...insight.budgetHighlights]
      ..sort((a, b) => b.completion.compareTo(a.completion));
    final selected = sorted.take(3).toList(growable: false);
    if (selected.isEmpty || expense <= 0) {
      return const [];
    }

    final totalCompletion = selected.fold<double>(
      0,
      (sum, item) => sum + item.completion,
    );
    final denominator = totalCompletion == 0
        ? selected.length
        : totalCompletion;

    return [
      for (final item in selected)
        {
          'category': item.label,
          'amount': ((expense * item.completion) / denominator).round(),
        },
    ];
  }

  String _buildNotes(MonthlyInsight insight) {
    final completion = (insight.budgetCompletion * 100).toStringAsFixed(0);
    final savings = (insight.savingsRate * 100).toStringAsFixed(1);
    return 'budget_completion=$completion%, savings_rate=$savings%, outlook=${insight.outlook}';
  }

  double? _parseDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().trim());
  }

  static String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}

enum L2ResultSource { backend, fallback }

class MonthlyAnalysisResult {
  const MonthlyAnalysisResult({
    required this.insight,
    required this.source,
    required this.reason,
  });

  final MonthlyInsight insight;
  final L2ResultSource source;
  final String reason;

  bool get usedFallback => source == L2ResultSource.fallback;
}

class MerchantClassificationResult {
  const MerchantClassificationResult({
    required this.category,
    required this.confidence,
    required this.reason,
    required this.source,
  });

  final String category;
  final double confidence;
  final String reason;
  final L2ResultSource source;

  bool get usedFallback => source == L2ResultSource.fallback;

  MerchantClassificationResult copyWith({
    String? category,
    double? confidence,
    String? reason,
    L2ResultSource? source,
  }) {
    return MerchantClassificationResult(
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      source: source ?? this.source,
    );
  }
}
