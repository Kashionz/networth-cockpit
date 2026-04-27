import '../../features/portfolio/models/asset_allocation.dart';
import '../../features/portfolio/models/contribution_direction.dart';
import '../../features/portfolio/models/holding.dart';
import '../../shared/models/money.dart';

class MockPortfolioData {
  const MockPortfolioData._();

  static const allocations = [
    AssetAllocation(
      category: AssetCategory.equity,
      currentRatio: 72,
      targetRatio: 60,
    ),
    AssetAllocation(
      category: AssetCategory.bond,
      currentRatio: 19,
      targetRatio: 30,
    ),
    AssetAllocation(
      category: AssetCategory.cash,
      currentRatio: 9,
      targetRatio: 10,
    ),
  ];

  static const topHoldings = [
    Holding(
      name: '全球股票市場基金',
      marketValue: Money.twd(620000),
      weightRatio: 19.8,
    ),
    Holding(name: '美國大型股基金', marketValue: Money.twd(410000), weightRatio: 13.1),
    Holding(name: '台灣高股息基金', marketValue: Money.twd(305000), weightRatio: 9.7),
    Holding(name: '投資級債券基金', marketValue: Money.twd(260000), weightRatio: 8.3),
    Holding(name: '短期公債基金', marketValue: Money.twd(210000), weightRatio: 6.7),
  ];

  static const contributionDirections = [
    ContributionDirection(
      category: AssetCategory.equity,
      ratio: 20,
      note: '維持核心股票曝險',
    ),
    ContributionDirection(
      category: AssetCategory.bond,
      ratio: 55,
      note: '優先補足目標差距',
    ),
    ContributionDirection(
      category: AssetCategory.cash,
      ratio: 25,
      note: '保留短期資金彈性',
    ),
  ];

  static const topFiveConcentration = 57.6;
  static const largestHoldingConcentration = 19.8;
}
