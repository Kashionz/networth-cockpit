class MarketQuote {
  const MarketQuote({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.source,
    required this.asOf,
  });

  final String symbol;
  final String name;
  final num price;
  final num change;
  final String source;
  final DateTime asOf;

  bool get isRising => change >= 0;

  MarketQuote copyWith({
    String? symbol,
    String? name,
    num? price,
    num? change,
    String? source,
    DateTime? asOf,
  }) {
    return MarketQuote(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      change: change ?? this.change,
      source: source ?? this.source,
      asOf: asOf ?? this.asOf,
    );
  }
}
