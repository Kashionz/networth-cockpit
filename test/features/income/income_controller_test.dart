import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networth_cockpit/data/repositories/income_stream_repository.dart';
import 'package:networth_cockpit/features/income/controllers/income_controller.dart';
import 'package:networth_cockpit/features/income/models/income_stream.dart';

void main() {
  test('build loads seeded streams', () async {
    final repository = _InMemoryIncomeRepository(
      seed: [_stream('salary', 50000)],
    );
    final container = ProviderContainer(
      overrides: [incomeStreamRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final streams = await container.read(incomeControllerProvider.future);

    expect(streams, hasLength(1));
    expect(streams.first.name, 'salary');
    expect(repository.fetchCount, 1);
  });

  test(
    'upsert and delete update AsyncNotifier state with loading transitions',
    () async {
      final repository = _InMemoryIncomeRepository(
        seed: [_stream('salary', 50000)],
      );
      final container = ProviderContainer(
        overrides: [
          incomeStreamRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(incomeControllerProvider.future);
      final controller = container.read(incomeControllerProvider.notifier);

      final transitions = <AsyncValue<List<IncomeStream>>>[];
      final subscription = container.listen<AsyncValue<List<IncomeStream>>>(
        incomeControllerProvider,
        (previous, next) => transitions.add(next),
      );
      addTearDown(subscription.close);

      await controller.upsert(_stream('bonus', 12000, id: 'bonus-id'));

      expect(transitions.any((state) => state.isLoading), isTrue);
      final afterUpsert = container.read(incomeControllerProvider).requireValue;
      expect(afterUpsert.map((stream) => stream.name), contains('bonus'));

      transitions.clear();
      await controller.delete('bonus-id');

      expect(transitions.any((state) => state.isLoading), isTrue);
      final afterDelete = container.read(incomeControllerProvider).requireValue;
      expect(
        afterDelete.map((stream) => stream.id),
        isNot(contains('bonus-id')),
      );
    },
  );
}

IncomeStream _stream(String name, num amount, {String? id}) {
  final now = DateTime.now().toUtc();
  return IncomeStream(
    id: id ?? '$name-id',
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
  int fetchCount = 0;

  @override
  Future<List<IncomeStream>> fetchIncomeStreams({String? userId}) async {
    fetchCount += 1;
    return List<IncomeStream>.unmodifiable(_streams);
  }

  @override
  Future<IncomeStream> upsertIncomeStream(IncomeStream stream) async {
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
