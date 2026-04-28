import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/dashboard_repository.dart';

final dashboardControllerProvider = Provider<DashboardSnapshot>(
  (ref) => ref.watch(_dashboardSnapshotStateProvider),
);

final _dashboardSnapshotStateProvider =
    NotifierProvider<DashboardController, DashboardSnapshot>(
      DashboardController.new,
    );

class DashboardController extends Notifier<DashboardSnapshot> {
  late final DashboardRepository _repository;

  @override
  DashboardSnapshot build() {
    _repository = ref.read(dashboardRepositoryProvider);
    Future<void>.microtask(reload);
    return _repository.fallbackSnapshot;
  }

  Future<void> reload() async {
    final nextSnapshot = await _repository.fetchSnapshot();
    if (!ref.mounted) {
      return;
    }
    state = nextSnapshot;
  }
}
