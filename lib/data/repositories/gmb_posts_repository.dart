import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class GMBPostRequest {
  final String locationName;
  final String summary;
  final String topicType; // STANDARD, EVENT, OFFER
  final String? callToActionType; // NONE, BOOK, ORDER, SHOP, LEARN_MORE, SIGN_UP, CALL
  final String? callToActionUrl;
  final String? mediaUrl;
  final String? eventTitle;
  final Map<String, dynamic>? eventSchedule;
  final String? couponCode;
  final String? redeemUrl;
  final String? termsConditions;
  final String? scheduledTime;

  const GMBPostRequest({
    required this.locationName,
    required this.summary,
    this.topicType = 'STANDARD',
    this.callToActionType,
    this.callToActionUrl,
    this.mediaUrl,
    this.eventTitle,
    this.eventSchedule,
    this.couponCode,
    this.redeemUrl,
    this.termsConditions,
    this.scheduledTime,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'location_name': locationName,
      'summary': summary,
      'topic_type': topicType,
    };

    if (callToActionType != null && callToActionType != 'NONE') {
      body['call_to_action'] = {
        'actionType': callToActionType,
        'url': callToActionUrl ?? '',
      };
      body['action_type'] = callToActionType;
      body['action_url'] = callToActionUrl ?? '';
    }

    if (mediaUrl != null && mediaUrl!.isNotEmpty) {
      body['media_url'] = mediaUrl;
      body['media'] = [
        {
          'mediaFormat': 'PHOTO',
          'sourceUrl': mediaUrl,
        }
      ];
    }

    if (topicType == 'EVENT' || topicType == 'OFFER') {
      if (eventTitle != null && eventTitle!.isNotEmpty) {
        body['event'] = {
          'title': eventTitle,
          if (eventSchedule != null) 'schedule': eventSchedule,
        };
      }
    }

    if (topicType == 'OFFER') {
      final offerObj = <String, dynamic>{};
      if (couponCode != null && couponCode!.isNotEmpty) offerObj['couponCode'] = couponCode;
      if (redeemUrl != null && redeemUrl!.isNotEmpty) offerObj['redeemOnlineUrl'] = redeemUrl;
      if (termsConditions != null && termsConditions!.isNotEmpty) offerObj['termsConditions'] = termsConditions;
      if (offerObj.isNotEmpty) body['offer'] = offerObj;
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
      debugPrint('📝 Post create body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error creating GMB post: $e');
      return false;
    }
  }
}
