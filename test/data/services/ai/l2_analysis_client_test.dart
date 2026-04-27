import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:networth_cockpit/data/services/ai/l2_analysis_client.dart';
import 'package:networth_cockpit/features/insights/models/monthly_insight.dart';
import 'package:networth_cockpit/shared/models/month_key.dart';

void main() {
  test(
    'analyzeMonthly sends FastAPI contract fields and parses backend response',
    () async {
      String? capturedBody;

      final client = L2AnalysisClient(
        baseUrl: 'https://example.com',
        httpClient: MockClient((request) async {
          capturedBody = request.body;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'recommendations': ['減少外食支出', '提高固定儲蓄額'],
                'llm_insight': '本月現金流與預算執行維持穩定。',
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final result = await client.analyzeMonthly(seedInsight: _seedInsight);

      expect(result.usedFallback, isFalse);
      expect(result.source, L2ResultSource.backend);
      expect(result.insight.aiInterpretation.first, '本月現金流與預算執行維持穩定。');
      expect(result.insight.aiInterpretation, contains('減少外食支出'));
      expect(result.insight.outlook, '減少外食支出');

      final capturedPayload = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(capturedPayload, isNotNull);
      expect(capturedPayload['month'], '2026-04');
      expect(capturedPayload['income'], isA<num>());
      expect(capturedPayload['expense'], isA<num>());
      expect(capturedPayload['top_categories'], isA<List>());
      expect(capturedPayload['notes'], isA<String>());
    },
  );
}

const _seedInsight = MonthlyInsight(
  month: MonthKey(2026, 4),
  netWorthCurrent: 1462000,
  netWorthDelta: 42000,
  savingsRate: 0.284,
  savingsRateTarget: 0.3,
  budgetCompletion: 0.9,
  budgetHighlights: [
    BudgetRecapItem(label: '固定', completion: 0.94, note: '維持原本節奏即可'),
    BudgetRecapItem(label: '生活', completion: 0.87, note: '可延續目前分配'),
    BudgetRecapItem(label: '彈性', completion: 0.96, note: '下月可預留一點餘裕'),
  ],
  allocationChanges: [
    AllocationChangeItem(
      label: '股票',
      previousWeight: 0.58,
      currentWeight: 0.6,
      targetWeight: 0.6,
    ),
  ],
  aiInterpretation: ['seed'],
  outlook: '可考慮在下月維持既有定投與預算配置。',
);
