import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/portfolio/models/asset_allocation.dart';
import '../../features/portfolio/models/contribution_direction.dart';
import '../../features/portfolio/models/holding.dart';
import '../mock/mock_portfolio_data.dart';

export '../../features/portfolio/models/asset_allocation.dart';
export '../../features/portfolio/models/contribution_direction.dart';
export '../../features/portfolio/models/holding.dart';

final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => const MockPortfolioRepository(),
);

abstract interface class PortfolioRepository {
  List<AssetAllocation> getAllocations();

  List<Holding> getTopHoldings({int limit = 5});

  List<ContributionDirection> getContributionDirections();

  double getTopFiveConcentration();

  double getLargestHoldingConcentration();
}

class MockPortfolioRepository implements PortfolioRepository {
  const MockPortfolioRepository();

  @override
  List<AssetAllocation> getAllocations() => MockPortfolioData.allocations;

  @override
  List<Holding> getTopHoldings({int limit = 5}) {
    return MockPortfolioData.topHoldings.take(limit).toList(growable: false);
  }

  @override
  List<ContributionDirection> getContributionDirections() {
    return MockPortfolioData.contributionDirections;
  }

  @override
  double getTopFiveConcentration() => MockPortfolioData.topFiveConcentration;

  @override
  double getLargestHoldingConcentration() {
    return MockPortfolioData.largestHoldingConcentration;
  }
}
