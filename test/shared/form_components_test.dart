import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/shared/widgets/buttons/primary_button.dart';
import 'package:networth_cockpit/shared/widgets/buttons/secondary_button.dart';
import 'package:networth_cockpit/shared/widgets/forms/app_select_field.dart';
import 'package:networth_cockpit/shared/widgets/forms/app_text_field.dart';
import 'package:networth_cockpit/shared/widgets/forms/category_tag.dart';

void main() {
  test('AppTextField rejects controller and initialValue together', () {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    expect(
      () => AppTextField(
        label: '備註',
        controller: controller,
        initialValue: 'Market Weekend',
      ),
      throwsAssertionError,
    );
  });

  testWidgets('AppTextField renders support copy and reports changes', (
    tester,
  ) async {
    String? changedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: AppTextField(
                label: '很長的欄位名稱用來確認在手機窄版畫面中不會造成文字溢出',
                helperText: '輸入交易備註或商家名稱',
                onChanged: (value) => changedValue = value,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Market Weekend');
    await tester.pump();

    expect(find.text('輸入交易備註或商家名稱'), findsOneWidget);
    expect(changedValue, 'Market Weekend');
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppSelectField renders values and reports selection changes', (
    tester,
  ) async {
    String? selectedValue = 'living';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 210,
              child: AppSelectField<String>(
                label: '分類',
                value: selectedValue,
                items: const [
                  AppSelectFieldItem(value: 'living', label: '生活採買與餐飲'),
                  AppSelectFieldItem(value: 'transport', label: '交通通勤與停車費用'),
                ],
                onChanged: (value) => selectedValue = value,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('交通通勤與停車費用').last);
    await tester.pumpAndSettle();

    expect(selectedValue, 'transport');
    expect(tester.takeException(), isNull);
  });

  testWidgets('CategoryTag is tappable, selected, and has a mobile target', (
    tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CategoryTag(
              label: '可重用的交易分類標籤',
              selected: true,
              onTap: () => tapCount += 1,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CategoryTag));
    await tester.pump();

    final size = tester.getSize(find.byType(CategoryTag));
    expect(tapCount, 1);
    expect(size.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'buttons render icons, handle taps, and keep tall touch targets',
    (tester) async {
      var primaryTapCount = 0;
      var secondaryTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      label: '接受所有分類建議並套用到本月現金流列表',
                      icon: Icons.check,
                      onPressed: () => primaryTapCount += 1,
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: '稍後再回來檢查這些分類建議',
                      icon: Icons.schedule,
                      onPressed: () => secondaryTapCount += 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.tap(find.byType(SecondaryButton));
      await tester.pump();

      expect(primaryTapCount, 1);
      expect(secondaryTapCount, 1);
      expect(
        tester.getSize(find.byType(PrimaryButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byType(SecondaryButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
