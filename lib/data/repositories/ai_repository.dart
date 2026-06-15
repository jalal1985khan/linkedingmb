import '../models/ai_recommendation.dart';
import '../models/business_profile.dart';

abstract class AiRepository {
  Future<void> analyzeBusiness(BusinessProfile profile);
  Future<List<AiRecommendation>> getRecommendations(String businessId);
  Future<void> applyRecommendations({
    required String businessId,
    required bool autoApply,
    required List<String> recommendationIds,
  });
}
