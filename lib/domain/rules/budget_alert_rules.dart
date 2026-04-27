import 'dart:math';

enum BudgetAlertType {
  none,
  nearingLimit,
  overBudget,
  monthEndAllocationAdjustment,
}

class BudgetAlertInput {
  const BudgetAlertInput({
    required this.totalBudgetAmount,
    required this.usedAmount,
    required this.daysLeftInMonth,
    this.isMonthEnd = false,
  }) : assert(totalBudgetAmount >= 0),
       assert(usedAmount >= 0),
       assert(daysLeftInMonth >= 0);

  final num totalBudgetAmount;
  final num usedAmount;
  final int daysLeftInMonth;
  final bool isMonthEnd;

  double get usageRatio {
    if (totalBudgetAmount <= 0) {
      return 0;
    }
    return usedAmount / totalBudgetAmount;
  }

  num get remainingAmount => totalBudgetAmount - usedAmount;
}

class BudgetAlertResult {
  const BudgetAlertResult({
    required this.type,
    required this.shouldNotify,
    required this.usageRatio,
    required this.remainingAmount,
    required this.daysLeftInMonth,
    this.title,
    this.reason,
  });

  final BudgetAlertType type;
  final bool shouldNotify;
  final double usageRatio;
  final num remainingAmount;
  final int daysLeftInMonth;
  final String? title;
  final String? reason;
}

BudgetAlertResult evaluateBudgetAlert(BudgetAlertInput input) {
  final usageRatio = input.usageRatio;
  final remainingAmount = input.remainingAmount;

  if (usageRatio < 0.8) {
    return BudgetAlertResult(
      type: BudgetAlertType.none,
      shouldNotify: false,
      usageRatio: usageRatio,
      remainingAmount: remainingAmount,
      daysLeftInMonth: input.daysLeftInMonth,
    );
  }

  if (usageRatio < 1.0) {
    final readableRemaining = _formatAmount(max<num>(remainingAmount, 0));
    return BudgetAlertResult(
      type: BudgetAlertType.nearingLimit,
      shouldNotify: true,
      usageRatio: usageRatio,
      remainingAmount: remainingAmount,
      daysLeftInMonth: input.daysLeftInMonth,
      title: '預算使用檢視',
      reason: '還剩 $readableRemaining 元，${input.daysLeftInMonth} 天。',
    );
  }

  if (usageRatio > 1.2 && input.isMonthEnd) {
    return BudgetAlertResult(
      type: BudgetAlertType.monthEndAllocationAdjustment,
      shouldNotify: true,
      usageRatio: usageRatio,
      remainingAmount: remainingAmount,
      daysLeftInMonth: input.daysLeftInMonth,
      title: '月底分配檢視',
      reason: '本月使用已超出較多，月底可回看是否調整下月分配。',
    );
  }

  return BudgetAlertResult(
    type: BudgetAlertType.overBudget,
    shouldNotify: true,
    usageRatio: usageRatio,
    remainingAmount: remainingAmount,
    daysLeftInMonth: input.daysLeftInMonth,
    title: '預算使用檢視',
    reason: '本月使用已達預算上限以上，可先安排剩餘天數的支出順序。',
  );
}

String _formatAmount(num value) {
  final rounded = value.toStringAsFixed(2);
  if (rounded.endsWith('.00')) {
    return value.toStringAsFixed(0);
  }
  if (rounded.endsWith('0')) {
    return value.toStringAsFixed(1);
  }
  return rounded;
}
