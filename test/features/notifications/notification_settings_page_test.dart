import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/theme/app_colors.dart';
import 'package:networth_cockpit/features/dashboard/controllers/dashboard_controller.dart';
import 'package:networth_cockpit/features/dashboard/models/dashboard_snapshot.dart';
import 'package:networth_cockpit/features/notifications/pages/notification_settings_page.dart';
import 'package:networth_cockpit/shared/models/money.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';
import 'package:networth_cockpit/shared/widgets/data_display/allocation_bar.dart';
import 'package:networth_cockpit/shared/widgets/data_display/progress_bar.dart';

void main() {
  testWidgets('Notification settings shows current L1 conclusion', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardControllerProvider.overrideWithValue(
            _snapshotForCardDueRule,
          ),
        ],
        child: const MaterialApp(home: NotificationSettingsPage()),
      ),
    );

    expect(find.text('目前 L1 提示'), findsOneWidget);
    expect(find.text('現金安排檢視'), findsOneWidget);
    expect(find.text('本期信用卡應繳金額高於可動用現金，可先安排本月資金順序。'), findsOneWidget);
  });
}

final _snapshotForCardDueRule = DashboardSnapshot(
  month: const MonthKey(2030, 1),
  savingsRate: 22,
  savingsTarget: 30,
  netWorth: const Money.twd(100000),
  netWorthDelta: const Money.twd(5000),
  netWorthTrend: const [1, 2, 3, 4],
  budgetSummary: const [
    BudgetSnapshotItem(
      label: '固定',
      used: 2000,
      limit: 3000,
      tone: ProgressTone.calm,
    ),
  ],
  allocationSummary: const [
    AllocationSegment(label: '股票', value: 60, color: AppColors.assetEquity),
    AllocationSegment(label: '債券', value: 30, color: AppColors.assetBond),
    AllocationSegment(label: '現金', value: 10, color: AppColors.assetCash),
  ],
  attentionItems: const [],
  statementSummary: const Money.twd(15000),
  lastSyncedAt: DateTime(2030, 1, 31),
);
