import 'asset_allocation.dart';

class ContributionDirection {
  const ContributionDirection({
    required this.category,
    required this.ratio,
    this.note,
  });

  final AssetCategory category;
  final double ratio;
  final String? note;

  @override
  bool operator ==(Object other) {
    return other is ContributionDirection &&
        other.category == category &&
        other.ratio == ratio &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(category, ratio, note);
}
