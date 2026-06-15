import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_ai_repository.dart';
import '../../data/models/ai_recommendation.dart';
import '../../data/models/business_profile.dart';
import '../../data/repositories/backend_business_repository.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/business_repository.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BackendBusinessRepository();
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return MockAiRepository();
});

class SelectedBusinessController extends StateNotifier<BusinessProfile?> {
  SelectedBusinessController() : super(null);

  void setBusiness(BusinessProfile business) {
    state = business;
  }

  void clear() {
    state = null;
  }
}

final selectedBusinessProvider =
    StateNotifierProvider<SelectedBusinessController, BusinessProfile?>(
  (ref) => SelectedBusinessController(),
);

final associatedBusinessesProvider =
    FutureProvider.family<List<BusinessProfile>, String>((ref, userId) {
  return ref.read(businessRepositoryProvider).getAssociatedBusinesses(userId);
});

final aiRecommendationsProvider =
    FutureProvider.family<List<AiRecommendation>, String>((ref, businessId) {
  return ref.read(aiRepositoryProvider).getRecommendations(businessId);
});
