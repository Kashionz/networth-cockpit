import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/shared/widgets/data_display/trend_sparkline.dart';

void main() {
  testWidgets('TrendSparkline paints when data points are provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrendSparkline(points: [100, 108, 104, 116, 122, 128]),
        ),
      ),
    );

    expect(find.byType(TrendSparkline), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TrendSparkline),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(find.text('暫無趨勢資料'), findsNothing);
  });

  testWidgets('TrendSparkline shows neutral empty state without data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TrendSparkline(points: [])),
      ),
    );

    expect(find.text('暫無趨勢資料'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TrendSparkline),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  testWidgets('TrendSparkline renders a centered accent mark for one point', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 120, child: TrendSparkline(points: [100])),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(TrendSparkline),
        matching: find.byType(CustomPaint),
      ),
      paints
        ..save()
        ..circle(x: 60, y: 28, radius: 3),
    );
  });
}
