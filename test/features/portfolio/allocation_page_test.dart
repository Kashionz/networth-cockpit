import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/portfolio_repository.dart';
import 'package:networth_cockpit/features/portfolio/controllers/portfolio_controller.dart';
import 'package:networth_cockpit/features/portfolio/models/asset_allocation.dart';
import 'package:networth_cockpit/features/portfolio/models/contribution_direction.dart';
import 'package:networth_cockpit/features/portfolio/models/holding.dart';
import 'package:networth_cockpit/features/portfolio/pages/allocation_page.dart';
import 'package:networth_cockpit/shared/models/money.dart';

void main() {
  Future<void> pumpAllocationPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AllocationPage())),
      ),
    );
  }

  testWidgets('Allocation page shows required sections and disclaimer', (
    tester,
  ) async {
    await pumpAllocationPage(tester);

    expect(find.text('投資配置'), findsOneWidget);
    expect(find.text('現況 vs 目標'), findsOneWidget);
    expect(find.text('偏離度'), findsOneWidget);
    expect(find.text('Top 5 持股'), findsOneWidget);
    expect(find.text('補倉方向'), findsOneWidget);
    expect(find.text('集中度說明'), findsOneWidget);
    expect(find.textContaining('本資訊僅供參考,不構成投資建議'), findsOneWidget);

    expect(find.text('股票'), findsWidgets);
    expect(find.text('債券'), findsWidgets);
    expect(find.text('現金'), findsWidgets);
  });

  testWidgets('Allocation page reads ratio and drift values from controller', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioRepositoryProvider.overrideWithValue(
            _FakePortfolioRepository(snapshot: _fakePortfolioSnapshot),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AllocationPage())),
      ),
    );

    expect(find.text('50.0% / 40.0%'), findsOneWidget);
    expect(find.text('35.0% / 45.0%'), findsOneWidget);
    expect(find.text('15.0% / 15.0%'), findsOneWidget);
    expect(find.text('+10.0%'), findsOneWidget);
    expect(find.text('-10.0%'), findsOneWidget);
    expect(find.textContaining('45.0%'), findsWidgets);
    expect(find.textContaining('測試持股 A'), findsOneWidget);
  });

  testWidgets('Contribution guidance remains category-level and neutral', (
    tester,
  ) async {
    await pumpAllocationPage(tester);

    expect(find.textContaining('僅提供類別比例參考'), findsOneWidget);
    expect(find.textContaining('買進'), findsNothing);
    expect(find.textContaining('賣出'), findsNothing);
    expect(find.textContaining('0050'), findsNothing);
  });
}

class _FakePortfolioRepository implements PortfolioRepository {
  const _FakePortfolioRepository({required this.snapshot});

  final PortfolioAllocationViewModel snapshot;

  @override
  Future<void> refresh() async {}

  @override
  List<AssetAllocation> getAllocations() => snapshot.allocations;

  @override
  List<ContributionDirection> getContributionDirections() {
    return snapshot.contributionDirections;
  }

  @override
  double getLargestHoldingConcentration() {
    return snapshot.largestHoldingConcentration;
  }

  @override
  double getTopFiveConcentration() => snapshot.topFiveConcentration;

  @override
  List<Holding> getTopHoldings({int limit = 5}) {
    return snapshot.topHoldings.take(limit).toList(growable: false);
  }
}

const _fakePortfolioSnapshot = PortfolioAllocationViewModel(
  allocations: [
    AssetAllocation(
      category: AssetCategory.equity,
      currentRatio: 50,
      targetRatio: 40,
    ),
    AssetAllocation(
      category: AssetCategory.bond,
      currentRatio: 35,
      targetRatio: 45,
    ),
    AssetAllocation(
      category: AssetCategory.cash,
      currentRatio: 15,
      targetRatio: 15,
    ),
  ],
  topHoldings: [
    Holding(name: '測試持股 A', marketValue: Money.twd(200000), weightRatio: 12),
    Holding(name: '測試持股 B', marketValue: Money.twd(180000), weightRatio: 11),
    Holding(name: '測試持股 C', marketValue: Money.twd(160000), weightRatio: 10),
    Holding(name: '測試持股 D', marketValue: Money.twd(140000), weightRatio: 8),
    Holding(name: '測試持股 E', marketValue: Money.twd(120000), weightRatio: 4),
  ],
  contributionDirections: [
    ContributionDirection(category: AssetCategory.equity, ratio: 30),
    ContributionDirection(category: AssetCategory.bond, ratio: 50),
    ContributionDirection(category: AssetCategory.cash, ratio: 20),
  ],
  topFiveConcentration: 45,
  largestHoldingConcentration: 12,
);
