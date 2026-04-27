import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/models/dashboard_snapshot.dart';
import '../mock/mock_dashboard_data.dart';

export '../../features/dashboard/models/dashboard_snapshot.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => const MockDashboardRepository(),
);

final dashboardSnapshotProvider = Provider<DashboardSnapshot>(
  (ref) => ref.watch(dashboardRepositoryProvider).getSnapshot(),
);

abstract interface class DashboardRepository {
  DashboardSnapshot getSnapshot();
}

class MockDashboardRepository implements DashboardRepository {
  const MockDashboardRepository();

  @override
  DashboardSnapshot getSnapshot() => mockDashboardSnapshot;
}
