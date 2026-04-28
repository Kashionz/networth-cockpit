import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/core/theme/app_colors.dart';
import 'package:networth_cockpit/domain/rules/health_rule_engine.dart';
import 'package:networth_cockpit/domain/rules/health_rule_projection.dart';
import 'package:networth_cockpit/features/dashboard/models/dashboard_snapshot.dart';
import 'package:networth_cockpit/features/insights/models/monthly_insight.dart';
import 'package:networth_cockpit/shared/models/money.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';
import 'package:networth_cockpit/shared/widgets/data_display/allocation_bar.dart';
import 'package:networth_cockpit/shared/widgets/data_display/progress_bar.dart';

void main() {
  group('HealthRuleProjection', () {
    test(
      'fromDashboardSnapshot normalizes rates and derives cash/emergency metrics',
      () {
        final input = HealthRuleProjection.fromDashboardSnapshot(
          _dashboardSnapshot(
            savingsRate: 28.4,
            statementAmount: 12000,
            netWorthAmount: 100000,
            allocationSummary: const [
              AllocationSegment(
                label: '股票',
                value: 70,
                color: AppColors.assetEquity,
              ),
              AllocationSegment(
                label: '債券',
                value: 20,
                color: AppColors.assetBond,
              ),
              AllocationSegment(
                label: '現金',
                value: 10,
                color: AppColors.assetCash,
              ),
            ],
            budgetSummary: const [
              BudgetSnapshotItem(
                label: '固定',
                used: 5000,
                limit: 5000,
                tone: ProgressTone.calm,
              ),
            ],
          ),
        );

        expect(input.cardPaymentDueAmount, 12000);
        expect(input.availableCashAmount, 10000);
        expect(input.emergencyFundMonths, closeTo(2.0, 0.0001));
        expect(input.savingsRate, closeTo(0.284, 0.0001));
        expect(input.allocationDriftRate, closeTo(0.1, 0.0001));
      },
    );

    test('dashboard evaluation returns card-payment-due rule first', () {
      final result = HealthRuleProjection.evaluateDashboardSnapshot(
        _dashboardSnapshot(
          savingsRate: 25,
          statementAmount: 15000,
          netWorthAmount: 100000,
          allocationSummary: const [
            AllocationSegment(
              label: '股票',
              value: 60,
              color: AppColors.assetEquity,
            ),
            AllocationSegment(
              label: '債券',
              value: 30,
              color: AppColors.assetBond,
            ),
            AllocationSegment(
              label: '現金',
              value: 10,
              color: AppColors.assetCash,
            ),
          ],
          budgetSummary: const [
            BudgetSnapshotItem(
              label: '固定',
              used: 2000,
              limit: 2000,
              tone: ProgressTone.calm,
            ),
          ],
        ),
      );

      expect(result.type, HealthRuleType.cardPaymentDueOverCash);
    });

    test(
      'dashboard evaluation returns emergency-fund rule when months < 3',
      () {
        final result = HealthRuleProjection.evaluateDashboardSnapshot(
          _dashboardSnapshot(
            savingsRate: 25,
            statementAmount: 2000,
            netWorthAmount: 60000,
            allocationSummary: const [
              AllocationSegment(
                label: '股票',
                value: 60,
                color: AppColors.assetEquity,
              ),
              AllocationSegment(
                label: '債券',
                value: 30,
                color: AppColors.assetBond,
              ),
              AllocationSegment(
                label: '現金',
                value: 10,
                color: AppColors.assetCash,
              ),
            ],
            budgetSummary: const [
              BudgetSnapshotItem(
                label: '固定',
                used: 3000,
                limit: 3000,
                tone: ProgressTone.calm,
              ),
            ],
          ),
        );

        expect(result.type, HealthRuleType.emergencyFundMonthsLow);
      },
    );

    test('10% boundaries stay healthy for savings and drift thresholds', () {
      final result = HealthRuleProjection.evaluateDashboardSnapshot(
        _dashboardSnapshot(
          savingsRate: 10,
          statementAmount: 5000,
          netWorthAmount: 300000,
          allocationSummary: const [
            AllocationSegment(
              label: '股票',
              value: 70,
              color: AppColors.assetEquity,
            ),
            AllocationSegment(
              label: '債券',
              value: 20,
              color: AppColors.assetBond,
            ),
            AllocationSegment(
              label: '現金',
              value: 10,
              color: AppColors.assetCash,
            ),
          ],
          budgetSummary: const [
            BudgetSnapshotItem(
              label: '固定',
              used: 10000,
              limit: 10000,
              tone: ProgressTone.calm,
            ),
          ],
        ),
      );

      expect(result.type, HealthRuleType.healthy);
    });

    test('dashboard and monthly projections match for equivalent metrics', () {
      final dashboardResult = HealthRuleProjection.evaluateDashboardSnapshot(
        _dashboardSnapshot(
          savingsRate: 8,
          statementAmount: 2000,
          netWorthAmount: 200000,
          allocationSummary: const [
            AllocationSegment(
              label: '股票',
              value: 60,
              color: AppColors.assetEquity,
            ),
            AllocationSegment(
              label: '債券',
              value: 25,
              color: AppColors.assetBond,
            ),
            AllocationSegment(
              label: '現金',
              value: 15,
              color: AppColors.assetCash,
            ),
          ],
          budgetSummary: const [
            BudgetSnapshotItem(
              label: '固定',
              used: 5000,
              limit: 5000,
              tone: ProgressTone.calm,
            ),
          ],
        ),
      );

      final monthlyResult = HealthRuleProjection.evaluateMonthlyInsight(
        _monthlyInsight(
          savingsRate: 0.08,
          allocationChanges: const [
            AllocationChangeItem(
              label: '股票',
              previousWeight: 0.60,
              currentWeight: 0.60,
              targetWeight: 0.60,
            ),
            AllocationChangeItem(
              label: '債券',
              previousWeight: 0.25,
              currentWeight: 0.25,
              targetWeight: 0.25,
            ),
            AllocationChangeItem(
              label: '現金',
              previousWeight: 0.15,
              currentWeight: 0.15,
              targetWeight: 0.15,
            ),
          ],
        ),
      );

      expect(monthlyResult.type, dashboardResult.type);
      expect(monthlyResult.title, dashboardResult.title);
      expect(monthlyResult.reason, dashboardResult.reason);
    });
  });
}

DashboardSnapshot _dashboardSnapshot({
  required double savingsRate,
  required num statementAmount,
  required num netWorthAmount,
  required List<AllocationSegment> allocationSummary,
  required List<BudgetSnapshotItem> budgetSummary,
}) {
  return DashboardSnapshot(
    month: const MonthKey(2030, 1),
    savingsRate: savingsRate,
    savingsTarget: 30,
    netWorth: Money.twd(netWorthAmount),
    netWorthDelta: const Money.twd(0),
    netWorthTrend: const [1, 2, 3, 4],
    budgetSummary: budgetSummary,
    allocationSummary: allocationSummary,
    attentionItems: const [],
    statementSummary: Money.twd(statementAmount),
    lastSyncedAt: DateTime(2030, 1, 31),
  );
}

MonthlyInsight _monthlyInsight({
  required double savingsRate,
  required List<AllocationChangeItem> allocationChanges,
}) {
  return MonthlyInsight(
    month: const MonthKey(2030, 1),
    netWorthCurrent: 0,
    netWorthDelta: 0,
    savingsRate: savingsRate,
    savingsRateTarget: 0.3,
    budgetCompletion: 0.8,
    budgetHighlights: const [],
    allocationChanges: allocationChanges,
    aiInterpretation: const ['維持節奏即可。'],
    outlook: '維持既有節奏。',
  );
}
