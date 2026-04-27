import '../../../shared/models/money.dart';

class Holding {
  const Holding({
    required this.name,
    required this.marketValue,
    required this.weightRatio,
  });

  final String name;
  final Money marketValue;
  final double weightRatio;

  @override
  bool operator ==(Object other) {
    return other is Holding &&
        other.name == name &&
        other.marketValue == marketValue &&
        other.weightRatio == weightRatio;
  }

  @override
  int get hashCode => Object.hash(name, marketValue, weightRatio);
}
