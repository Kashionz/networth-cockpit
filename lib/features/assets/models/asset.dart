import '../../../shared/models/money.dart';
import 'asset_type.dart';

class Asset {
  const Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final AssetType type;
  final Money value;
  final DateTime updatedAt;

  Asset copyWith({
    String? id,
    String? name,
    AssetType? type,
    Money? value,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
