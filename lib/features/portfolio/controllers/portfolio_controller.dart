import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/portfolio_repository.dart';

final portfolioControllerProvider =
    NotifierProvider<PortfolioController, PortfolioAllocationViewModel>(
      PortfolioController.new,
    );

class PortfolioController extends Notifier<PortfolioAllocationViewModel> {
  late final PortfolioRepository _repository;

  @override
  PortfolioAllocationViewModel build() {
    _repository = ref.read(portfolioRepositoryProvider);
    Future<void>.microtask(reload);
    return _snapshotFromRepository();
  }

  Future<void> reload() async {
    await _repository.refresh();
    if (!ref.mounted) {
      return;
    }
    state = _snapshotFromRepository();
  }

  PortfolioAllocationViewModel _snapshotFromRepository() {
    return PortfolioAllocationViewModel(
      allocations: _repository.getAllocations(),
      topHoldings: _repository.getTopHoldings(limit: 5),
      contributionDirections: _repository.getContributionDirections(),
      topFiveConcentration: _repository.getTopFiveConcentration(),
      largestHoldingConcentration: _repository.getLargestHoldingConcentration(),
    );
  }
}

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
