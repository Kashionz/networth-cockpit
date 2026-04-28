import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/portfolio_performance_repository.dart';
import '../models/performance_milestone.dart';
import '../models/performance_timeline_point.dart';

final portfolioPerformanceControllerProvider =
    NotifierProvider<PortfolioPerformanceController, PortfolioPerformanceState>(
      PortfolioPerformanceController.new,
    );

class PortfolioPerformanceState {
  const PortfolioPerformanceState({
    required this.timeline,
    required this.milestones,
    required this.isLoading,
    required this.usedFallback,
    this.errorMessage,
  });

  factory PortfolioPerformanceState.initial() {
    return const PortfolioPerformanceState(
      timeline: [],
      milestones: [],
      isLoading: true,
      usedFallback: true,
    );
  }

  final List<PerformanceTimelinePoint> timeline;
  final List<PerformanceMilestone> milestones;
  final bool isLoading;
  final bool usedFallback;
  final String? errorMessage;

  PortfolioPerformanceState copyWith({
    List<PerformanceTimelinePoint>? timeline,
    List<PerformanceMilestone>? milestones,
    bool? isLoading,
    bool? usedFallback,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PortfolioPerformanceState(
      timeline: timeline ?? this.timeline,
      milestones: milestones ?? this.milestones,
      isLoading: isLoading ?? this.isLoading,
      usedFallback: usedFallback ?? this.usedFallback,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PortfolioPerformanceController
    extends Notifier<PortfolioPerformanceState> {
  late final PortfolioPerformanceRepository _repository;

  @override
  PortfolioPerformanceState build() {
    _repository = ref.read(portfolioPerformanceRepositoryProvider);
    Future<void>.microtask(reload);
    return PortfolioPerformanceState.initial();
  }

  Future<void> reload() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _repository.fetchSnapshot();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        timeline: snapshot.timeline,
        milestones: snapshot.milestones,
        usedFallback: snapshot.usedFallback,
        isLoading: false,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, errorMessage: '載入配置表現失敗，請稍後再試。');
    }
  }
}
