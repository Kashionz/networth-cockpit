import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/portfolio_repository.dart';

final portfolioControllerProvider = Provider<PortfolioAllocationViewModel>((
  ref,
) {
  final repository = ref.watch(portfolioRepositoryProvider);
  final allocations = repository.getAllocations();
  final topHoldings = repository.getTopHoldings(limit: 5);

  return PortfolioAllocationViewModel(
    allocations: allocations,
    topHoldings: topHoldings,
    contributionDirections: repository.getContributionDirections(),
    topFiveConcentration: repository.getTopFiveConcentration(),
    largestHoldingConcentration: repository.getLargestHoldingConcentration(),
  );
});

class PortfolioAllocationViewModel {
  const PortfolioAllocationViewModel({
    required this.allocations,
    required this.topHoldings,
    required this.contributionDirections,
    required this.topFiveConcentration,
    required this.largestHoldingConcentration,
  });

  final List<AssetAllocation> allocations;
  final List<Holding> topHoldings;
  final List<ContributionDirection> contributionDirections;
  final double topFiveConcentration;
  final double largestHoldingConcentration;

  List<AssetAllocation> get allocationsByDrift {
    final sorted = [...allocations];
    sorted.sort(
      (left, right) => right.driftRatio.abs().compareTo(left.driftRatio.abs()),
    );
    return sorted;
  }
}
