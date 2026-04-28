enum IncomeFrequency {
  monthly,
  yearly,
  oneTime;

  String get value => switch (this) {
    IncomeFrequency.monthly => 'monthly',
    IncomeFrequency.yearly => 'yearly',
    IncomeFrequency.oneTime => 'one_time',
  };

  String get label => switch (this) {
    IncomeFrequency.monthly => '每月',
    IncomeFrequency.yearly => '每年',
    IncomeFrequency.oneTime => '一次性',
  };

  static IncomeFrequency fromRaw(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'yearly' => IncomeFrequency.yearly,
      'one_time' => IncomeFrequency.oneTime,
      _ => IncomeFrequency.monthly,
    };
  }
}

class IncomeStream {
  const IncomeStream({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextDate,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final num amount;
  final IncomeFrequency frequency;
  final DateTime nextDate;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayLabel =>
      '$name · ${frequency.label} \$${_formatAmount(amount)}';

  IncomeStream copyWith({
    String? id,
    String? userId,
    String? name,
    num? amount,
    IncomeFrequency? frequency,
    DateTime? nextDate,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncomeStream(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'frequency': frequency.value,
      'next_date': _toDate(nextDate),
      'active': active,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory IncomeStream.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    final resolvedNextDate = _parseDate(
      json['next_date'] ?? json['nextDate'],
      fallback: now,
    );
    final resolvedCreatedAt = _parseDateTime(
      json['created_at'] ?? json['createdAt'],
      fallback: now,
    );
    final resolvedUpdatedAt = _parseDateTime(
      json['updated_at'] ?? json['updatedAt'],
      fallback: resolvedCreatedAt,
    );

    return IncomeStream(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '未命名收入',
      amount: _toNum(json['amount']) ?? 0,
      frequency: IncomeFrequency.fromRaw(json['frequency']?.toString()),
      nextDate: resolvedNextDate,
      active: _toBool(json['active']) ?? true,
      createdAt: resolvedCreatedAt,
      updatedAt: resolvedUpdatedAt,
    );
  }

  static DateTime _parseDate(Object? raw, {required DateTime fallback}) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return DateTime.utc(fallback.year, fallback.month, fallback.day);
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return DateTime.utc(fallback.year, fallback.month, fallback.day);
    }
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  static DateTime _parseDateTime(Object? raw, {required DateTime fallback}) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return fallback.toUtc();
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return fallback.toUtc();
    }
    return parsed.toUtc();
  }

  static String _toDate(DateTime value) {
    final utc = DateTime.utc(value.year, value.month, value.day);
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static num? _toNum(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString());
  }

  static bool? _toBool(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return null;
  }
}

String _formatAmount(num value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
