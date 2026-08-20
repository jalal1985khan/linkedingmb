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
    if (statusStr == null || statusStr.isEmpty) return PostStatus.scheduled;
    final s = statusStr.toLowerCase().trim();
    if (s == 'published' || s == 'success' || s == 'completed' || s == 'posted') return PostStatus.published;
    if (s == 'scheduled' || s == 'approved') return PostStatus.scheduled;
    if (s == 'queued' || s == 'pending' || s == 'waiting') return PostStatus.queued;
    if (s == 'failed' || s == 'error') return PostStatus.failed;
    if (s == 'draft') return PostStatus.draft;
    return PostStatus.scheduled;
  }

  ScheduledPost? _mapToScheduledPost(Map<String, dynamic> json) {
    final rawId = json['_id'] ??
        json['id'] ??
        json['postId'] ??
        json['name'] ??
        json['gmb_post_id'] ??
        DateTime.now().millisecondsSinceEpoch.toString();

    // Normalise body/preview matching web displayBody
    final caption = json['caption']?.toString();
    final content = json['content']?.toString();
    final summary = json['summary']?.toString();
    final text = json['text']?.toString();
    final rawTitle = json['title']?.toString();
    final topic = json['topic']?.toString();

    final previewText = (caption != null && caption.isNotEmpty)
        ? caption
        : (content != null && content.isNotEmpty)
            ? content
            : (summary != null && summary.isNotEmpty)
                ? summary
                : (text != null && text.isNotEmpty)
                    ? text
                    : (rawTitle ?? '');

    // Normalise title matching web scheduled-posts-widget.tsx
    String title = 'Untitled Post';
    if (previewText.isNotEmpty) {
      title = previewText.length > 50 ? '${previewText.substring(0, 47)}...' : previewText;
    } else if (rawTitle != null && rawTitle.isNotEmpty && !rawTitle.startsWith('Published Post')) {
      title = rawTitle;
    } else if (topic != null && topic.isNotEmpty) {
      title = topic;
    }

    final topicType = json['topic_type'] ??
        json['topicType'] ??
        json['contentType'] ??
        json['post_type'] ??
        'STANDARD';

    DateTime schedAt = DateTime.now();
    final rawDate = json['scheduled_at'] ??
        json['scheduled_time'] ??
        json['published_at'] ??
        json['posted_at'] ??
        json['created_at'] ??
        json['createTime'] ??
        json['timestamp'];
    if (rawDate != null) {
      try {
        final s = rawDate.toString().trim();
        final isoStr = s.contains(' ') && !s.contains('T') ? s.replaceFirst(' ', 'T') : s;
        schedAt = DateTime.parse(isoStr);
      } catch (_) {}
    }

    final isAi = json['is_ai_generated'] == true ||
        json['isAiGenerated'] == true ||
        json['ai_generated'] == true ||
        json['automation_generated'] == true;

    // Extract thumbnail URL matching web imgUrl logic
    String? imgUrl = json['generated_image_url'] ??
        json['image_url'] ??
        json['image_data'] ??
        json['media_url'] ??
        json['mediaUrl'] ??
        json['image_path'];
    if (imgUrl != null && imgUrl.isEmpty) imgUrl = null;

    return ScheduledPost(
      id: rawId.toString(),
      title: title,
      preview: previewText.isNotEmpty ? previewText : title,
      platform: (json['platform']?.toString() ?? 'GOOGLE BUSINESS').toUpperCase(),
      status: _parseStatus(json['status']?.toString()),
      isAiGenerated: isAi,
      scheduledAt: schedAt,
      contentType: topicType.toString(),
      imageUrl: imgUrl,
    );
  }

  @override
  Future<DashboardData> fetchDashboardData({String? locationId}) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return const DashboardData(queuedCount: 0, aiGeneratedCount: 0, posts: []);
      }

      List<ScheduledPost> posts = [];
      final seenIds = <String>{};
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      String cleanId = '';
      String gmbLocParam = '';
      if (locationId != null &&
          locationId.isNotEmpty &&
          locationId != 'all' &&
          locationId != 'personal_default' &&
          locationId != 'social_hive_default') {
        cleanId = locationId.replaceFirst('locations/', '');
        gmbLocParam = '?location_id=${Uri.encodeComponent(cleanId)}';
      }

      void addPostsFromList(dynamic rawList, {bool filterOutPublished = true}) {
        if (rawList is! List) return;
        for (final item in rawList) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final rawStatus = (map['status'] ?? '').toString().toLowerCase();
            if (filterOutPublished && (rawStatus == 'posted' || rawStatus == 'published' || rawStatus == 'executed')) {
              continue;
            }

            final mapped = _mapToScheduledPost(map);
            if (mapped != null && mapped.id.isNotEmpty && !seenIds.contains(mapped.id)) {
              seenIds.add(mapped.id);
              posts.add(mapped);
            }
          }
        }
      }

      // 1. Fetch LinkedIn Scheduler Queue
      try {
        final liSchedUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts?status=all&limit=100&platform=linkedin');
        final response = await _httpClient.get(liSchedUri, headers: headers);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final list = decoded is Map ? (decoded['scheduled_posts'] ?? decoded['posts'] ?? decoded['data']) : decoded;
          final prevCount = posts.length;
          addPostsFromList(list);
          debugPrint('📥 /api/scheduler/posts (linkedin) returned ${posts.length - prevCount} scheduled posts');
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching /api/scheduler/posts (linkedin): $e');
      }

      // 2. Fetch GMB Scheduler Queue
      try {
        final gmbSchedUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts?status=all&limit=100&platform=gmb');
        final response = await _httpClient.get(gmbSchedUri, headers: headers);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final list = decoded is Map ? (decoded['scheduled_posts'] ?? decoded['posts'] ?? decoded['data']) : decoded;
          final prevCount = posts.length;
          addPostsFromList(list);
          debugPrint('📥 /api/scheduler/posts (gmb) returned ${posts.length - prevCount} scheduled posts');
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching /api/scheduler/posts (gmb): $e');
      }

      // 3. Fetch from GMB Posts API (/api/gmb/posts)
      try {
        final gmbUri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/posts$gmbLocParam');
        final response = await _httpClient.get(gmbUri, headers: headers);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final list = decoded is Map ? (decoded['posts'] ?? decoded['data']) : decoded;
          final prevCount = posts.length;
          addPostsFromList(list);
          debugPrint('📥 /api/gmb/posts returned ${posts.length - prevCount} active posts');
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching /api/gmb/posts: $e');
      }

      // 4. Fetch AI-generated draft posts
      try {
        final genUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts/generated?limit=50&platform=linkedin');
        final response = await _httpClient.get(genUri, headers: headers);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final list = decoded is Map ? (decoded['posts'] ?? decoded['data']) : decoded;
          final prevCount = posts.length;
          addPostsFromList(list);
          debugPrint('📥 /api/scheduler/posts/generated (linkedin) returned ${posts.length - prevCount} drafts');
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching /api/scheduler/posts/generated: $e');
      }

      try {
        final genGmbUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts/generated?limit=50&platform=gmb');
        final response = await _httpClient.get(genGmbUri, headers: headers);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final list = decoded is Map ? (decoded['posts'] ?? decoded['data']) : decoded;
          final prevCount = posts.length;
          addPostsFromList(list);
          debugPrint('📥 /api/scheduler/posts/generated (gmb) returned ${posts.length - prevCount} drafts');
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching /api/scheduler/posts/generated (gmb): $e');
      }

      // Sort by scheduledAt ascending
      posts.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      final queued = posts.where((p) => p.status == PostStatus.queued || p.status == PostStatus.scheduled || p.status == PostStatus.draft).length;
      final aiGen = posts.where((p) => p.isAiGenerated).length;

      debugPrint('📅 [ScheduledPosts] Fetched ${posts.length} posts for location: ${locationId ?? 'all'} (Queued: $queued, AI-Gen: $aiGen)');
      for (int i = 0; i < posts.length && i < 4; i++) {
        final p = posts[i];
        final overdueStr = p.scheduledAt.isBefore(DateTime.now()) ? ' (OVERDUE)' : '';
        debugPrint('   ↳ [${p.status.name.toUpperCase()}$overdueStr] "${p.title}" | scheduled: ${p.scheduledAt}');
      }

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
