import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class GMBLocationStats {
  final int views;
  final int searches;
  final int calls;
  final int directionRequests;
  final int websiteClicks;
  final double averageRating;
  final int totalReviews;

  const GMBLocationStats({
    this.views = 0,
    this.searches = 0,
    this.calls = 0,
    this.directionRequests = 0,
    this.websiteClicks = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  factory GMBLocationStats.fromJson(Map<String, dynamic> json) {
    int parseVal(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return GMBLocationStats(
      views: parseVal(json['views'] ?? json['overview'] ?? json['queriesDirect'] ?? json['viewsMaps']),
      searches: parseVal(json['searches'] ?? json['queriesIndirect'] ?? json['queriesChain']),
      calls: parseVal(json['calls'] ?? json['actionsPhone']),
      directionRequests: parseVal(json['directionRequests'] ?? json['directions'] ?? json['actionsDrivingDirections']),
      websiteClicks: parseVal(json['websiteClicks'] ?? json['actionsWebsite']),
      averageRating: ((json['averageRating'] ?? json['rating'] ?? 0.0) as num).toDouble(),
      totalReviews: parseVal(json['totalReviews'] ?? json['reviewCount']),
    );
  }

  int get totalInteractions => calls + directionRequests + websiteClicks;
}

class GMBAnalyticsRepository {
  GMBAnalyticsRepository({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  static const _tokenKey = 'auth_access_token';

  Future<GMBLocationStats> fetchStats(String locationId) async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null || token.isEmpty) return const GMBLocationStats();

      final encodedId = Uri.encodeComponent(locationId);
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/stats?location_id=$encodedId');

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['data'] != null) {
          return GMBLocationStats.fromJson(decoded['data']);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching GMB analytics stats for location $locationId: $e');
    }
    return const GMBLocationStats();
  }

  Future<PostActivityStats> fetchPostActivity({String? locationId}) async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ fetchPostActivity: Token is null or empty');
        return const PostActivityStats();
      }

      // 1. Try location-specific activity chart endpoint first
      if (locationId != null && locationId.isNotEmpty) {
        try {
          final uri = Uri.parse('${ApiConfig.baseUrl}/api/dashboard/activity-chart?author_urn=${Uri.encodeComponent(locationId)}');
          final response = await _httpClient.get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if (decoded['success'] == true && decoded['data'] is List) {
              final stats = PostActivityStats.fromActivityList(decoded['data']);
              if (stats.totalCount > 0 && (stats.queued > 0 || stats.posted > 0)) {
                debugPrint('✅ fetchPostActivity from location activity-chart: AI=${stats.aiGenerated}, Manual=${stats.manualGenerated}, Queue=${stats.queued}, Posted=${stats.posted}');
                return stats;
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching location activity-chart: $e');
        }
      }

      // 2. Try global user activity chart (as web frontend does by default)
      try {
        final globalUri = Uri.parse('${ApiConfig.baseUrl}/api/dashboard/activity-chart');
        final response = await _httpClient.get(
          globalUri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['success'] == true && decoded['data'] is List) {
            final stats = PostActivityStats.fromActivityList(decoded['data']);
            if (stats.totalCount > 0 && (stats.queued > 0 || stats.posted > 0)) {
              debugPrint('✅ fetchPostActivity from global activity-chart: AI=${stats.aiGenerated}, Manual=${stats.manualGenerated}, Queue=${stats.queued}, Posted=${stats.posted}');
              return stats;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching global activity-chart: $e');
      }

      // 3. Fallback: Query /api/gmbapi/posts AND /api/scheduler/posts/generated
      try {
        int aiCount = 0;
        int manualCount = 0;
        int queuedCount = 0;
        int postedCount = 0;

        // Fetch posts from /api/gmbapi/posts
        try {
          final gmbPostsUri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/posts');
          final response = await _httpClient.get(
            gmbPostsUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            List<dynamic> posts = [];
            if (decoded is Map) {
              if (decoded['posts'] is List) {
                posts = decoded['posts'];
              } else if (decoded['data'] is List) {
                posts = decoded['data'];
              }
            } else if (decoded is List) {
              posts = decoded;
            }

            for (final item in posts) {
              if (item is Map) {
                final isAi = item['is_ai_generated'] == true ||
                    item['is_ai'] == true ||
                    (item['model_used'] != null && item['model_used'].toString().isNotEmpty) ||
                    (item['post_origin'] != null && item['post_origin'].toString().contains('ai')) ||
                    (item['topic_type'] != null && item['topic_type'].toString().isNotEmpty);

                if (isAi) {
                  aiCount++;
                } else {
                  manualCount++;
                }

                final st = item['status']?.toString().toUpperCase() ?? '';
                if (st == 'LIVE' || st == 'POSTED' || st == 'PUBLISHED' || st == 'SUCCESS' || st == 'COMPLETED') {
                  postedCount++;
                } else if (st == 'QUEUED' || st == 'SCHEDULED' || st == 'PENDING') {
                  queuedCount++;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching gmbapi/posts fallback: $e');
        }

        // Fetch generated AI draft posts from /api/scheduler/posts/generated (matching Web logic)
        try {
          final genUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts/generated?platform=all');
          final response = await _httpClient.get(
            genUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          debugPrint('📊 /api/scheduler/posts/generated HTTP ${response.statusCode}: ${response.body}');

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            List<dynamic> genPosts = [];
            if (decoded is List) {
              genPosts = decoded;
            } else if (decoded is Map && decoded['posts'] is List) {
              genPosts = decoded['posts'];
            } else if (decoded is Map && decoded['data'] is List) {
              genPosts = decoded['data'];
            }
            debugPrint('✅ Found ${genPosts.length} generated draft posts via /api/scheduler/posts/generated');
            aiCount += genPosts.length;
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching generated posts fallback: $e');
        }

        // Fetch scheduled/queued posts from /api/scheduler/posts?status=all
        try {
          final schedUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts?status=all');
          final response = await _httpClient.get(
            schedUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            List<dynamic> schedPosts = [];
            if (decoded is List) {
              schedPosts = decoded;
            } else if (decoded is Map && decoded['posts'] is List) {
              schedPosts = decoded['posts'];
            } else if (decoded is Map && decoded['data'] is List) {
              schedPosts = decoded['data'];
            }

            for (final p in schedPosts) {
              if (p is Map) {
                final st = (p['status'] ?? '').toString().toLowerCase();
                if (st == 'posted' || st == 'published' || st == 'success' || st == 'completed' || st == 'live') {
                  postedCount++;
                } else {
                  queuedCount++;
                }
              }
            }
            debugPrint('✅ Processed ${schedPosts.length} scheduled/queued posts from /api/scheduler/posts?status=all');
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching scheduled posts fallback: $e');
        }

        final computedStats = PostActivityStats(
          aiGenerated: aiCount,
          manualGenerated: manualCount,
          queued: queuedCount,
          posted: postedCount,
        );
        debugPrint('✅ fetchPostActivity computed: AI=$aiCount, Manual=$manualCount, Queue=$queuedCount, Posted=$postedCount');
        return computedStats;
      } catch (e) {
        debugPrint('⚠️ Error in fallback post activity calculation: $e');
      }
    } catch (e) {
      debugPrint('❌ Error in fetchPostActivity: $e');
    }
    return const PostActivityStats();
  }
}

class PostActivityStats {
  final int aiGenerated;
  final int manualGenerated;
  final int queued;
  final int posted;

  const PostActivityStats({
    this.aiGenerated = 0,
    this.manualGenerated = 0,
    this.queued = 0,
    this.posted = 0,
  });

  int get totalCount => aiGenerated + manualGenerated + queued + posted;

  factory PostActivityStats.fromActivityList(List<dynamic> list) {
    int ai = 0;
    int manual = 0;
    int queued = 0;
    int posted = 0;

    int parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    for (final item in list) {
      if (item is Map) {
        ai += parseNum(item['ai'] ?? item['ai_generated'] ?? item['aiGenerated']);
        manual += parseNum(item['manual'] ?? item['manual_generated'] ?? item['manualGenerated']);
        queued += parseNum(item['queue'] ?? item['queued'] ?? item['scheduled']);
        posted += parseNum(item['posted'] ?? item['published']);
      }
    }
    return PostActivityStats(
      aiGenerated: ai,
      manualGenerated: manual,
      queued: queued,
      posted: posted,
    );
  }
}
