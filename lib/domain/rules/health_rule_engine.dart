typedef HealthRule = HealthRuleResult? Function(HealthRuleInput input);

enum HealthRuleType {
  cardPaymentDueOverCash,
  emergencyFundMonthsLow,
  savingsRateLow,
  allocationDriftHigh,
  healthy,
}

class HealthRuleInput {
  const HealthRuleInput({
    required this.cardPaymentDueAmount,
    required this.availableCashAmount,
    required this.emergencyFundMonths,
    required this.savingsRate,
    required this.allocationDriftRate,
  });

  final num cardPaymentDueAmount;
  final num availableCashAmount;
  final double emergencyFundMonths;
  final double savingsRate;
  final double allocationDriftRate;

  HealthRuleInput copyWith({
    num? cardPaymentDueAmount,
    num? availableCashAmount,
    double? emergencyFundMonths,
    double? savingsRate,
    double? allocationDriftRate,
  }) {
    return HealthRuleInput(
      cardPaymentDueAmount: cardPaymentDueAmount ?? this.cardPaymentDueAmount,
      availableCashAmount: availableCashAmount ?? this.availableCashAmount,
      emergencyFundMonths: emergencyFundMonths ?? this.emergencyFundMonths,
      savingsRate: savingsRate ?? this.savingsRate,
      allocationDriftRate: allocationDriftRate ?? this.allocationDriftRate,
    );
  }
}

class HealthRuleResult {
  const HealthRuleResult({
    required this.type,
    required this.title,
    required this.reason,
  });

  final HealthRuleType type;
  final String title;
  final String reason;
}

class HealthRuleEngine {
  HealthRuleEngine({List<HealthRule>? rules})
    : _rules = List<HealthRule>.unmodifiable(rules ?? _defaultRules);

  final List<HealthRule> _rules;

  HealthRuleResult evaluate(HealthRuleInput input) {
    for (final rule in _rules) {
      final result = rule(input);
      if (result != null) {
        _assertNeutralCopy(result);
        return result;
      }
    }
    throw StateError('Health rules must include a fallback.');
  }
}

final List<HealthRule> _defaultRules =
    List<HealthRule>.unmodifiable(<HealthRule>[
      _cardPaymentDueRule,
      _emergencyFundRule,
      _savingsRateRule,
      _allocationDriftRule,
      _healthyFallbackRule,
    ]);

const List<String> _restrictedTerms = <String>['警告', '危險', '錯誤'];

const HealthRuleResult _cardPaymentDueResult = HealthRuleResult(
  type: HealthRuleType.cardPaymentDueOverCash,
  title: '現金安排檢視',
  reason: '本期信用卡應繳金額高於可動用現金，可先安排本月資金順序。',
);

const HealthRuleResult _emergencyFundResult = HealthRuleResult(
  type: HealthRuleType.emergencyFundMonthsLow,
  title: '預備金月數檢視',
  reason: '緊急預備金可支撐月數低於 3 個月，可逐步補強現金緩衝。',
);

const HealthRuleResult _savingsRateResult = HealthRuleResult(
  type: HealthRuleType.savingsRateLow,
  title: '儲蓄節奏檢視',
  reason: '本月儲蓄率低於 10%，可回看固定與彈性支出比例。',
);

const HealthRuleResult _allocationDriftResult = HealthRuleResult(
  type: HealthRuleType.allocationDriftHigh,
  title: '配置偏離檢視',
  reason: '目前投資配置偏離目標超過 10%，可安排類別層級回顧。',
);

const HealthRuleResult _healthyResult = HealthRuleResult(
  type: HealthRuleType.healthy,
  title: '整體狀態穩定',
  reason: '目前四項基礎指標皆在預設範圍內，可維持既有節奏。',
);

HealthRuleResult? _cardPaymentDueRule(HealthRuleInput input) {
  if (input.cardPaymentDueAmount > input.availableCashAmount) {
    return _cardPaymentDueResult;
  }
  return null;
}

HealthRuleResult? _emergencyFundRule(HealthRuleInput input) {
  if (input.emergencyFundMonths < 3) {
    return _emergencyFundResult;
  }
  return null;
}

HealthRuleResult? _savingsRateRule(HealthRuleInput input) {
  if (input.savingsRate < 0.1) {
    return _savingsRateResult;
  }
  return null;
}

HealthRuleResult? _allocationDriftRule(HealthRuleInput input) {
  if (input.allocationDriftRate.abs() > 0.1) {
    return _allocationDriftResult;
  }
  return null;
}

HealthRuleResult _healthyFallbackRule(HealthRuleInput input) {
  return _healthyResult;
}

void _assertNeutralCopy(HealthRuleResult result) {
  final copy = '${result.title}${result.reason}';
  for (final term in _restrictedTerms) {
    if (copy.contains(term)) {
      throw StateError('Health rule output must stay neutral: $term');
    }
  }
}
