import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:networth_cockpit/data/repositories/account_lifecycle_repository.dart';
import 'package:networth_cockpit/data/repositories/dashboard_repository.dart';
import 'package:networth_cockpit/data/repositories/monthly_report_repository.dart';
import 'package:networth_cockpit/data/services/ai/l2_analysis_client.dart';
import 'package:networth_cockpit/features/transactions/import/pages/transaction_import_flow_page.dart';

void main() {
  testWidgets('E2E: transaction import flow can finish end-to-end', (
    tester,
  ) async {
    final fallbackL2Client = L2AnalysisClient(
      baseUrl: null,
      httpClient: MockClient((_) async => http.Response('{}', 500)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          l2AnalysisClientProvider.overrideWithValue(fallbackL2Client),
        ],
        child: const MaterialApp(home: TransactionImportFlowPage()),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, '選擇卡片').first);
    await tester.pump();
    await tester.tap(find.text('使用範例檔案'));
    await tester.pump();
    await tester.tap(find.text('開始解析'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('確認分類'));
    await tester.pump();
    await tester.tap(find.text('完成寫入'));
    await tester.pump();

    expect(find.text('完成匯入'), findsOneWidget);
  });

  test(
    'E2E: monthly report fetch ensures current month report exists',
    () async {
      final reportRepository = MonthlyReportRepositoryImpl(
        dashboardRepository: const MockDashboardRepository(),
        l2AnalysisClient: L2AnalysisClient(
          baseUrl: null,
          httpClient: MockClient((_) async => http.Response('{}', 500)),
        ),
        now: () => DateTime.utc(2026, 4, 27),
      );

      final reports = await reportRepository.fetchReports();

      expect(reports, isNotEmpty);
      expect(reports.first.month.year, 2026);
      expect(reports.first.month.month, 4);
      expect(reports.first.statusMessage, isNotEmpty);
    },
  );

  test('E2E: account deletion lifecycle supports request and cancel', () {
    var now = DateTime.utc(2026, 4, 27, 9);
    final lifecycleRepository = AccountLifecycleRepositoryImpl(now: () => now);

    final requested = lifecycleRepository.requestDeletion();
    expect(requested.status, AccountDeletionStatus.pending);

    now = now.add(const Duration(days: 2));
    final cancelled = lifecycleRepository.cancelDeletion();
    expect(cancelled.status, AccountDeletionStatus.cancelled);
    expect(cancelled.events.first.type, AccountLifecycleEventType.cancelled);
  });
}
