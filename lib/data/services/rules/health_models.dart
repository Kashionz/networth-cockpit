enum HealthHintLevel { info, watch }

enum HealthRuleSource { edgeFunction, localFallback }

class HealthDashboardMetrics {
  const HealthDashboardMetrics({
    required this.netWorthChangePct,
    required this.savingsRatePct,
    required this.debtToIncomePct,
    required this.liquidityMonths,
  });

  final double netWorthChangePct;
  final double savingsRatePct;
  final double debtToIncomePct;
  final double liquidityMonths;

  Map<String, dynamic> toJson() {
    return {
      'netWorthChangePct': netWorthChangePct,
      'savingsRatePct': savingsRatePct,
      'debtToIncomePct': debtToIncomePct,
      'liquidityMonths': liquidityMonths,
    };
  }
}

class HealthHint {
  const HealthHint({
    required this.id,
    required this.title,
    required this.detail,
    required this.level,
  });

  final String id;
  final String title;
  final String detail;
  final HealthHintLevel level;

  factory HealthHint.fromJson(Map<String, dynamic> json) {
    final rawLevel = json['level']?.toString().toLowerCase();
    final level = rawLevel == 'watch'
        ? HealthHintLevel.watch
        : HealthHintLevel.info;

    return HealthHint(
      id: json['id']?.toString() ?? 'hint-unknown',
      title: json['title']?.toString() ?? '本月提醒',
      detail: json['detail']?.toString() ?? '持續觀察主要指標。',
      level: level,
    );
  }
}

class HealthRuleEvaluation {
  const HealthRuleEvaluation({
    required this.summary,
    required this.hints,
    required this.source,
    required this.usedFallback,
    this.note,
  });

  final String summary;
  final List<HealthHint> hints;
  final HealthRuleSource source;
  final bool usedFallback;
  final String? note;
}
