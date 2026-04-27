class StatementCycle {
  const StatementCycle({required this.statementDate, required this.dueDate});

  final DateTime statementDate;
  final DateTime dueDate;

  int get statementDay => statementDate.day;
  int get dueDay => dueDate.day;

  factory StatementCycle.fromDays({
    required int statementDay,
    required int dueDay,
    DateTime? referenceDate,
  }) {
    final base = referenceDate ?? DateTime.now();
    final statement = _safeDate(base.year, base.month, statementDay);

    final dueBase = dueDay >= statementDay
        ? DateTime(base.year, base.month)
        : DateTime(base.year, base.month + 1);
    final due = _safeDate(dueBase.year, dueBase.month, dueDay);

    return StatementCycle(statementDate: statement, dueDate: due);
  }

  StatementCycle copyWith({DateTime? statementDate, DateTime? dueDate}) {
    return StatementCycle(
      statementDate: statementDate ?? this.statementDate,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

DateTime _safeDate(int year, int month, int day) {
  final maxDay = DateTime(year, month + 1, 0).day;
  final clampedDay = day.clamp(1, maxDay);
  return DateTime(year, month, clampedDay);
}
