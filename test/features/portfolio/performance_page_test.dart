import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/features/portfolio/controllers/performance_controller.dart';
import 'package:networth_cockpit/features/portfolio/models/performance_milestone.dart';
import 'package:networth_cockpit/features/portfolio/models/performance_timeline_point.dart';
import 'package:networth_cockpit/features/portfolio/pages/performance_page.dart';
import 'package:networth_cockpit/shared/widgets/data_display/net_worth_timeline_chart.dart';

void main() {
  testWidgets('performance page shows timeline and milestone history', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioPerformanceControllerProvider.overrideWith(
            () => _TestPerformanceController(_state),
          ),
        ],
        child: const MaterialApp(home: PortfolioPerformancePage()),
      ),
    );

    expect(find.text('配置表現'), findsOneWidget);
    expect(find.text('淨值時間線'), findsOneWidget);
    expect(find.byType(NetWorthTimelineChart), findsOneWidget);
    expect(find.text('里程碑紀錄'), findsOneWidget);
    expect(find.text('淨值達成 NT\$1,000,000'), findsOneWidget);
  });

  testWidgets(
    'performance page shows loading indicator when state is loading',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            portfolioPerformanceControllerProvider.overrideWith(
              () => _TestPerformanceController(
                const PortfolioPerformanceState(
                  timeline: [],
                  milestones: [],
                  isLoading: true,
                  usedFallback: true,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: PortfolioPerformancePage()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );
}

class _TestPerformanceController extends PortfolioPerformanceController {
  _TestPerformanceController(this._state);

  final PortfolioPerformanceState _state;

  @override
  PortfolioPerformanceState build() => _state;
}

final _state = PortfolioPerformanceState(
  timeline: [
    PerformanceTimelinePoint(
      date: DateTime(2030, 1, 1),
      assets: 1200000,
      liabilities: 250000,
      netWorth: 950000,
    ),
    PerformanceTimelinePoint(
      date: DateTime(2030, 2, 1),
      assets: 1280000,
      liabilities: 220000,
      netWorth: 1060000,
    ),
  ],
  milestones: [
    PerformanceMilestone(
      code: 'networth_1m',
      title: '淨值達成 NT\$1,000,000',
      description: '達到第一個百萬淨值里程碑，繼續維持紀律投入。',
      achievedAt: DateTime(2030, 2, 1),
      netWorth: 1060000,
    ),
  ],
  isLoading: false,
  usedFallback: false,
);
