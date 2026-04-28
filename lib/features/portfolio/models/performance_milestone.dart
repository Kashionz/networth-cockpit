class PerformanceMilestone {
  const PerformanceMilestone({
    required this.code,
    required this.title,
    required this.description,
    required this.achievedAt,
    required this.netWorth,
  });

  final String code;
  final String title;
  final String description;
  final DateTime achievedAt;
  final double netWorth;
}
