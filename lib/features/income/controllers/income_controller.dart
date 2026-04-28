import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/income_stream_repository.dart';
import '../models/income_stream.dart';

final incomeControllerProvider =
    AsyncNotifierProvider<IncomeController, List<IncomeStream>>(
      IncomeController.new,
    );

class IncomeController extends AsyncNotifier<List<IncomeStream>> {
  late final IncomeStreamRepository _repository;

  @override
  Future<List<IncomeStream>> build() async {
    _repository = ref.read(incomeStreamRepositoryProvider);
    return _repository.fetchIncomeStreams();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.fetchIncomeStreams());
  }

  Future<void> save(IncomeStream stream) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.upsertIncomeStream(stream);
      return _repository.fetchIncomeStreams();
    });
  }

  Future<void> upsert(IncomeStream stream) => save(stream);

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteIncomeStream(id);
      return _repository.fetchIncomeStreams();
    });
  }
}
