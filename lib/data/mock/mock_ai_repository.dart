import '../models/ai_recommendation.dart';
import '../models/business_profile.dart';
import '../repositories/ai_repository.dart';

class MockAiRepository implements AiRepository {
  @override
  Future<void> analyzeBusiness(BusinessProfile profile) async {
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  @override
  Future<List<AiRecommendation>> getRecommendations(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const [
      AiRecommendation(
        id: 'r_001',
        title: 'Optimize profile keywords',
        description: 'Add local intent keywords in your profile description and FAQs.',
        impact: 'High',
      ),
      AiRecommendation(
        id: 'r_002',
        title: 'Post 4 times weekly',
        description: 'Maintain a consistent cadence with offer, event, and update posts.',
        impact: 'Medium',
      ),
      AiRecommendation(
        id: 'r_003',
        title: 'Add CTA to every post',
        description: 'Include "Call now", "Book", or "Visit website" for better conversion.',
        impact: 'High',
      ),
    ];
  }

  @override
  Future<void> applyRecommendations({
    required String businessId,
    required bool autoApply,
    required List<String> recommendationIds,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }
}
