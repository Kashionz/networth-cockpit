import '../../../shared/models/money.dart';
import 'asset_type.dart';

class Asset {
  const Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.quantity,
    required this.costBasis,
    required this.currency,
    required this.market,
    required this.updatedAt,
    this.symbol,
    this.marketQuoteSource,
  });

  final String id;
  final String name;
  final AssetType type;
  final Money value;
  final String? symbol;
  final num quantity;
  final Money costBasis;
  final String currency;
  final String market;
  final DateTime updatedAt;
  final String? marketQuoteSource;

  Asset copyWith({
    String? id,
    String? name,
    AssetType? type,
    Money? value,
    String? symbol,
    num? quantity,
    Money? costBasis,
    String? currency,
    String? market,
    DateTime? updatedAt,
    String? marketQuoteSource,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      costBasis: costBasis ?? this.costBasis,
      currency: currency ?? this.currency,
      market: market ?? this.market,
      updatedAt: updatedAt ?? this.updatedAt,
      marketQuoteSource: marketQuoteSource ?? this.marketQuoteSource,
    );
  }
}
