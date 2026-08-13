import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class GMBPostRequest {
  final String locationName;
  final String summary;
  final String? topicType; // STANDARD, EVENT, OFFER
  final String? callToActionType; // LEARN_MORE, CALL, BOOK, SHOP, GET_OFFER
  final String? callToActionUrl;
  final String? mediaUrl;
  final String? scheduledTime;

  const GMBPostRequest({
    required this.locationName,
    required this.summary,
    this.topicType = 'STANDARD',
    this.callToActionType,
    this.callToActionUrl,
    this.mediaUrl,
    this.scheduledTime,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'location_name': locationName,
      'summary': summary,
      'topic_type': topicType ?? 'STANDARD',
    };

    if (callToActionType != null && callToActionType!.isNotEmpty) {
      body['action_type'] = callToActionType;
      if (callToActionUrl != null && callToActionUrl!.isNotEmpty) {
        body['action_url'] = callToActionUrl;
      }
    }

    if (mediaUrl != null && mediaUrl!.isNotEmpty) {
      body['media_url'] = mediaUrl;
    }

    if (scheduledTime != null && scheduledTime!.isNotEmpty) {
      body['scheduled_time'] = scheduledTime;
    }

    return body;
  }
}

class GMBPostsRepository {
  GMBPostsRepository({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  static const _tokenKey = 'auth_access_token';

  Future<bool> createPost(GMBPostRequest post) async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null || token.isEmpty) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/posts/create');
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(post.toJson()),
      );

      debugPrint('📝 Post create status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error creating GMB post: $e');
      return false;
    }
  }
}
