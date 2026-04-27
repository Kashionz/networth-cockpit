import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/dashboard_repository.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';

void main() {
  test('dashboard repository exposes the MVP dashboard snapshot', () {
    final repository = MockDashboardRepository();

    final snapshot = repository.getSnapshot();

    expect(snapshot.month, const MonthKey(2026, 4));
    expect(snapshot.savingsRate, 28.4);
    expect(snapshot.netWorth.amount, 2450000);
    expect(snapshot.netWorthTrend, hasLength(8));
    expect(snapshot.budgetSummary, hasLength(3));
    expect(snapshot.allocationSummary, hasLength(3));
    expect(snapshot.statementSummary.amount, 28740);
    expect(snapshot.lastSyncedAt, isNotNull);
  });
}
