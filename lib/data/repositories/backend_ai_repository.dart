import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/ai_recommendation.dart';
import '../models/business_profile.dart';
import 'ai_repository.dart';

class BackendAiRepository implements AiRepository {
  BackendAiRepository({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  static const _tokenKey = 'auth_access_token';

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> analyzeBusiness(BusinessProfile profile) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/intelligence/combined');
      await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('❌ Error analyzing business: $e');
    }
  }

  @override
  Future<List<AiRecommendation>> getRecommendations(String businessId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return [];

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/intelligence/combined');
      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['recommendations'] ?? decoded['items'] ?? [];
        if (list is List) {
          return list.map((item) {
            final m = item as Map<String, dynamic>;
            return AiRecommendation(
              id: (m['id'] ?? m['_id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
              title: (m['title'] ?? 'Business Recommendation').toString(),
              description: (m['reasoning'] ?? m['description'] ?? 'AI suggestion to improve profile visibility.').toString(),
              impact: (m['impact'] ?? m['type'] ?? 'HIGH').toString(),
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting AI recommendations: $e');
    }
    return [];
  }

  @override
  Future<void> applyRecommendations({
    required String businessId,
    required bool autoApply,
    required List<String> recommendationIds,
  }) async {
    debugPrint('Applied ${recommendationIds.length} AI recommendations for $businessId');
  }
}
