import '../../core/theme/app_colors.dart';
import '../../features/dashboard/models/dashboard_snapshot.dart';
import '../../shared/models/money.dart';
import '../../shared/models/month_key.dart';
import '../../shared/widgets/data_display/allocation_bar.dart';
import '../../shared/widgets/data_display/progress_bar.dart';

final mockDashboardSnapshot = DashboardSnapshot(
  month: const MonthKey(2026, 4),
  savingsRate: 28.4,
  savingsTarget: 30,
  netWorth: const Money.twd(2450000),
  netWorthDelta: const Money.twd(85000),
  netWorthTrend: const [920, 936, 948, 941, 964, 982, 1004, 1018],
  budgetSummary: const [
    BudgetSnapshotItem(
      label: '固定',
      used: 17200,
      limit: 18000,
      tone: ProgressTone.near,
    ),
    BudgetSnapshotItem(
      label: '生活',
      used: 10800,
      limit: 15000,
      tone: ProgressTone.calm,
    ),
    BudgetSnapshotItem(
      label: '彈性',
      used: 4200,
      limit: 7000,
      tone: ProgressTone.calm,
    ),
  ],
  allocationSummary: const [
    AllocationSegment(label: '股票', value: 72, color: AppColors.assetEquity),
    AllocationSegment(label: '債券', value: 23, color: AppColors.assetBond),
    AllocationSegment(label: '現金', value: 5, color: AppColors.assetCash),
  ],
  attentionItems: const [
    AttentionItem(title: '可考慮回看配置', body: '股票部位高於目標約 12%,下次投入新資金時可優先補足其他類別。'),
    AttentionItem(title: '彈性預算接近上限', body: '本月仍有 5 天,剩餘日均可用約 NT\$ 560。'),
  ],
  statementSummary: const Money.twd(28740),
  lastSyncedAt: DateTime(2026, 4, 26, 9, 30),
);
