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

      // Helper function to run the full calculation with or without location parameter
      Future<PostActivityStats> calculateActivity(bool includeLocation) async {
        final locParam = (includeLocation && locationId != null && locationId.isNotEmpty)
            ? '&account_id=${Uri.encodeComponent(locationId)}&author_urn=${Uri.encodeComponent(locationId)}'
            : '';
        final chartLocParam = (includeLocation && locationId != null && locationId.isNotEmpty)
            ? '?author_urn=${Uri.encodeComponent(locationId)}'
            : '';

        // 1. Try activity chart endpoint
        try {
          final uri = Uri.parse('${ApiConfig.baseUrl}/api/dashboard/activity-chart$chartLocParam');
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
                debugPrint('✅ fetchPostActivity from activity-chart (includeLocation=$includeLocation): AI=${stats.aiGenerated}, Manual=${stats.manualGenerated}, Queue=${stats.queued}, Posted=${stats.posted}');
                return stats;
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching activity-chart: $e');
        }

        // 2. Fallback algorithm (Matching socialhive-frontend lib/api/dashboard.ts exactly)
        int aiCount = 0;
        int manualCount = 0;
        int queuedCount = 0;
        int postedCount = 0;

        // Fetch GMB API posts
        try {
          final gmbPostsUri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/posts${locParam.startsWith('&') ? '?${locParam.substring(1)}' : locParam}');
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
                } else if (st == 'QUEUED' || st == 'SCHEDULED' || st == 'PENDING' || st == 'DRAFT') {
                  queuedCount++;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching gmbapi/posts fallback: $e');
        }

        // Fetch AI draft posts from /api/scheduler/posts/generated?platform=all (Matching Web lib/api/dashboard.ts)
        try {
          final genUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts/generated?platform=all$locParam');
          final response = await _httpClient.get(
            genUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

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
            // Matching Web lib/api/dashboard.ts lines 129 & 136: Draft posts contribute to both AI and Queue count
            aiCount += genPosts.length;
            queuedCount += genPosts.length;
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching generated posts fallback: $e');
        }

        // Fetch scheduled/queued posts from /api/scheduler/posts?status=all&platform=all (Matching Web lib/api/dashboard.ts)
        try {
          final schedUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts?status=all&platform=all$locParam');
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
            } else if (decoded is Map && decoded['scheduled_posts'] is List) {
              schedPosts = decoded['scheduled_posts'];
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
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching scheduled posts fallback: $e');
        }

        // Fetch published history posts from /api/scheduler/posts/history?platform=all (Matching Web lib/api/dashboard.ts)
        try {
          final histUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts/history?platform=all$locParam');
          final response = await _httpClient.get(
            histUri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            List<dynamic> histPosts = [];
            if (decoded is List) {
              histPosts = decoded;
            } else if (decoded is Map && decoded['posts'] is List) {
              histPosts = decoded['posts'];
            } else if (decoded is Map && decoded['data'] is List) {
              histPosts = decoded['data'];
            }

            postedCount += histPosts.length;
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching post history fallback: $e');
        }

        final computedStats = PostActivityStats(
          aiGenerated: aiCount,
          manualGenerated: manualCount,
          queued: queuedCount,
          posted: postedCount,
        );
        debugPrint('✅ fetchPostActivity computed (includeLocation=$includeLocation): AI=$aiCount, Manual=$manualCount, Queue=$queuedCount, Posted=$postedCount');
        return computedStats;
      } catch (e) {
        debugPrint('⚠️ Error in calculation: $e');
        return const PostActivityStats();
      }
    }

    // Try location-filtered first. If count is 0, fallback to user-wide calculation matching Web
    PostActivityStats result = await calculateActivity(true);
    if (result.totalCount == 0 && locationId != null && locationId.isNotEmpty) {
      debugPrint('ℹ️ Location-specific activity returned 0 stats, falling back to user-wide activity (matching Web)');
      result = await calculateActivity(false);
    }
    return result;
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
