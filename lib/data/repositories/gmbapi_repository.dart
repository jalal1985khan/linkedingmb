import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import 'backend_auth_repository.dart';

final gmbapiRepositoryProvider = Provider<GmbapiRepository>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return GmbapiRepository(authRepo);
});

class GmbapiRepository {
  final BackendAuthRepository _authRepository;

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
      if (name != null) 'name': name,
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

  Future<List<dynamic>> getLocations() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/locations');
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['locations'];
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
      if (mediaUrl != null) 'media_url': mediaUrl,
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/reviews/$reviewId/reply');
    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode({
        'reply_text': replyText,
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

  Future<List<dynamic>> getReviews() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/reviews');
    final response = await http.get(uri, headers: await _getHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['reviews'] ?? [];
      throw Exception(data['message'] ?? 'Failed to load reviews');
    }
    throw Exception('Failed to load reviews: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getReviewById(String reviewId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/reviews/$reviewId');
    final response = await http.get(uri, headers: await _getHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['review'];
      throw Exception(data['message'] ?? 'Failed to load review');
    }
    throw Exception('Failed to load review: ${response.statusCode}');
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
}
