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

  bool get netWorthIncreased => netWorthDelta >= 0;

  String get monthLabel => month.zhLabel;

  String get savingsRateLabel => '${(savingsRate * 100).toStringAsFixed(1)}%';

  String get savingsTargetLabel =>
      '${(savingsRateTarget * 100).toStringAsFixed(0)}%';

  String get budgetCompletionLabel =>
      '${(budgetCompletion * 100).toStringAsFixed(0)}%';
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
}
