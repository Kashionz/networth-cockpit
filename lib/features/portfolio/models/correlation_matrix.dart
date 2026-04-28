class CorrelationMatrix {
  const CorrelationMatrix({required this.holdingNames, required this.values});

  const CorrelationMatrix.empty() : holdingNames = const [], values = const [];

  final List<String> holdingNames;
  final List<List<double?>> values;

  bool get isEmpty => holdingNames.isEmpty;

  int get size => holdingNames.length;

  double? valueAt(int row, int column) {
    if (row < 0 || column < 0) {
      return null;
    }
    if (row >= values.length || column >= values[row].length) {
      return null;
    }
    return values[row][column];
  }

  List<HighCorrelationRisk> highCorrelationRisks({double threshold = 0.8}) {
    final risks = <HighCorrelationRisk>[];
    for (var row = 0; row < size; row++) {
      for (var column = row + 1; column < size; column++) {
        final value = valueAt(row, column);
        if (value == null || value < threshold) {
          continue;
        }
        risks.add(
          HighCorrelationRisk(
            leftHoldingName: holdingNames[row],
            rightHoldingName: holdingNames[column],
            coefficient: value,
          ),
        );
      }
    }
    return List<HighCorrelationRisk>.unmodifiable(risks);
  }
}

class HighCorrelationRisk {
  const HighCorrelationRisk({
    required this.leftHoldingName,
    required this.rightHoldingName,
    required this.coefficient,
  });

  final String leftHoldingName;
  final String rightHoldingName;
  final double coefficient;
}
