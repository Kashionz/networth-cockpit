import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/monthly_report_repository.dart';
import '../../../shared/models/month_key.dart';
import '../models/monthly_insight.dart';

final insightsControllerProvider =
    NotifierProvider<InsightsController, InsightsState>(InsightsController.new);

class InsightsController extends Notifier<InsightsState> {
  @override
  InsightsState build() {
    final repository = ref.watch(monthlyReportRepositoryProvider);
    final fallbackReports = repository.fallbackReports;
    final currentMonth = MonthKey.fromDate(DateTime.now());
    final selectedMonth = _resolveSelectedMonth(
      reports: fallbackReports,
      preferredMonth: currentMonth,
    );
    unawaited(refresh(preferredMonth: currentMonth));
    return InsightsState(
      reports: fallbackReports,
      selectedMonth: selectedMonth,
    );
  }

  Future<void> refresh({MonthKey? preferredMonth}) async {
    final targetMonth = preferredMonth ?? MonthKey.fromDate(DateTime.now());
    final reports = await ref
        .read(monthlyReportRepositoryProvider)
        .fetchReports(ensureCurrentMonth: true);
    if (!ref.mounted || reports.isEmpty) {
      return;
    }

    state = state.copyWith(
      reports: reports,
      selectedMonth: _resolveSelectedMonth(
        reports: reports,
        preferredMonth: targetMonth,
      ),
    );
  }

  void selectMonth(MonthKey month) {
    final exists = state.reports.any((report) => report.month == month);
    if (!exists) {
      return;
    }
    state = state.copyWith(selectedMonth: month);
  }

  MonthKey _resolveSelectedMonth({
    required List<MonthlyReportRecord> reports,
    required MonthKey preferredMonth,
  }) {
    for (final report in reports) {
      if (report.month == preferredMonth) {
        return preferredMonth;
      }
    }
    return reports.first.month;
  }
}

class InsightsState {
  const InsightsState({required this.reports, required this.selectedMonth});

  final List<MonthlyReportRecord> reports;
  final MonthKey selectedMonth;

  List<MonthKey> get availableMonths => [
    for (final report in reports) report.month,
  ];

  MonthlyReportRecord get selectedReport {
    for (final report in reports) {
      if (report.month == selectedMonth) {
        return report;
      }
    }
    return reports.first;
  }

  MonthlyInsight get displayInsight => selectedReport.insight;
  bool get usedFallback => selectedReport.usedFallback;
  String get sourceLabel => usedFallback ? '本地 fallback' : 'FastAPI 後端分析';
  String get statusMessage => selectedReport.statusMessage;

  InsightsState copyWith({
    List<MonthlyReportRecord>? reports,
    MonthKey? selectedMonth,
  }) {
    return InsightsState(
      reports: reports ?? this.reports,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}
