import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/api_post_repository.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/repositories/post_repository.dart';
import '../business_flow/providers/active_location_provider.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return ApiPostRepository();
});

final dashboardDataProvider = FutureProvider<DashboardData>((ref) {
  final activeLoc = ref.watch(activeLocationProvider).activeLocation;
  return ref.read(postRepositoryProvider).fetchDashboardData(locationId: activeLoc?.id);
});

