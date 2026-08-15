import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class CompetitorItem {
  final String name;
  final double? rating;
  final int? reviewCount;
  final int? position;

  const CompetitorItem({
    required this.name,
    this.rating,
    this.reviewCount,
    this.position,
  });

  factory CompetitorItem.fromJson(Map<String, dynamic> json) {
    double? parseRating(dynamic v) => v is num ? v.toDouble() : null;
    int? parseInt(dynamic v) => v is num ? v.toInt() : null;

    return CompetitorItem(
      name: (json['name'] ?? json['title'] ?? 'Competitor').toString(),
      rating: parseRating(json['rating']),
      reviewCount: parseInt(json['reviewCount'] ?? json['review_count']),
      position: parseInt(json['position']),
    );
  }
}

class GMBLocationStats {
  final int views;
  final int searches;
  final int calls;
  final int directionRequests;
  final int websiteClicks;
  final double averageRating;
  final int totalReviews;
  final String? _impressionsChange;
  final String? _callsChange;
  final String? _directionsChange;
  final String? _websiteClicksChange;
  final String? _competitorRank;
  final List<CompetitorItem> _competitors;
  final List<double> chartHeights;
  final List<String> chartLabels;

  const GMBLocationStats({
    this.views = 0,
    this.searches = 0,
    this.calls = 0,
    this.directionRequests = 0,
    this.websiteClicks = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    String? impressionsChange,
    String? callsChange,
    String? directionsChange,
    String? websiteClicksChange,
    String? competitorRank,
    List<CompetitorItem> competitors = const [],
    this.chartHeights = const [],
    this.chartLabels = const [],
  })  : _impressionsChange = impressionsChange,
        _callsChange = callsChange,
        _directionsChange = directionsChange,
        _websiteClicksChange = websiteClicksChange,
        _competitorRank = competitorRank,
        _competitors = competitors;

  String get impressionsChange => (_impressionsChange != null && _impressionsChange.isNotEmpty) ? _impressionsChange : '+0%';
  String get callsChange => (_callsChange != null && _callsChange.isNotEmpty) ? _callsChange : '+0%';
  String get directionsChange => (_directionsChange != null && _directionsChange.isNotEmpty) ? _directionsChange : '+0%';
  String get websiteClicksChange => (_websiteClicksChange != null && _websiteClicksChange.isNotEmpty) ? _websiteClicksChange : '+0%';
  /// Null when this listing did not appear in the local pack, which means
  /// unranked for that query rather than top placement.
  String? get competitorRank =>
      (_competitorRank != null && _competitorRank.isNotEmpty) ? _competitorRank : null;
  List<CompetitorItem> get competitors => _competitors;

  int get totalImpressions {
    if (views > 0 || searches > 0) {
      return views + searches;
    }
    return calls + directionRequests + websiteClicks;
  }

  int get totalInteractions => calls + directionRequests + websiteClicks;

  factory GMBLocationStats.fromJson(Map<String, dynamic> json) {
    int parseVal(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    String parseChange(dynamic v) {
      if (v == null || v.toString().isEmpty || v.toString() == 'null') return '+0%';
      final str = v.toString().trim();
      if (str.startsWith('+') || str.startsWith('-')) return str;
      return '+$str';
    }

    final parsedCompetitors = <CompetitorItem>[];
    if (json['competitors'] is List) {
      for (final item in json['competitors']) {
        if (item is Map<String, dynamic>) {
          parsedCompetitors.add(CompetitorItem.fromJson(item));
        }
      }
    }

    final rawTrend = json['chartHeights'] ?? json['trend'] ?? json['weeklyTrend'];
    List<double> heights = const [];
    if (rawTrend is List && rawTrend.isNotEmpty) {
      heights = rawTrend.map((e) => (num.tryParse(e.toString()) ?? 0.0).toDouble()).toList();
    }

    final rawLabels = json['chartLabels'] ?? json['labels'];
    List<String> labels = const [];
    if (rawLabels is List && rawLabels.isNotEmpty) {
      labels = rawLabels.map((e) => e.toString()).toList();
    }

    return GMBLocationStats(
      views: parseVal(json['overview'] ?? json['views'] ?? json['queriesDirect'] ?? json['viewsMaps']),
      searches: parseVal(json['searches'] ?? json['queriesIndirect'] ?? json['queriesChain']),
      calls: parseVal(json['calls'] ?? json['actionsPhone']),
      directionRequests: parseVal(json['directionRequests'] ?? json['directions'] ?? json['actionsDrivingDirections']),
      websiteClicks: parseVal(json['websiteClicks'] ?? json['actionsWebsite']),
      averageRating: ((json['averageRating'] ?? json['rating'] ?? json['average_rating'] ?? json['overall_rating'] ?? 0.0) as num).toDouble(),
      totalReviews: parseVal(json['totalReviews'] ?? json['reviewCount'] ?? json['total_reviews'] ?? json['review_count']),
      impressionsChange: parseChange(json['impressionsChange'] ?? json['viewsChange']),
      callsChange: parseChange(json['callsChange'] ?? json['engagementChange']),
      directionsChange: parseChange(json['directionsChange']),
      websiteClicksChange: parseChange(json['websiteClicksChange']),
      competitorRank: (json['competitorRank'] ?? json['rank'])?.toString(),
      competitors: parsedCompetitors,
      chartHeights: heights,
      chartLabels: labels,
    );
  }
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

  Future<GMBLocationStats> fetchStats(String locationId, {String timeframe = 'Weekly'}) async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null || token.isEmpty) return const GMBLocationStats();

      final encodedId = Uri.encodeComponent(locationId);
      final encodedTimeframe = Uri.encodeComponent(timeframe.toLowerCase());
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/stats?location_id=$encodedId&timeframe=$encodedTimeframe');

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
      debugPrint('❌ Error fetching GMB analytics stats for location $locationId ($timeframe): $e');
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

      // 1. Try dedicated GMB App Dashboard endpoint
      try {
        final appDashUrl = isAllOrEmpty
            ? '${ApiConfig.baseUrl}/api/gmb/app-dashboard'
            : '${ApiConfig.baseUrl}/api/gmb/app-dashboard?location_id=${Uri.encodeComponent(locationId)}';
        final response = await _httpClient.get(
          Uri.parse(appDashUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['success'] == true && decoded['post_activity'] is Map) {
            final act = decoded['post_activity'];
            final stats = PostActivityStats(
              aiGenerated: (act['ai_generated'] ?? 0) as int,
              manualGenerated: (act['manual_generated'] ?? 0) as int,
              queued: (act['queued'] ?? 0) as int,
              posted: (act['posted'] ?? 0) as int,
            );
            debugPrint('✅ fetchPostActivity from /api/gmb/app-dashboard (${isAllOrEmpty ? "all" : locationId}): AI=${stats.aiGenerated}, Manual=${stats.manualGenerated}, Queue=${stats.queued}, Posted=${stats.posted}');
            return stats;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching /api/gmb/app-dashboard: $e');
      }

      // 2. Try Activity Chart endpoint
      try {
        final chartUrl = isAllOrEmpty
            ? '${ApiConfig.baseUrl}/api/dashboard/activity-chart'
            : '${ApiConfig.baseUrl}/api/dashboard/activity-chart?author_urn=${Uri.encodeComponent(locationId)}';
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
            ? '&account_id=${Uri.encodeComponent(locationId)}'
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

        // d) Query /api/gmb/posts if location specified
        if (useLocation && !isAllOrEmpty) {
          try {
            final gmbUri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/posts?location_id=${Uri.encodeComponent(locationId)}');
            final response = await _httpClient.get(gmbUri, headers: {'Authorization': 'Bearer $token'});
            if (response.statusCode == 200) {
              final decoded = jsonDecode(response.body);
              final list = decoded is Map ? (decoded['posts'] ?? decoded['data'] ?? []) : (decoded is List ? decoded : []);
              if (list is List) {
                for (final item in list) {
                  if (item is Map) {
                    final isAi = item['is_ai_generated'] == true || item['is_ai'] == true || item['model_used'] != null;
                    if (isAi) {
                      aiCount++;
                    } else {
                      manualCount++;
                    }
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
