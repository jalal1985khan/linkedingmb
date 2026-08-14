import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class GMBReviewItem {
  final String id;
  final String name;
  final String reviewerName;
  final String? reviewerPhoto;
  final int starRating;
  final String comment;
  final String createTime;
  final String? reviewReply;
  final String? replyTime;

  const GMBReviewItem({
    required this.id,
    required this.name,
    required this.reviewerName,
    this.reviewerPhoto,
    required this.starRating,
    required this.comment,
    required this.createTime,
    this.reviewReply,
    this.replyTime,
  });

  factory GMBReviewItem.fromJson(Map<String, dynamic> json) {
    int rating = 0;
    final rawRating = json['starRating'] ?? json['star_rating'] ?? json['rating'] ?? json['stars'];
    if (rawRating != null) {
      if (rawRating is int) {
        rating = rawRating;
      } else if (rawRating is double) {
        rating = rawRating.round();
      } else if (rawRating is String) {
        final s = rawRating.trim().toUpperCase();
        const ratingMap = {'ONE': 1, 'TWO': 2, 'THREE': 3, 'FOUR': 4, 'FIVE': 5};
        if (ratingMap.containsKey(s)) {
          rating = ratingMap[s]!;
        } else {
          rating = (double.tryParse(s) ?? 0.0).round();
        }
      }
    }
    if (rating <= 0) rating = 5;

    final reviewer = json['reviewer'] as Map<String, dynamic>? ?? {};
    final replyObj = json['reviewReply'] as Map<String, dynamic>?;

    String? replyText = replyObj?['comment'];
    String? replyTimeStr = replyObj?['updateTime'];

    if (replyText == null || replyText.trim().isEmpty) {
      if (json['reply_comment'] != null && json['reply_comment'].toString().trim().isNotEmpty) {
        replyText = json['reply_comment'].toString().trim();
      } else if (json['reply'] != null) {
        if (json['reply'] is Map && json['reply']['comment'] != null) {
          replyText = json['reply']['comment'].toString().trim();
          replyTimeStr ??= json['reply']['updateTime']?.toString();
        } else if (json['reply'] is String &&
            json['reply'].toString().trim().isNotEmpty &&
            json['reply'].toString() != '1' &&
            json['reply'].toString() != '0') {
          replyText = json['reply'].toString().trim();
        }
      }
    }

    return GMBReviewItem(
      id: json['name'] ?? json['_id'] ?? DateTime.now().toIso8601String(),
      name: json['name'] ?? '',
      reviewerName: reviewer['displayName'] ?? json['reviewerName'] ?? 'Anonymous Customer',
      reviewerPhoto: reviewer['profilePhotoUrl'],
      starRating: rating,
      comment: json['comment'] ?? json['text'] ?? '',
      createTime: json['createTime'] ?? '',
      reviewReply: (replyText != null && replyText.trim().isNotEmpty) ? replyText.trim() : null,
      replyTime: replyTimeStr,
    );
  }
}

class GMBReviewsRepository {
  GMBReviewsRepository({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  static const _tokenKey = 'auth_access_token';

  Future<List<GMBReviewItem>> fetchReviews(String locationName) async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return [];

    final encodedLocation = Uri.encodeComponent(locationName);
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/reviews?location_name=$encodedLocation');

    final response = await _httpClient.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      debugPrint('⚠️ Failed to fetch reviews: ${response.statusCode}');
      return [];
    }

    final decoded = jsonDecode(response.body);
    List<dynamic> reviewsList = [];
    if (decoded is Map<String, dynamic> && decoded['reviews'] is List) {
      reviewsList = decoded['reviews'];
    } else if (decoded is List) {
      reviewsList = decoded;
    }

    return reviewsList
        .whereType<Map<String, dynamic>>()
        .map(GMBReviewItem.fromJson)
        .toList();
  }

  Future<bool> postReply({
    required String reviewName,
    required String replyText,
  }) async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return false;

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/reviews/reply');
    final response = await _httpClient.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'review_name': reviewName,
        'reply_text': replyText,
      }),
    );

    return response.statusCode == 200;
  }

  Future<String?> generateAIReply({
    required String reviewText,
    required String reviewerName,
    required int rating,
  }) async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/reviews/reply/enhance');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'review_text': reviewText,
        'reviewer_name': reviewerName,
        'rating': rating,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['reply_text'] ?? decoded['enhanced_reply'] ?? decoded['reply'];
    }
    return null;
  }
}
