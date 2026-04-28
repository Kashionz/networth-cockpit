import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/income_stream_repository.dart';
import 'package:networth_cockpit/features/income/models/income_stream.dart';
import 'package:networth_cockpit/features/income/pages/income_page.dart';

void main() {
  testWidgets('renders income list and completes FAB add flow', (tester) async {
    final repository = _InMemoryIncomeRepository(
      seed: [_stream(id: 'salary', name: '薪資', amount: 50000)],
    );
    final container = ProviderContainer(
      overrides: [incomeStreamRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: IncomePage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('收入管理'), findsOneWidget);
    expect(find.text('薪資'), findsOneWidget);
    expect(find.text('新增收入'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, '新增收入'));
    await tester.pumpAndSettle();

    expect(find.text('新增收入來源'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, '例如：薪資、租金收入'),
      '接案收入',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '例如：50000'),
      '12000',
    );

    await tester.tap(find.widgetWithText(FilledButton, '建立收入'));
    await tester.pumpAndSettle();

    expect(find.text('收入管理'), findsOneWidget);
    expect(find.text('接案收入'), findsOneWidget);
    expect(repository.upsertCount, 1);
  });
}

IncomeStream _stream({
  required String id,
  required String name,
  required num amount,
}) {
  final now = DateTime.now().toUtc();
  return IncomeStream(
    id: id,
    userId: 'user-1',
    name: name,
    amount: amount,
    frequency: IncomeFrequency.monthly,
    nextDate: now,
    active: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _InMemoryIncomeRepository implements IncomeStreamRepository {
  _InMemoryIncomeRepository({List<IncomeStream>? seed})
    : _streams = List<IncomeStream>.from(seed ?? const []);

  List<IncomeStream> _streams;
  int upsertCount = 0;

  @override
  Future<List<IncomeStream>> fetchIncomeStreams({String? userId}) async {
    return List<IncomeStream>.unmodifiable(_streams);
  }

  @override
  Future<IncomeStream> upsertIncomeStream(IncomeStream stream) async {
    upsertCount += 1;
    _streams = [
      stream,
      for (final current in _streams)
        if (current.id != stream.id) current,
    ];
    return stream;
  }

  @override
  Future<void> deleteIncomeStream(String id) async {
    _streams = _streams
        .where((stream) => stream.id != id)
        .toList(growable: false);
  }

  @override
  num totalMonthlyIncome() {
    return _streams
        .where((stream) => stream.active)
        .fold<num>(0, (sum, stream) => sum + stream.amount);
  }
}
