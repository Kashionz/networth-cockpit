import '../../../shared/models/month_key.dart';

class MonthlyInsight {
  const MonthlyInsight({
    required this.month,
    required this.netWorthCurrent,
    required this.netWorthDelta,
    required this.savingsRate,
    required this.savingsRateTarget,
    required this.budgetCompletion,
    required this.budgetHighlights,
    required this.allocationChanges,
    required this.aiInterpretation,
    required this.outlook,
    this.quantMetrics = const QuantMetrics.empty(),
    this.aiTrace = const AiGovernanceTrace.fallback(),
  });

  final MonthKey month;
  final num netWorthCurrent;
  final num netWorthDelta;
  final double savingsRate;
  final double savingsRateTarget;
  final double budgetCompletion;
  final List<BudgetRecapItem> budgetHighlights;
  final List<AllocationChangeItem> allocationChanges;
  final List<String> aiInterpretation;
  final String outlook;
  final QuantMetrics quantMetrics;
  final AiGovernanceTrace aiTrace;

  bool get netWorthIncreased => netWorthDelta >= 0;

  String get monthLabel => month.zhLabel;
  String get contextHash => _stableContextHash(this);

  String get savingsRateLabel => '${(savingsRate * 100).toStringAsFixed(1)}%';

  String get savingsTargetLabel =>
      '${(savingsRateTarget * 100).toStringAsFixed(0)}%';

  String get budgetCompletionLabel =>
      '${(budgetCompletion * 100).toStringAsFixed(0)}%';

  MonthlyInsight copyWith({
    MonthKey? month,
    num? netWorthCurrent,
    num? netWorthDelta,
    double? savingsRate,
    double? savingsRateTarget,
    double? budgetCompletion,
    List<BudgetRecapItem>? budgetHighlights,
    List<AllocationChangeItem>? allocationChanges,
    List<String>? aiInterpretation,
    String? outlook,
    QuantMetrics? quantMetrics,
    AiGovernanceTrace? aiTrace,
  }) {
    final next = MonthlyInsight(
      month: month ?? this.month,
      netWorthCurrent: netWorthCurrent ?? this.netWorthCurrent,
      netWorthDelta: netWorthDelta ?? this.netWorthDelta,
      savingsRate: savingsRate ?? this.savingsRate,
      savingsRateTarget: savingsRateTarget ?? this.savingsRateTarget,
      budgetCompletion: budgetCompletion ?? this.budgetCompletion,
      budgetHighlights: budgetHighlights ?? this.budgetHighlights,
      allocationChanges: allocationChanges ?? this.allocationChanges,
      aiInterpretation: aiInterpretation ?? this.aiInterpretation,
      outlook: outlook ?? this.outlook,
      quantMetrics: quantMetrics ?? this.quantMetrics,
      aiTrace: aiTrace ?? this.aiTrace,
    );
    return next;
  }

  Map<String, dynamic> toJson() {
    return {
      'month': {'year': month.year, 'month': month.month},
      'netWorthCurrent': netWorthCurrent,
      'netWorthDelta': netWorthDelta,
      'savingsRate': savingsRate,
      'savingsRateTarget': savingsRateTarget,
      'budgetCompletion': budgetCompletion,
      'budgetHighlights': [for (final item in budgetHighlights) item.toJson()],
      'allocationChanges': [
        for (final item in allocationChanges) item.toJson(),
      ],
      'quantMetrics': quantMetrics.toJson(),
      'aiInterpretation': aiInterpretation,
      'outlook': outlook,
      'aiTrace': aiTrace.toJson(fallbackContextHash: contextHash),
      'snapshotSummary': {
        'netWorthCurrent': netWorthCurrent,
        'netWorthDelta': netWorthDelta,
        'savingsRate': savingsRate,
        'budgetCompletion': budgetCompletion,
        'budgetHighlights': [
          for (final item in budgetHighlights) item.toJson(),
        ],
        'allocationChanges': [
          for (final item in allocationChanges) item.toJson(),
        ],
        'quantMetrics': quantMetrics.toJson(),
      },
    };
  }

  factory MonthlyInsight.fromJson(
    Map<String, dynamic> json, {
    MonthKey? fallbackMonth,
  }) {
    final month =
        _parseMonthKey(json['month']) ??
        _parseMonthKey(json['month_key']) ??
        _parseMonthKey(json['snapshotMonth']) ??
        fallbackMonth ??
        MonthKey.fromDate(DateTime.now());

    final netWorthCurrent =
        _toNum(json['netWorthCurrent']) ??
        _toNum(json['net_worth_current']) ??
        0;
    final netWorthDelta =
        _toNum(json['netWorthDelta']) ?? _toNum(json['net_worth_delta']) ?? 0;
    final savingsRate =
        _toDouble(json['savingsRate']) ?? _toDouble(json['savings_rate']) ?? 0;
    final savingsRateTarget =
        _toDouble(json['savingsRateTarget']) ??
        _toDouble(json['savings_rate_target']) ??
        0.3;
    final budgetCompletion =
        _toDouble(json['budgetCompletion']) ??
        _toDouble(json['budget_completion']) ??
        0;

    final budgetHighlights = _parseBudgetHighlights(
      json['budgetHighlights'] ?? json['budget_highlights'],
    );
    final allocationChanges = _parseAllocationChanges(
      json['allocationChanges'] ?? json['allocation_changes'],
    );
    final quantMetrics = QuantMetrics.fromJson(
      json['quantMetrics'] ?? json['quant_metrics'],
    );
    final aiInterpretation = _parseStringList(
      json['aiInterpretation'] ?? json['ai_interpretation'],
    );
    final outlook = json['outlook']?.toString().trim() ?? '';

    final insight = MonthlyInsight(
      month: month,
      netWorthCurrent: netWorthCurrent,
      netWorthDelta: netWorthDelta,
      savingsRate: savingsRate,
      savingsRateTarget: savingsRateTarget,
      budgetCompletion: budgetCompletion,
      budgetHighlights: budgetHighlights,
      allocationChanges: allocationChanges,
      quantMetrics: quantMetrics,
      aiInterpretation: aiInterpretation.isEmpty
          ? const ['本月指標已完成彙整，可持續觀察趨勢變化。']
          : aiInterpretation,
      outlook: outlook.isEmpty ? '建議維持既有檢視節奏並持續追蹤。' : outlook,
    );

    return insight.copyWith(
      aiTrace: AiGovernanceTrace.fromJson(
        json['aiTrace'] ?? json['ai_trace'],
        fallbackContextHash: insight.contextHash,
      ),
    );
  }
}

class QuantMetrics {
  const QuantMetrics({
    required this.returnRate,
    required this.volatility,
    required this.sharpeRatio,
    required this.maxDrawdown,
    required this.benchmarkReturnRate,
    required this.benchmarkExcessReturn,
    required this.stressTests,
  });

  const QuantMetrics.empty()
    : returnRate = 0,
      volatility = 0,
      sharpeRatio = 0,
      maxDrawdown = 0,
      benchmarkReturnRate = 0,
      benchmarkExcessReturn = 0,
      stressTests = const [];

  final double returnRate;
  final double volatility;
  final double sharpeRatio;
  final double maxDrawdown;
  final double benchmarkReturnRate;
  final double benchmarkExcessReturn;
  final List<StressTestScenario> stressTests;

  String get returnRateLabel => '${(returnRate * 100).toStringAsFixed(2)}%';
  String get volatilityLabel => '${(volatility * 100).toStringAsFixed(2)}%';
  String get sharpeLabel => sharpeRatio.toStringAsFixed(2);
  String get maxDrawdownLabel => '${(maxDrawdown * 100).toStringAsFixed(2)}%';
  String get benchmarkReturnLabel =>
      '${(benchmarkReturnRate * 100).toStringAsFixed(2)}%';
  String get excessReturnLabel =>
      '${(benchmarkExcessReturn * 100).toStringAsFixed(2)}%';

  QuantMetrics copyWith({
    double? returnRate,
    double? volatility,
    double? sharpeRatio,
    double? maxDrawdown,
    double? benchmarkReturnRate,
    double? benchmarkExcessReturn,
    List<StressTestScenario>? stressTests,
  }) {
    return QuantMetrics(
      returnRate: returnRate ?? this.returnRate,
      volatility: volatility ?? this.volatility,
      sharpeRatio: sharpeRatio ?? this.sharpeRatio,
      maxDrawdown: maxDrawdown ?? this.maxDrawdown,
      benchmarkReturnRate: benchmarkReturnRate ?? this.benchmarkReturnRate,
      benchmarkExcessReturn:
          benchmarkExcessReturn ?? this.benchmarkExcessReturn,
      stressTests: stressTests ?? this.stressTests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'returnRate': returnRate,
      'volatility': volatility,
      'sharpeRatio': sharpeRatio,
      'maxDrawdown': maxDrawdown,
      'benchmarkReturnRate': benchmarkReturnRate,
      'benchmarkExcessReturn': benchmarkExcessReturn,
      'stressTests': [for (final item in stressTests) item.toJson()],
    };
  }

  factory QuantMetrics.fromJson(Object? raw) {
    if (raw is! Map) {
      return const QuantMetrics.empty();
    }

    final json = Map<String, dynamic>.from(raw);
    final stressTests = _parseStressTests(
      json['stressTests'] ?? json['stress_tests'],
    );

    return QuantMetrics(
      returnRate:
          _toDouble(json['returnRate']) ?? _toDouble(json['return_rate']) ?? 0,
      volatility:
          _toDouble(json['volatility']) ??
          _toDouble(json['annualized_volatility']) ??
          0,
      sharpeRatio:
          _toDouble(json['sharpeRatio']) ??
          _toDouble(json['sharpe']) ??
          _toDouble(json['sharpe_ratio']) ??
          0,
      maxDrawdown:
          _toDouble(json['maxDrawdown']) ??
          _toDouble(json['max_drawdown']) ??
          0,
      benchmarkReturnRate:
          _toDouble(json['benchmarkReturnRate']) ??
          _toDouble(json['benchmark_return_rate']) ??
          0,
      benchmarkExcessReturn:
          _toDouble(json['benchmarkExcessReturn']) ??
          _toDouble(json['benchmark_excess_return']) ??
          0,
      stressTests: stressTests,
    );
  }
}

class StressTestScenario {
  const StressTestScenario({
    required this.name,
    required this.shockRate,
    required this.projectedDrawdown,
    required this.projectedReturnRate,
  });

  final String name;
  final double shockRate;
  final double projectedDrawdown;
  final double projectedReturnRate;

  String get shockRateLabel => '${(shockRate * 100).toStringAsFixed(0)}%';
  String get projectedDrawdownLabel =>
      '${(projectedDrawdown * 100).toStringAsFixed(2)}%';
  String get projectedReturnLabel =>
      '${(projectedReturnRate * 100).toStringAsFixed(2)}%';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'shockRate': shockRate,
      'projectedDrawdown': projectedDrawdown,
      'projectedReturnRate': projectedReturnRate,
    };
  }

  factory StressTestScenario.fromJson(Map<String, dynamic> json) {
    return StressTestScenario(
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : '情境壓測',
      shockRate:
          _toDouble(json['shockRate']) ?? _toDouble(json['shock_rate']) ?? 0,
      projectedDrawdown:
          _toDouble(json['projectedDrawdown']) ??
          _toDouble(json['projected_drawdown']) ??
          0,
      projectedReturnRate:
          _toDouble(json['projectedReturnRate']) ??
          _toDouble(json['projected_return_rate']) ??
          0,
    );
  }
}

class AiGovernanceTrace {
  const AiGovernanceTrace({
    required this.model,
    required this.source,
    required this.status,
    required this.contextHash,
    this.generatedAt,
  });

  const AiGovernanceTrace.fallback({
    this.model = 'local-deterministic',
    this.source = 'l2_fallback',
    this.status = 'fallback',
    this.contextHash = 'unknown',
    this.generatedAt,
  });

  final String model;
  final String source;
  final String status;
  final String contextHash;
  final String? generatedAt;

  AiGovernanceTrace copyWith({
    String? model,
    String? source,
    String? status,
    String? contextHash,
    String? generatedAt,
  }) {
    return AiGovernanceTrace(
      model: model ?? this.model,
      source: source ?? this.source,
      status: status ?? this.status,
      contextHash: contextHash ?? this.contextHash,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson({String? fallbackContextHash}) {
    final context = contextHash.trim().isNotEmpty
        ? contextHash
        : (fallbackContextHash ?? 'unknown');
    return {
      'model': model,
      'source': source,
      'status': status,
      'contextHash': context,
      if (generatedAt != null) 'generatedAt': generatedAt,
    };
  }

  factory AiGovernanceTrace.fromJson(
    Object? raw, {
    required String fallbackContextHash,
  }) {
    if (raw is! Map) {
      return AiGovernanceTrace.fallback(contextHash: fallbackContextHash);
    }
    final json = Map<String, dynamic>.from(raw);
    final model = json['model']?.toString().trim();
    final source = json['source']?.toString().trim();
    final status = json['status']?.toString().trim();
    final contextHash =
        json['contextHash']?.toString().trim() ??
        json['context_hash']?.toString().trim();

    return AiGovernanceTrace(
      model: model == null || model.isEmpty ? 'unknown' : model,
      source: source == null || source.isEmpty ? 'unknown' : source,
      status: status == null || status.isEmpty ? 'unknown' : status,
      contextHash: contextHash == null || contextHash.isEmpty
          ? fallbackContextHash
          : contextHash,
      generatedAt:
          json['generatedAt']?.toString() ?? json['generated_at']?.toString(),
    );
  }
}

class BudgetRecapItem {
  const BudgetRecapItem({
    required this.label,
    required this.completion,
    required this.note,
  });

  final String label;
  final double completion;
  final String note;

  String get completionLabel => '${(completion * 100).toStringAsFixed(0)}%';

  Map<String, dynamic> toJson() {
    return {'label': label, 'completion': completion, 'note': note};
  }

  factory BudgetRecapItem.fromJson(Map<String, dynamic> json) {
    return BudgetRecapItem(
      label: json['label']?.toString().trim().isNotEmpty == true
          ? json['label'].toString().trim()
          : '未分類',
      completion:
          _toDouble(json['completion']) ??
          _toDouble(json['completion_rate']) ??
          0,
      note: json['note']?.toString().trim().isNotEmpty == true
          ? json['note'].toString().trim()
          : '維持既有節奏即可。',
    );
  }
}

class AllocationChangeItem {
  const AllocationChangeItem({
    required this.label,
    required this.previousWeight,
    required this.currentWeight,
    required this.targetWeight,
  });

  final String label;
  final double previousWeight;
  final double currentWeight;
  final double targetWeight;

  double get changeFromLastMonth => currentWeight - previousWeight;
  double get driftToTarget => currentWeight - targetWeight;

  String get currentWeightLabel =>
      '${(currentWeight * 100).toStringAsFixed(0)}%';
  String get targetWeightLabel => '${(targetWeight * 100).toStringAsFixed(0)}%';
  String get changeLabel {
    final points = changeFromLastMonth * 100;
    final prefix = points >= 0 ? '+' : '';
    return '$prefix${points.toStringAsFixed(1)}pp';
  }

  String get driftLabel {
    final points = driftToTarget * 100;
    if (points.abs() < 0.05) {
      return '貼近目標';
    }
    final prefix = points > 0 ? '高於目標 ' : '低於目標 ';
    return '$prefix${points.abs().toStringAsFixed(1)}pp';
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'previousWeight': previousWeight,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
    };
  }

  factory AllocationChangeItem.fromJson(Map<String, dynamic> json) {
    return AllocationChangeItem(
      label: json['label']?.toString().trim().isNotEmpty == true
          ? json['label'].toString().trim()
          : '未分類',
      previousWeight:
          _toDouble(json['previousWeight']) ??
          _toDouble(json['previous_weight']) ??
          0,
      currentWeight:
          _toDouble(json['currentWeight']) ??
          _toDouble(json['current_weight']) ??
          0,
      targetWeight:
          _toDouble(json['targetWeight']) ??
          _toDouble(json['target_weight']) ??
          0,
    );
  }
}

MonthKey? _parseMonthKey(Object? raw) {
  if (raw is MonthKey) {
    return raw;
  }

  if (raw is Map) {
    final year = _toInt(raw['year']);
    final month = _toInt(raw['month']);
    if (year != null && month != null && month >= 1 && month <= 12) {
      return MonthKey(year, month);
    }
  }

  final value = raw?.toString().trim();
  if (value == null || value.isEmpty) {
    return null;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return MonthKey(parsed.year, parsed.month);
  }

  final matcher = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(value);
  if (matcher == null) {
    return null;
  }
  final year = int.tryParse(matcher.group(1)!);
  final month = int.tryParse(matcher.group(2)!);
  if (year == null || month == null || month < 1 || month > 12) {
    return null;
  }
  return MonthKey(year, month);
}

List<BudgetRecapItem> _parseBudgetHighlights(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  final items = <BudgetRecapItem>[];
  for (final item in raw) {
    if (item is Map) {
      items.add(BudgetRecapItem.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  return List<BudgetRecapItem>.unmodifiable(items);
}

List<AllocationChangeItem> _parseAllocationChanges(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  final items = <AllocationChangeItem>[];
  for (final item in raw) {
    if (item is Map) {
      items.add(AllocationChangeItem.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  return List<AllocationChangeItem>.unmodifiable(items);
}

List<StressTestScenario> _parseStressTests(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  final items = <StressTestScenario>[];
  for (final item in raw) {
    if (item is Map) {
      items.add(StressTestScenario.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  return List<StressTestScenario>.unmodifiable(items);
}

List<String> _parseStringList(Object? raw) {
  if (raw is List) {
    return raw
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }
  if (raw is String) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

String _stableContextHash(MonthlyInsight insight) {
  final payload = [
    '${insight.month.year}-${insight.month.month.toString().padLeft(2, '0')}',
    insight.netWorthCurrent.toString(),
    insight.netWorthDelta.toString(),
    insight.savingsRate.toStringAsFixed(6),
    insight.savingsRateTarget.toStringAsFixed(6),
    insight.budgetCompletion.toStringAsFixed(6),
    insight.quantMetrics.returnRate.toStringAsFixed(6),
    insight.quantMetrics.volatility.toStringAsFixed(6),
    insight.quantMetrics.sharpeRatio.toStringAsFixed(6),
    insight.quantMetrics.maxDrawdown.toStringAsFixed(6),
    insight.quantMetrics.benchmarkReturnRate.toStringAsFixed(6),
    insight.quantMetrics.benchmarkExcessReturn.toStringAsFixed(6),
  ].join('|');
  return _fnv1a64Hex(payload);
}

String _fnv1a64Hex(String input) {
  const offset = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  var hash = offset;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * prime) & 0xffffffffffffffff;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

int? _toInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString().trim());
}

double? _toDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString().trim());
}

num? _toNum(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value;
  }
  return num.tryParse(value.toString().trim());
}
