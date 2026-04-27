class Percentage {
  const Percentage(this.value);

  final double value;

  String label({int fractionDigits = 1}) {
    return '${value.toStringAsFixed(fractionDigits)}%';
  }

  @override
  bool operator ==(Object other) {
    return other is Percentage && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
