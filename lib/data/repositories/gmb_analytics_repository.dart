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

      final isAllOrEmpty = locationId == null ||
          locationId.isEmpty ||
          locationId.toLowerCase() == 'all' ||
          locationId.toLowerCase() == 'default' ||
          locationId.toLowerCase() == 'personal_default';

      // 1. Try Activity Chart endpoint (Matching Web dashboardApi.getActivityChartData)
      try {
        final chartUrl = isAllOrEmpty
            ? '${ApiConfig.baseUrl}/api/dashboard/activity-chart'
            : '${ApiConfig.baseUrl}/api/dashboard/activity-chart?author_urn=${Uri.encodeComponent(locationId!)}';
        final response = await _httpClient.get(
          Uri.parse(chartUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['success'] == true && decoded['data'] is List) {
            final stats = PostActivityStats.fromActivityList(decoded['data']);
            if (stats.totalCount > 0) {
              debugPrint('✅ fetchPostActivity from activity-chart (${isAllOrEmpty ? "all" : locationId}): AI=${stats.aiGenerated}, Manual=${stats.manualGenerated}, Queue=${stats.queued}, Posted=${stats.posted}');
              return stats;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching activity-chart: $e');
      }

      // Helper function to run the full calculation with or without location parameter (Matching Web fallback)
      Future<PostActivityStats> computeFallback(bool useLocation) async {
        int aiCount = 0;
        int manualCount = 0;
        int queuedCount = 0;
        int postedCount = 0;

        final accParam = (useLocation && !isAllOrEmpty)
            ? '&account_id=${Uri.encodeComponent(locationId!)}'
            : '';

        // a) Query /api/scheduler/posts/generated?platform=all (Matching Web lib/api/dashboard.ts line 93)
        try {
          final genUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts/generated?platform=all$accParam');
          final response = await _httpClient.get(genUri, headers: {'Authorization': 'Bearer $token'});
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            final list = decoded is List ? decoded : (decoded['posts'] ?? decoded['data'] ?? []);
            if (list is List) {
              // Matching Web lib/api/dashboard.ts lines 129 & 136: Draft posts contribute to both AI and Queue count
              aiCount += list.length;
              queuedCount += list.length;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching generated posts: $e');
        }

        // b) Query /api/scheduler/posts?status=all&platform=all (Matching Web lib/api/dashboard.ts line 97)
        try {
          final schedUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts?status=all&platform=all$accParam');
          final response = await _httpClient.get(schedUri, headers: {'Authorization': 'Bearer $token'});
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            final list = decoded is List ? decoded : (decoded['scheduled_posts'] ?? decoded['posts'] ?? decoded['data'] ?? []);
            if (list is List) {
              for (final p in list) {
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
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching scheduled posts: $e');
        }

        // c) Query /api/scheduler/posts/history?platform=all (Matching Web lib/api/dashboard.ts line 104)
        try {
          final histUri = Uri.parse('${ApiConfig.baseUrl}/api/scheduler/posts/history?platform=all$accParam');
          final response = await _httpClient.get(histUri, headers: {'Authorization': 'Bearer $token'});
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            final list = decoded is List ? decoded : (decoded['posts'] ?? decoded['data'] ?? []);
            if (list is List) {
              postedCount += list.length;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching post history: $e');
        }

        // d) Query /api/gmbapi/posts if location specified
        if (useLocation && !isAllOrEmpty) {
          try {
            final gmbUri = Uri.parse('${ApiConfig.baseUrl}/api/gmbapi/posts?location_id=${Uri.encodeComponent(locationId!)}');
            final response = await _httpClient.get(gmbUri, headers: {'Authorization': 'Bearer $token'});
            if (response.statusCode == 200) {
              final decoded = jsonDecode(response.body);
              final list = decoded is Map ? (decoded['posts'] ?? decoded['data'] ?? []) : (decoded is List ? decoded : []);
              if (list is List) {
                for (final item in list) {
                  if (item is Map) {
                    final isAi = item['is_ai_generated'] == true || item['is_ai'] == true || item['model_used'] != null;
                    if (isAi) aiCount++; else manualCount++;
                    final st = item['status']?.toString().toUpperCase() ?? '';
                    if (st == 'LIVE' || st == 'POSTED' || st == 'PUBLISHED' || st == 'SUCCESS' || st == 'COMPLETED') {
                      postedCount++;
                    } else {
                      queuedCount++;
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error fetching gmbapi/posts: $e');
          }
        }

        return PostActivityStats(
          aiGenerated: aiCount,
          manualGenerated: manualCount,
          queued: queuedCount,
          posted: postedCount,
        );
      }

      PostActivityStats stats = await computeFallback(true);
      debugPrint('✅ fetchPostActivity computed stats for ${isAllOrEmpty ? "all" : locationId}: AI=${stats.aiGenerated}, Manual=${stats.manualGenerated}, Queue=${stats.queued}, Posted=${stats.posted}');
      return stats;
    } catch (e) {
      debugPrint('❌ Error in fetchPostActivity: $e');
      return const PostActivityStats();
    }
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
