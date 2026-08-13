import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/business_profile.dart';
import '../../../data/repositories/gmb_analytics_repository.dart';
import '../../../data/repositories/gmb_reviews_repository.dart';

final gmbAnalyticsRepositoryProvider = Provider<GMBAnalyticsRepository>((ref) {
  return GMBAnalyticsRepository();
});

final gmbReviewsRepositoryProvider = Provider<GMBReviewsRepository>((ref) {
  return GMBReviewsRepository();
});

final dashboardStatsProvider =
    FutureProvider.family<GMBLocationStats, String>((ref, locationId) async {
  if (locationId.isEmpty) return const GMBLocationStats();
  final repo = ref.watch(gmbAnalyticsRepositoryProvider);
  return repo.fetchStats(locationId);
});

final postActivityProvider =
    FutureProvider.family<PostActivityStats, String>((ref, locationId) async {
  final repo = ref.watch(gmbAnalyticsRepositoryProvider);
  return repo.fetchPostActivity(locationId: locationId);
});

final dashboardReviewsProvider =
    FutureProvider.family<List<GMBReviewItem>, String>((ref, locationId) async {
  if (locationId.isEmpty) return const [];
  final repo = ref.watch(gmbReviewsRepositoryProvider);
  return repo.fetchReviews(locationId);
});

final profileCompletenessProvider =
    Provider.family<int, BusinessProfile?>((ref, profile) {
  if (profile == null) return 50;

  int score = 0;
  if (profile.name.trim().isNotEmpty) score += 20;
  if (profile.address.trim().isNotEmpty) score += 20;
  if (profile.phone.trim().isNotEmpty) score += 15;
  if (profile.category.trim().isNotEmpty) score += 15;
  if (profile.website.trim().isNotEmpty) score += 15;
  if (profile.hoursSummary.trim().isNotEmpty) score += 15;

  return score.clamp(0, 100);
});
