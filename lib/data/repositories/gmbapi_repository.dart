import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../features/auth/auth_controller.dart';
import 'auth_repository.dart';

final gmbapiRepositoryProvider = Provider<GmbapiRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return GmbapiRepository(authRepo);
});

class GmbapiRepository {
  final AuthRepository _authRepository;

  GmbapiRepository(this._authRepository);

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authRepository.getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/auth/login');
    final response = await http.post(uri, headers: await _getHeaders(), body: jsonEncode({
      'email': email,
      'password': password,
    }));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'];
      throw Exception(data['message'] ?? 'Login failed');
    }
    throw Exception('Login failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> register(String email, String password, {String? name}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/auth/register');
    final response = await http.post(uri, headers: await _getHeaders(), body: jsonEncode({
      'email': email,
      'password': password,
      'name': ?name,
    }));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'];
      throw Exception(data['message'] ?? 'Register failed');
    }
    throw Exception('Register failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> refreshToken(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/auth/refresh');
    final response = await http.post(uri, headers: await _getHeaders(), body: jsonEncode({
      'refresh_token': token,
    }));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'];
      throw Exception(data['message'] ?? 'Refresh failed');
    }
    throw Exception('Refresh failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getLocations() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/locations');
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data as Map<String, dynamic>;
      }
      throw Exception(data['message'] ?? 'Failed to load locations');
    }
    throw Exception('Failed to load locations: ${response.statusCode}');
  }

  Future<void> selectLocation(String locationId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/locations/select');
    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode({'location_id': locationId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      }
      throw Exception(data['message'] ?? 'Failed to select location');
    }
    throw Exception('Failed to select location: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getAnalyticsData() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/analytics');
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
      throw Exception(data['message'] ?? 'Failed to load analytics data');
    }
    throw Exception('Failed to load analytics data: ${response.statusCode}');
  }

  Future<void> createPost(String summary, {String topicType = 'STANDARD', String? mediaUrl}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/posts');
    final body = {
      'summary': summary,
      'topic_type': topicType,
      'media_url': ?mediaUrl,
    };

    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      }
      throw Exception(data['message'] ?? 'Failed to create post');
    }
    throw Exception('Failed to create post: ${response.statusCode}');
  }

  Future<void> replyToReview(String reviewId, String replyText) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/reviews/reply');
    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode({
        'review_id': reviewId,
        'answer': replyText,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      }
      throw Exception(data['message'] ?? 'Failed to reply to review');
    }
    throw Exception('Failed to reply to review: ${response.statusCode}');
  }

  Future<String> enhanceReviewReply({
    required String reviewerName,
    required String starRating,
    required String reviewComment,
    String businessName = '',
    String? locationId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/reviews/reply/enhance');
    final body = {
      'reviewer_name': reviewerName,
      'star_rating': starRating,
      'review_comment': reviewComment,
      if (businessName.isNotEmpty) 'business_name': businessName,
      'location_id': ?locationId,
    };

    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['suggested_reply'] != null) {
        return data['suggested_reply'];
      }
      throw Exception(data['message'] ?? 'Failed to generate AI reply');
    }
    throw Exception('Failed to generate AI reply: ${response.statusCode}');
  }

  Future<void> postQna(String question, String answer) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/qna');
    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode({
        'question': question,
        'answer': answer,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return;
      }
      throw Exception(data['message'] ?? 'Failed to post QnA');
    }
    throw Exception('Failed to post QnA: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getLocationReviews({
    int page = 1,
    int perPage = 10,
    int? starRating,
    bool? hasComment,
    bool? hasReply,
    bool? isDeleted,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/reviews/location');
    final Map<String, dynamic> body = {
      'page': page,
      'per_page': perPage,
    };
    if (starRating != null) body['star_rating'] = starRating;
    if (hasComment != null) body['has_comment'] = hasComment;
    if (hasReply != null) body['has_reply'] = hasReply;
    if (isDeleted != null) body['is_deleted'] = isDeleted;

    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'] ?? {};
      throw Exception(data['message'] ?? 'Failed to load reviews');
    }
    throw Exception('Failed to load reviews: ${response.statusCode}');
  }

  Future<List<dynamic>> getPosts() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/posts');
    final response = await http.get(uri, headers: await _getHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['posts'] ?? [];
      throw Exception(data['message'] ?? 'Failed to load posts');
    }
    throw Exception('Failed to load posts: ${response.statusCode}');
  }

  Future<List<dynamic>> getPostsHistory({String? locationId, int limit = 50}) async {
    try {
      final queryParams = <String, String>{
        'platform': 'gmb',
        'limit': limit.toString(),
      };
      if (locationId != null && locationId.isNotEmpty) {
        queryParams['account_id'] = locationId;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/scheduler/posts/history').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['history'] is List) return data['history'];
        if (data['posts'] is List) return data['posts'];
        if (data['scheduled_posts'] is List) return data['scheduled_posts'];
        if (data is List) return data;
      }
    } catch (_) {}

    try {
      return await getPosts();
    } catch (_) {}

    return [];
  }

  Future<void> deletePost(String postId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/posts/$postId');
    final response = await http.delete(uri, headers: await _getHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return;
      throw Exception(data['message'] ?? 'Failed to delete post');
    }
    throw Exception('Failed to delete post: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getCompetitorScan({String? scanId, String? placeId, String? locationId}) async {
    try {
      final headers = await _getHeaders();
      final locId = locationId ?? '';
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/intelligence/combined?location_id=${Uri.encodeComponent(locId)}');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          final data = decoded['data'];
          final competitors = data['competitors'] ?? [];
          return {
            'success': true,
            'results': competitors is List ? competitors : [],
            'status': 'Complete',
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching competitor intelligence: $e');
    }

    // Fallback lookup to /api/gmb/stats
    try {
      final headers = await _getHeaders();
      if (locationId != null && locationId.isNotEmpty) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/stats?location_id=${Uri.encodeComponent(locationId)}');
        final response = await http.get(uri, headers: headers);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['success'] == true && decoded['data'] != null) {
            final competitors = decoded['data']['competitors'] ?? [];
            return {
              'success': true,
              'results': competitors is List ? competitors : [],
              'status': 'Complete',
            };
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Fallback stats competitor lookup error: $e');
    }

    return {'success': true, 'results': [], 'status': 'No competitor data'};
  }

  Future<Map<String, dynamic>> getKeywordScans() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/keyword-scans');
    final response = await http.get(uri, headers: await _getHeaders());
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'] ?? {};
      throw Exception(data['message'] ?? 'Failed to load keyword scans');
    }
    throw Exception('Failed to load keyword scans: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getCompetitorKpi(String placeId, String centerPlaceId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/competitor-kpi').replace(
      queryParameters: {
        'placeId': placeId,
        'centerPlaceId': centerPlaceId,
      }
    );
    final response = await http.get(uri, headers: await _getHeaders());
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'] ?? {};
      throw Exception(data['message'] ?? 'Failed to load competitor KPI');
    }
    throw Exception('Failed to load competitor KPI: ${response.statusCode}');
  }
}
