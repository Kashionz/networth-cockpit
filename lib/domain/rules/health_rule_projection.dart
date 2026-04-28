import 'dart:math';

import '../../features/dashboard/models/dashboard_snapshot.dart';
import '../../features/insights/models/monthly_insight.dart';
import 'health_rule_engine.dart';

class HealthRuleProjection {
  const HealthRuleProjection._();

  static const Map<String, double> _defaultAllocationTargets = {
    '股票': 0.6,
    '債券': 0.25,
    '現金': 0.15,
  };

  static HealthRuleInput fromDashboardSnapshot(DashboardSnapshot snapshot) {
    final estimatedCashAmount = _estimateCashAmount(snapshot);
    final monthlyOutflow = _estimateMonthlyOutflow(snapshot);
    final emergencyFundMonths = monthlyOutflow <= 0
        ? 6.0
        : (estimatedCashAmount / monthlyOutflow).toDouble();

    return HealthRuleInput(
      cardPaymentDueAmount: snapshot.statementSummary.amount,
      availableCashAmount: estimatedCashAmount,
      emergencyFundMonths: emergencyFundMonths,
      savingsRate: _normalizeRate(snapshot.savingsRate),
      allocationDriftRate: _dashboardAllocationDriftRate(snapshot),
    );
  }

  static HealthRuleInput fromMonthlyInsight(
    MonthlyInsight insight, {
    num cardPaymentDueAmount = 0,
    num availableCashAmount = 0,
    double emergencyFundMonths = 6,
  }) {
    return HealthRuleInput(
      cardPaymentDueAmount: cardPaymentDueAmount,
      availableCashAmount: availableCashAmount,
      emergencyFundMonths: emergencyFundMonths,
      savingsRate: _normalizeRate(insight.savingsRate),
      allocationDriftRate: _monthlyAllocationDriftRate(insight),
    );
  }

  static HealthRuleResult evaluateDashboardSnapshot(
    DashboardSnapshot snapshot, {
    HealthRuleEngine? engine,
  }) {
    final evaluator = engine ?? HealthRuleEngine();
    return evaluator.evaluate(fromDashboardSnapshot(snapshot));
  }

  static HealthRuleResult evaluateMonthlyInsight(
    MonthlyInsight insight, {
    HealthRuleEngine? engine,
  }) {
    final evaluator = engine ?? HealthRuleEngine();
    return evaluator.evaluate(fromMonthlyInsight(insight));
  }

  static num _estimateCashAmount(DashboardSnapshot snapshot) {
    final cashSegment = snapshot.allocationSummary.where(
      (segment) => segment.label == '現金',
    );
    if (cashSegment.isEmpty) {
      return 0;
    }
    final ratio = _normalizeRate(cashSegment.first.value);
    final netWorthAmount = snapshot.netWorth.amount;
    if (netWorthAmount <= 0) {
      return 0;
    }
    return netWorthAmount * ratio;
  }

  static num _estimateMonthlyOutflow(DashboardSnapshot snapshot) {
    final budgetUsed = snapshot.budgetSummary.fold<num>(
      0,
      (sum, item) => sum + item.used,
    );
    if (budgetUsed > 0) {
      return budgetUsed;
    }
    final budgetLimit = snapshot.budgetSummary.fold<num>(
      0,
      (sum, item) => sum + item.limit,
    );
    if (budgetLimit > 0) {
      return budgetLimit;
    }
    return 0;
  }

  static double _dashboardAllocationDriftRate(DashboardSnapshot snapshot) {
    final currentByLabel = <String, double>{
      for (final target in _defaultAllocationTargets.entries) target.key: 0,
    };

    for (final segment in snapshot.allocationSummary) {
      if (!currentByLabel.containsKey(segment.label)) {
        continue;
      }
      currentByLabel[segment.label] = _normalizeRate(segment.value);
    }

    var maxDrift = 0.0;
    for (final target in _defaultAllocationTargets.entries) {
      final current = currentByLabel[target.key] ?? 0;
      maxDrift = max(maxDrift, (current - target.value).abs());
    }
    return maxDrift;
  }

  static double _monthlyAllocationDriftRate(MonthlyInsight insight) {
    if (insight.allocationChanges.isEmpty) {
      return 0;
    }
    var maxDrift = 0.0;
    for (final change in insight.allocationChanges) {
      maxDrift = max(maxDrift, change.driftToTarget.abs());
    }
    return maxDrift;
  }

  static double _normalizeRate(num value) {
    final raw = value.toDouble();
    if (raw > 1) {
      return (raw / 100).clamp(0, 1).toDouble();
    }
    return raw.clamp(0, 1).toDouble();
  }
}
