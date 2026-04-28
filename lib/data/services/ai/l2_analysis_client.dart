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
    num? monthlyIncome,
    List<Map<String, Object?>>? priceHistory,
    List<Map<String, Object?>>? benchmarkHistory,
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
            body: jsonEncode(
              _buildMonthlyPayload(
                seedInsight,
                monthlyIncome: monthlyIncome,
                priceHistory: priceHistory,
                benchmarkHistory: benchmarkHistory,
              ),
            ),
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
        sharpeRatio: merged.quantMetrics.sharpeRatio,
        annualizedVolatility: merged.quantMetrics.volatility,
        maxDrawdownPct: merged.quantMetrics.maxDrawdown,
        benchmarkDiffPct: merged.quantMetrics.benchmarkExcessReturn,
        stressTestResult: _stressResultToMap(merged.quantMetrics.stressTests),
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

  Map<String, dynamic> _buildMonthlyPayload(
    MonthlyInsight insight, {
    num? monthlyIncome,
    List<Map<String, Object?>>? priceHistory,
    List<Map<String, Object?>>? benchmarkHistory,
  }) {
    final month =
        '${insight.month.year}-${insight.month.month.toString().padLeft(2, '0')}';
    final resolvedIncome = monthlyIncome != null && monthlyIncome > 0
        ? monthlyIncome
        : _estimateIncome(insight);
    final income = resolvedIncome < 0 ? 0 : resolvedIncome.round();
    final expense = _estimateExpense(income, insight.savingsRate);
    final topCategories = _buildTopCategories(insight, expense: expense);
    final notes = _buildNotes(insight);

    return {
      'month': month,
      'income': income,
      'expense': expense,
      'price_history': _normalizeHistoryPayload(priceHistory),
      'benchmark_history': _normalizeHistoryPayload(benchmarkHistory),
      'top_categories': topCategories,
      'quant_metrics': {
        'return_rate': insight.quantMetrics.returnRate,
        'annualized_volatility': insight.quantMetrics.volatility,
        'sharpe': insight.quantMetrics.sharpeRatio,
        'max_drawdown': insight.quantMetrics.maxDrawdown,
        'benchmark_return_rate': insight.quantMetrics.benchmarkReturnRate,
        'benchmark_excess_return': insight.quantMetrics.benchmarkExcessReturn,
        'stress_tests': [
          for (final scenario in insight.quantMetrics.stressTests)
            scenario.toJson(),
        ],
      },
      'trace': {
        'context_hash': insight.aiTrace.contextHash == 'unknown'
            ? insight.contextHash
            : insight.aiTrace.contextHash,
        'source': insight.aiTrace.source,
      },
      'notes': notes,
    };
  }

  MonthlyInsight _buildMonthlyFallback(MonthlyInsight seed) {
    final outlook = seed.netWorthDelta >= 0
        ? '下月可維持既有定投與預算節奏，並持續每週追蹤一次。'
        : '下月建議先以現金流穩定為主，再逐步恢復原定投節奏。';

    return seed.copyWith(
      aiInterpretation: _buildGovernedInterpretation(seed),
      outlook: outlook,
      aiTrace: AiGovernanceTrace(
        model: 'local-deterministic',
        source: 'l2_fallback',
        status: 'fallback',
        contextHash: seed.contextHash,
        generatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
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

    final backendQuant = QuantMetrics.fromJson(_extractQuantPayload(payload));
    final mergedQuant = _mergeQuantMetrics(seed.quantMetrics, backendQuant);
    final provisional = seed.copyWith(quantMetrics: mergedQuant);
    final lines = _buildGovernedInterpretation(
      provisional,
      candidateLines: _extractMonthlyLines(payload),
    );

    final outlook = payload['outlook']?.toString().trim().isNotEmpty == true
        ? payload['outlook'].toString().trim()
        : _extractOutlookFromRecommendations(payload) ?? provisional.outlook;
    final trace = _traceFromPayload(
      payload,
      fallbackContextHash: seed.aiTrace.contextHash == 'unknown'
          ? provisional.contextHash
          : seed.aiTrace.contextHash,
    );

    return provisional.copyWith(
      aiInterpretation: lines,
      outlook: outlook,
      aiTrace: trace,
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
    final returnRate = (insight.quantMetrics.returnRate * 100).toStringAsFixed(
      2,
    );
    final volatility = (insight.quantMetrics.volatility * 100).toStringAsFixed(
      2,
    );
    final sharpe = insight.quantMetrics.sharpeRatio.toStringAsFixed(2);
    return 'budget_completion=$completion%, savings_rate=$savings%, return_rate=$returnRate%, volatility=$volatility%, sharpe=$sharpe, outlook=${insight.outlook}';
  }

  QuantMetrics _mergeQuantMetrics(QuantMetrics seed, QuantMetrics backend) {
    final stressTests = backend.stressTests.isNotEmpty
        ? backend.stressTests
        : seed.stressTests;
    return QuantMetrics(
      returnRate: _pickDouble(seed.returnRate, backend.returnRate),
      volatility: _pickDouble(seed.volatility, backend.volatility),
      sharpeRatio: _pickDouble(seed.sharpeRatio, backend.sharpeRatio),
      maxDrawdown: _pickDouble(seed.maxDrawdown, backend.maxDrawdown),
      benchmarkReturnRate: _pickDouble(
        seed.benchmarkReturnRate,
        backend.benchmarkReturnRate,
      ),
      benchmarkExcessReturn: _pickDouble(
        seed.benchmarkExcessReturn,
        backend.benchmarkExcessReturn,
      ),
      stressTests: stressTests,
    );
  }

  Map<String, dynamic> _extractQuantPayload(Map<String, dynamic> payload) {
    final nested = payload['quant_metrics'] ?? payload['quantMetrics'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }

    final maxDrawdownPct = _parseDouble(
      payload['max_drawdown_pct'] ?? payload['maxDrawdownPct'],
    );
    final benchmarkDiffPct = _parseDouble(
      payload['benchmark_diff_pct'] ?? payload['benchmarkDiffPct'],
    );

    return {
      'annualized_volatility':
          payload['annualized_volatility'] ?? payload['annualizedVolatility'],
      'sharpe_ratio': payload['sharpe_ratio'] ?? payload['sharpeRatio'],
      if (maxDrawdownPct != null)
        'max_drawdown': _pctToDecimalIfNeeded(maxDrawdownPct),
      if (benchmarkDiffPct != null)
        'benchmark_excess_return': _pctToDecimalIfNeeded(benchmarkDiffPct),
      'stress_tests': _stressTestsFromResult(
        payload['stress_test_result'] ?? payload['stressTestResult'],
      ),
    };
  }

  List<Map<String, dynamic>> _normalizeHistoryPayload(
    List<Map<String, Object?>>? history,
  ) {
    if (history == null || history.isEmpty) {
      return const [];
    }

    final rows = <Map<String, dynamic>>[];
    for (final entry in history) {
      final rawDate = entry['date'];
      final rawClose = entry['close'];
      final close = _parseDouble(rawClose);
      final dateText = rawDate?.toString().trim();
      if (close == null || dateText == null || dateText.isEmpty) {
        continue;
      }
      rows.add({'date': dateText, 'close': close});
    }
    return rows;
  }

  List<Map<String, dynamic>> _stressTestsFromResult(Object? raw) {
    if (raw is! Map) {
      return const [];
    }

    final tests = <Map<String, dynamic>>[];
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(value);
      if (map['ok'] != true) {
        continue;
      }

      final shockPct = _parseDouble(map['shock_pct']);
      final drawdownPct = _parseDouble(map['stressed_max_drawdown_pct']);
      final returnPct = _parseDouble(map['stressed_annualized_return_pct']);

      tests.add({
        'name': _scenarioNameFromKey(key),
        if (shockPct != null) 'shock_rate': _pctToDecimalIfNeeded(shockPct.abs()),
        if (drawdownPct != null)
          'projected_drawdown': _pctToDecimalIfNeeded(drawdownPct.abs()),
        if (returnPct != null)
          'projected_return_rate': _pctToDecimalIfNeeded(returnPct),
      });
    }

    return tests;
  }

  String _scenarioNameFromKey(String key) {
    if (key.trim().isEmpty) {
      return '情境壓測';
    }
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'(^| )([a-z])'),
          (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
        )
        .trim();
  }

  double _pctToDecimalIfNeeded(double value) {
    if (value.abs() > 1) {
      return value / 100;
    }
    return value;
  }

  Map<String, dynamic>? _stressResultToMap(List<StressTestScenario> scenarios) {
    if (scenarios.isEmpty) {
      return null;
    }
    return {
      'scenarios': [
        for (final scenario in scenarios)
          {
            'name': scenario.name,
            'shock_rate': scenario.shockRate,
            'projected_drawdown': scenario.projectedDrawdown,
            'projected_return_rate': scenario.projectedReturnRate,
          },
      ],
    };
  }

  double _pickDouble(double seed, double backend) {
    if (backend != 0) {
      return backend;
    }
    return seed;
  }

  List<String> _buildGovernedInterpretation(
    MonthlyInsight insight, {
    List<String> candidateLines = const [],
  }) {
    final metrics = insight.quantMetrics;
    final returnRate = (metrics.returnRate * 100).toStringAsFixed(2);
    final benchmark = (metrics.benchmarkReturnRate * 100).toStringAsFixed(2);
    final excess = (metrics.benchmarkExcessReturn * 100).toStringAsFixed(2);
    final volatility = (metrics.volatility * 100).toStringAsFixed(2);
    final drawdown = (metrics.maxDrawdown * 100).toStringAsFixed(2);
    final sharpe = metrics.sharpeRatio.toStringAsFixed(2);
    final worstStress = metrics.stressTests.isNotEmpty
        ? metrics.stressTests.reduce(
            (left, right) => left.projectedDrawdown >= right.projectedDrawdown
                ? left
                : right,
          )
        : null;

    final lines = <String>[
      '本月報酬率 $returnRate%，基準 $benchmark%，超額 $excess%。',
      '年化波動率 $volatility%，Sharpe $sharpe，最大回撤 $drawdown%。',
      if (worstStress != null)
        '${worstStress.name}（衝擊 ${worstStress.shockRateLabel}）下，預估回撤 ${worstStress.projectedDrawdownLabel}、情境報酬 ${worstStress.projectedReturnLabel}。',
    ];

    for (final line in candidateLines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (!_hasNumericSignal(trimmed)) {
        continue;
      }
      if (!lines.contains(trimmed)) {
        lines.add(trimmed);
      }
      if (lines.length >= 5) {
        break;
      }
    }

    return lines;
  }

  bool _hasNumericSignal(String text) {
    return RegExp(r'[\d%\.]+').hasMatch(text);
  }

  AiGovernanceTrace _traceFromPayload(
    Map<String, dynamic> payload, {
    required String fallbackContextHash,
  }) {
    final traceRaw = payload['trace'] ?? payload['ai_trace'];
    if (traceRaw is Map) {
      return AiGovernanceTrace.fromJson(
        traceRaw,
        fallbackContextHash: fallbackContextHash,
      );
    }

    final model = _firstNonEmptyText([
      payload['model'],
      payload['llm_model'],
      payload['model_name'],
    ]);
    final source = _firstNonEmptyText([
      payload['source'],
      payload['provider'],
      'fastapi_l2',
    ]);
    final status = _firstNonEmptyText([
      payload['status'],
      payload['result_status'],
      'ok',
    ]);
    final contextHash = _firstNonEmptyText([
      payload['context_hash'],
      payload['contextHash'],
      fallbackContextHash,
    ]);

    return AiGovernanceTrace(
      model: model ?? 'unknown',
      source: source ?? 'unknown',
      status: status ?? 'ok',
      contextHash: contextHash ?? fallbackContextHash,
      generatedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  String? _firstNonEmptyText(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
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
    this.sharpeRatio,
    this.annualizedVolatility,
    this.maxDrawdownPct,
    this.benchmarkDiffPct,
    this.stressTestResult,
  });

  final MonthlyInsight insight;
  final L2ResultSource source;
  final String reason;
  final double? sharpeRatio;
  final double? annualizedVolatility;
  final double? maxDrawdownPct;
  final double? benchmarkDiffPct;
  final Map<String, dynamic>? stressTestResult;

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
