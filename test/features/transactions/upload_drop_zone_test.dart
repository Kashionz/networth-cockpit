import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/features/transactions/import/widgets/upload_drop_zone.dart';

void main() {
  Widget buildSubject({
    VoidCallback? onSelectSampleFile,
    String? statusLabel,
    bool isProcessing = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: UploadDropZone(
          onSelectSampleFile: onSelectSampleFile ?? () {},
          statusLabel: statusLabel,
          isProcessing: isProcessing,
        ),
      ),
    );
  }

  testWidgets('shows supported CSV and PDF formats before selection', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    expect(find.textContaining('支援 CSV / PDF'), findsOneWidget);
    expect(find.byIcon(Icons.upload_file_outlined), findsOneWidget);
    expect(find.text('等待選擇檔案'), findsOneWidget);
    expect(find.text('使用範例檔案'), findsOneWidget);
  });

  testWidgets('calls sample file callback from mock trigger', (tester) async {
    var selected = false;

    await tester.pumpWidget(
      buildSubject(onSelectSampleFile: () => selected = true),
    );

    await tester.tap(find.text('使用範例檔案'));
    await tester.pump();

    expect(selected, isTrue);
  });

  testWidgets('shows processing status before parsing', (tester) async {
    await tester.pumpWidget(
      buildSubject(statusLabel: '準備解析', isProcessing: true),
    );

    expect(find.text('準備解析'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
