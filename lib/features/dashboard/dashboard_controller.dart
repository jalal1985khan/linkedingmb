import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_post_repository.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/repositories/post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return MockPostRepository();
});

final dashboardDataProvider = FutureProvider<DashboardData>((ref) {
  return ref.read(postRepositoryProvider).fetchDashboardData();
});
