class PerformanceTimelinePoint {
  const PerformanceTimelinePoint({
    required this.date,
    required this.assets,
    required this.liabilities,
    required this.netWorth,
  });

  final DateTime date;
  final double assets;
  final double liabilities;
  final double netWorth;
}
