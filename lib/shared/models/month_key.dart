class MonthKey {
  const MonthKey(this.year, this.month) : assert(month >= 1 && month <= 12);

  factory MonthKey.fromDate(DateTime date) {
    return MonthKey(date.year, date.month);
  }

  final int year;
  final int month;

  String get zhLabel => '$year 年 $month 月';

  @override
  bool operator ==(Object other) {
    return other is MonthKey && other.year == year && other.month == month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}
