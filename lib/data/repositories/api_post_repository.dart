import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/dashboard_data.dart';
import '../models/scheduled_post.dart';
import 'post_repository.dart';

class ApiPostRepository implements PostRepository {
  ApiPostRepository({
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

  PostStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return PostStatus.draft;
    final s = statusStr.toLowerCase();
    if (s == 'published' || s == 'success' || s == 'completed') return PostStatus.published;
    if (s == 'scheduled') return PostStatus.scheduled;
    if (s == 'queued' || s == 'pending') return PostStatus.queued;
    if (s == 'failed' || s == 'error') return PostStatus.failed;
    return PostStatus.draft;
  }

  ScheduledPost _mapToScheduledPost(Map<String, dynamic> json) {
    final rawId = json['_id'] ?? json['id'] ?? json['postId'] ?? json['name'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final summary = json['summary'] ?? json['content'] ?? json['text'] ?? json['title'] ?? 'Google Business Post';
    final topicType = json['topic_type'] ?? json['topicType'] ?? json['contentType'] ?? 'STANDARD';

    DateTime schedAt = DateTime.now();
    final rawDate = json['scheduled_time'] ?? json['scheduled_at'] ?? json['createTime'] ?? json['created_at'];
    if (rawDate != null) {
      try {
        schedAt = DateTime.parse(rawDate.toString());
      } catch (_) {}
    }

    return ScheduledPost(
      id: rawId.toString(),
      title: summary.toString().length > 60 ? '${summary.toString().substring(0, 57)}...' : summary.toString(),
      preview: summary.toString(),
      platform: 'GOOGLE BUSINESS',
      status: _parseStatus(json['status']?.toString()),
      isAiGenerated: json['is_ai_generated'] == true || json['isAiGenerated'] == true,
      scheduledAt: schedAt,
      contentType: topicType.toString(),
    );
  }

  @override
  Future<DashboardData> fetchDashboardData() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return const DashboardData(queuedCount: 0, aiGeneratedCount: 0, posts: []);
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/posts');
      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      List<ScheduledPost> posts = [];
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List rawList = [];
        if (decoded is Map<String, dynamic>) {
          if (decoded['posts'] is List) {
            rawList = decoded['posts'];
          } else if (decoded['data'] is List) {
            rawList = decoded['data'];
          }
        } else if (decoded is List) {
          rawList = decoded;
        }

        posts = rawList.whereType<Map<String, dynamic>>().map(_mapToScheduledPost).toList();
      }

      final queued = posts.where((p) => p.status == PostStatus.queued || p.status == PostStatus.scheduled).length;
      final aiGen = posts.where((p) => p.isAiGenerated).length;

      return DashboardData(
        queuedCount: queued,
        aiGeneratedCount: aiGen,
        posts: posts,
      );
    } catch (e) {
      debugPrint('❌ Error fetching real dashboard posts: $e');
      return const DashboardData(queuedCount: 0, aiGeneratedCount: 0, posts: []);
    }
  }

  @override
  Future<ScheduledPost> generatePostDraft({
    required String businessName,
    required String topic,
    required String goal,
    required String contentType,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/posts/create');

    final body = {
      'summary': '$topic - $businessName ($goal)',
      'topic_type': contentType.toUpperCase(),
      'is_ai_generated': true,
    };

    if (token != null && token.isNotEmpty) {
      try {
        await _httpClient.post(
          uri,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(body),
        );
      } catch (_) {}
    }

    return ScheduledPost(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: '$topic - $businessName',
      preview: 'AI draft focused on $goal. Optimized for local engagement.',
      platform: 'GOOGLE BUSINESS',
      status: PostStatus.draft,
      isAiGenerated: true,
      scheduledAt: DateTime.now(),
      contentType: contentType,
    );
  }

  @override
  Future<ScheduledPost> schedulePost({
    required String postId,
    required DateTime scheduledAt,
  }) async {
    return ScheduledPost(
      id: postId,
      title: 'Scheduled Post',
      preview: 'Post scheduled for ${scheduledAt.toIso8601String()}',
      platform: 'GOOGLE BUSINESS',
      status: PostStatus.scheduled,
      isAiGenerated: true,
      scheduledAt: scheduledAt,
      contentType: 'STANDARD',
    );
  }

  @override
  Future<ScheduledPost?> getPostById(String postId) async {
    final data = await fetchDashboardData();
    try {
      return data.posts.firstWhere((p) => p.id == postId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ScheduledPost> updatePostDraft({
    required String postId,
    required String title,
    required String preview,
    required String contentType,
  }) async {
    return ScheduledPost(
      id: postId,
      title: title,
      preview: preview,
      platform: 'GOOGLE BUSINESS',
      status: PostStatus.draft,
      isAiGenerated: true,
      scheduledAt: DateTime.now(),
      contentType: contentType,
    );
  }

  @override
  Future<ScheduledPost> publishNow(String postId) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/posts/publish');
    if (token != null && token.isNotEmpty) {
      try {
        await _httpClient.post(
          uri,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({'post_id': postId}),
        );
      } catch (_) {}
    }
    return ScheduledPost(
      id: postId,
      title: 'Published Post',
      preview: 'Post published successfully',
      platform: 'GOOGLE BUSINESS',
      status: PostStatus.published,
      isAiGenerated: true,
      scheduledAt: DateTime.now(),
      contentType: 'STANDARD',
    );
  }

  @override
  Future<ScheduledPost> duplicatePost(String postId) async {
    final existing = await getPostById(postId);
    return ScheduledPost(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: '${existing?.title ?? "Post"} (Copy)',
      preview: existing?.preview ?? '',
      platform: 'GOOGLE BUSINESS',
      status: PostStatus.draft,
      isAiGenerated: existing?.isAiGenerated ?? true,
      scheduledAt: DateTime.now(),
      contentType: existing?.contentType ?? 'STANDARD',
    );
  }

  @override
  Future<void> deletePost(String postId) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/posts/$postId');
    if (token != null && token.isNotEmpty) {
      try {
        await _httpClient.delete(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {}
    }
  }

  @override
  Future<ScheduledPost> retryFailedPost(String postId) async {
    return publishNow(postId);
  }
}
