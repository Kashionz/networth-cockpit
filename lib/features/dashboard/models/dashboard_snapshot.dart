import '../../../shared/models/money.dart';
import '../../../shared/models/month_key.dart';
import '../../../shared/widgets/data_display/allocation_bar.dart';
import '../../../shared/widgets/data_display/progress_bar.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.month,
    required this.savingsRate,
    required this.savingsTarget,
    required this.netWorth,
    required this.netWorthDelta,
    required this.netWorthTrend,
    required this.budgetSummary,
    required this.allocationSummary,
    required this.attentionItems,
    required this.statementSummary,
    required this.lastSyncedAt,
  });

  final MonthKey month;
  final double savingsRate;
  final double savingsTarget;
  final Money netWorth;
  final Money netWorthDelta;
  final List<num> netWorthTrend;
  final List<BudgetSnapshotItem> budgetSummary;
  final List<AllocationSegment> allocationSummary;
  final List<AttentionItem> attentionItems;
  final Money statementSummary;
  final DateTime lastSyncedAt;

  String get monthLabel => month.zhLabel;
}

class BudgetSnapshotItem {
  const BudgetSnapshotItem({
    required this.label,
    required this.used,
    required this.limit,
    required this.tone,
  });

  final String label;
  final num used;
  final num limit;
  final ProgressTone tone;
}

class AttentionItem {
  const AttentionItem({required this.title, required this.body});

  final String title;
  final String body;
}
