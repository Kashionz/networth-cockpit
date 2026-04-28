import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/dashboard_repository.dart';
import 'package:networth_cockpit/data/repositories/portfolio_performance_repository.dart';
import 'package:networth_cockpit/shared/models/money.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';
import 'package:networth_cockpit/shared/widgets/data_display/allocation_bar.dart';
import 'package:networth_cockpit/shared/widgets/data_display/progress_bar.dart';

void main() {
  test(
    'fallback timeline exposes assets/liabilities/networth points',
    () async {
      final repository = PortfolioPerformanceRepositoryImpl(
        dashboardRepository: _FakeDashboardRepository(),
        now: () => DateTime(2030, 6, 30),
      );

      final snapshot = await repository.fetchSnapshot();

      expect(snapshot.timeline, hasLength(6));
      expect(snapshot.timeline.last.assets, greaterThan(0));
      expect(snapshot.timeline.last.liabilities, greaterThanOrEqualTo(0));
      expect(snapshot.timeline.last.netWorth, greaterThan(0));
    },
  );

  test('milestones are triggered once only in fallback mode', () async {
    final repository = PortfolioPerformanceRepositoryImpl(
      dashboardRepository: _FakeDashboardRepository(),
      now: () => DateTime(2030, 6, 30),
    );

    final first = await repository.fetchSnapshot();
    final second = await repository.fetchSnapshot();

    expect(first.milestones, isNotEmpty);
    expect(second.milestones.length, first.milestones.length);
    expect(
      second.milestones.map((item) => item.code).toSet(),
      first.milestones.map((item) => item.code).toSet(),
    );
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  DashboardSnapshot get fallbackSnapshot => _snapshot;

  @override
  Future<DashboardSnapshot> fetchSnapshot() async => _snapshot;
}

final _snapshot = DashboardSnapshot(
  month: const MonthKey(2030, 6),
  savingsRate: 28,
  savingsTarget: 30,
  netWorth: const Money.twd(1560000),
  netWorthDelta: const Money.twd(45000),
  netWorthTrend: const [880000, 960000, 1050000, 1200000, 1380000, 1560000],
  budgetSummary: const [
    BudgetSnapshotItem(
      label: '固定',
      used: 25000,
      limit: 30000,
      tone: ProgressTone.calm,
    ),
  ],
  allocationSummary: const [
    AllocationSegment(label: '股票', value: 60, color: Color(0xFF0EA5E9)),
  ],
  attentionItems: const [AttentionItem(title: '測試', body: '測試')],
  statementSummary: const Money.twd(210000),
  lastSyncedAt: DateTime(2030, 6, 30),
);
