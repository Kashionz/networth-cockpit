import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/dashboard_repository.dart';

final dashboardControllerProvider = Provider<DashboardSnapshot>(
  (ref) => ref.watch(dashboardSnapshotProvider),
);
