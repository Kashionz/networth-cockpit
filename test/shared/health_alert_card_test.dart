import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/shared/widgets/feedback/health_alert_card.dart';

void main() {
  testWidgets('renders every health alert tone', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: const [
              HealthAlertCard(
                tone: HealthAlertTone.structural,
                title: '結構檢視',
                body: '固定支出占比可安排回看。',
              ),
              HealthAlertCard(
                tone: HealthAlertTone.review,
                title: '預算回看',
                body: '彈性支出接近本月設定。',
              ),
              HealthAlertCard(
                tone: HealthAlertTone.educational,
                title: '概念補充',
                body: '可了解資產配置的基本概念。',
              ),
              HealthAlertCard(
                tone: HealthAlertTone.info,
                title: '資料同步',
                body: '最近資料已完成更新。',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('結構檢視'), findsOneWidget);
    expect(find.text('預算回看'), findsOneWidget);
    expect(find.text('概念補充'), findsOneWidget);
    expect(find.text('資料同步'), findsOneWidget);
  });

  testWidgets('does not show action labels without callbacks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HealthAlertCard(
            tone: HealthAlertTone.review,
            title: '本月檢視',
            body: '可以安排稍後回看分類。',
            primaryActionLabel: '調整',
            secondaryActionLabel: '稍後',
          ),
        ),
      ),
    );

    expect(find.text('調整'), findsNothing);
    expect(find.text('稍後'), findsNothing);
  });

  testWidgets('shows neutral CTA labels with callbacks and handles taps', (
    tester,
  ) async {
    var primaryTapCount = 0;
    var secondaryTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HealthAlertCard(
            tone: HealthAlertTone.review,
            title: '本月檢視',
            body: '可以安排稍後回看分類。',
            primaryActionLabel: '調整',
            secondaryActionLabel: '稍後',
            onPrimaryAction: () => primaryTapCount += 1,
            onSecondaryAction: () => secondaryTapCount += 1,
          ),
        ),
      ),
    );

    expect(find.text('調整'), findsOneWidget);
    expect(find.text('稍後'), findsOneWidget);

    await tester.tap(find.text('調整'));
    await tester.tap(find.text('稍後'));

    expect(primaryTapCount, 1);
    expect(secondaryTapCount, 1);
  });

  testWidgets('avoids warning icon and exclamation copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HealthAlertCard(
            tone: HealthAlertTone.info,
            title: '資料檢視',
            body: '這是一則中性的狀態提示。',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.warning), findsNothing);
    expect(find.byIcon(Icons.warning_amber), findsNothing);
    expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);

    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    for (final textWidget in textWidgets) {
      expect(textWidget.data ?? '', isNot(contains('!')));
      expect(textWidget.data ?? '', isNot(contains('！')));
    }
  });
}
