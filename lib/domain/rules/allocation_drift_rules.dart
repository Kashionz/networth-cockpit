enum AllocationDriftSeverity { prompt, highlight, monthlyReportFlag }

class AllocationDriftInput {
  const AllocationDriftInput({
    required this.category,
    required this.driftRate,
    required this.sustainedDays,
  }) : assert(sustainedDays >= 0);

  final String category;
  final double driftRate;
  final int sustainedDays;
}

class AllocationDriftResult {
  const AllocationDriftResult({
    required this.category,
    required this.driftRate,
    required this.sustainedDays,
    required this.severity,
    required this.title,
    required this.reason,
  });

  final String category;
  final double driftRate;
  final int sustainedDays;
  final AllocationDriftSeverity severity;
  final String title;
  final String reason;

  bool get shouldHighlight =>
      severity == AllocationDriftSeverity.highlight ||
      severity == AllocationDriftSeverity.monthlyReportFlag;

  bool get shouldFlagMonthlyReport =>
      severity == AllocationDriftSeverity.monthlyReportFlag;
}

List<AllocationDriftResult> evaluateAllocationDriftRules(
  List<AllocationDriftInput> inputs,
) {
  final results = <AllocationDriftResult>[];

  for (final input in inputs) {
    final severity = _resolveSeverity(
      driftRate: input.driftRate,
      sustainedDays: input.sustainedDays,
    );
    if (severity == null) {
      continue;
    }
    results.add(
      AllocationDriftResult(
        category: input.category,
        driftRate: input.driftRate,
        sustainedDays: input.sustainedDays,
        severity: severity,
        title: _titleFor(input.category, severity),
        reason: _reasonFor(input, severity),
      ),
    );
  }

  return List<AllocationDriftResult>.unmodifiable(results);
}

AllocationDriftSeverity? _resolveSeverity({
  required double driftRate,
  required int sustainedDays,
}) {
  final absoluteDrift = driftRate.abs();
  if (absoluteDrift > 0.15) {
    return AllocationDriftSeverity.monthlyReportFlag;
  }
  if (absoluteDrift > 0.1) {
    return AllocationDriftSeverity.highlight;
  }
  if (absoluteDrift > 0.05 && sustainedDays >= 7) {
    return AllocationDriftSeverity.prompt;
  }
  return null;
}

String _titleFor(String category, AllocationDriftSeverity severity) {
  return switch (severity) {
    AllocationDriftSeverity.prompt => '$category 配置檢視',
    AllocationDriftSeverity.highlight => '$category 配置高亮檢視',
    AllocationDriftSeverity.monthlyReportFlag => '$category 月報章節檢視',
  };
}

String _reasonFor(
  AllocationDriftInput input,
  AllocationDriftSeverity severity,
) {
  final drift = _toPercentText(input.driftRate.abs());
  return switch (severity) {
    AllocationDriftSeverity.prompt =>
      '${input.category} 類別偏離目標 $drift，已持續 ${input.sustainedDays} 天，可安排類別層級檢視。',
    AllocationDriftSeverity.highlight =>
      '${input.category} 類別偏離目標 $drift，可在本月配置回顧中優先查看。',
    AllocationDriftSeverity.monthlyReportFlag =>
      '${input.category} 類別偏離目標 $drift，可在月報加入該類別專章回顧。',
  };
}

String _toPercentText(double ratio) => '${(ratio * 100).toStringAsFixed(1)}%';
