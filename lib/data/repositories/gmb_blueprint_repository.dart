import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class GMBBlueprintItem {
  final String id;
  final int dayNumber;
  final String title;
  final String caption;
  final String mediaConcept;
  final String ctaType;
  final String format;
  final String? status;
  final String? scheduledDate;

  GMBBlueprintItem({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.caption,
    required this.mediaConcept,
    required this.ctaType,
    required this.format,
    this.status,
    this.scheduledDate,
  });

  factory GMBBlueprintItem.fromJson(Map<String, dynamic> json) {
    return GMBBlueprintItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      dayNumber: (json['day_number'] ?? json['day'] ?? 1) as int,
      title: json['title']?.toString() ?? 'Untitled Concept',
      caption: json['caption']?.toString() ?? '',
      mediaConcept: json['media_concept']?.toString() ?? json['image_concept']?.toString() ?? '',
      ctaType: json['cta_type']?.toString() ?? 'LEARN_MORE',
      format: json['format']?.toString() ?? 'TEXT_IMAGE',
      status: json['status']?.toString(),
      scheduledDate: json['scheduled_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'day_number': dayNumber,
    'title': title,
    'caption': caption,
    'media_concept': mediaConcept,
    'cta_type': ctaType,
    'format': format,
    'status': status,
    'scheduled_date': scheduledDate,
  };
}

class GMBBlueprint {
  final bool success;
  final String status;
  final int totalItems;
  final int planDays;
  final int estimatedCredits;
  final List<GMBBlueprintItem> items;
  final String? message;

  GMBBlueprint({
    required this.success,
    required this.status,
    required this.totalItems,
    required this.planDays,
    required this.estimatedCredits,
    required this.items,
    this.message,
  });

  factory GMBBlueprint.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return GMBBlueprint(
      success: json['success'] == true,
      status: json['status']?.toString() ?? 'NO_BLUEPRINT',
      totalItems: (json['total_items'] ?? rawItems.length) as int,
      planDays: (json['plan_days'] ?? 30) as int,
      estimatedCredits: (json['estimated_credits'] ?? 0) as int,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(GMBBlueprintItem.fromJson)
          .toList(),
      message: json['message']?.toString(),
    );
  }
}

final gmbBlueprintRepositoryProvider = Provider<GMBBlueprintRepository>((ref) {
  return GMBBlueprintRepository();
});

class GMBBlueprintRepository {
  GMBBlueprintRepository({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _tokenStorageKey = 'auth_access_token';
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: _tokenStorageKey);
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<GMBBlueprint> getBlueprint(String locationId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/gmb/automation/blueprint?location_id=${Uri.encodeComponent(locationId)}',
    );
    final response = await _httpClient.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load blueprint (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return GMBBlueprint.fromJson(decoded);
  }

  Future<GMBBlueprint> generateBlueprint({
    required String locationId,
    int postsPerWeek = 5,
    List<String>? allowedFormats,
    bool autoSchedule = false,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/automation/generate-blueprint');
    final body = jsonEncode({
      'location_id': locationId,
      'posts_per_week': postsPerWeek,
      'user_role': 'pro',
      'allowed_formats': allowedFormats ?? ['VIDEO', 'TEXT_IMAGE', 'OFFER', 'EVENT', 'PRODUCT', 'SERVICE'],
      'auto_schedule': autoSchedule,
    });

    final response = await _httpClient.post(uri, headers: headers, body: body);
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['message'] ?? 'Failed to generate blueprint');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return GMBBlueprint.fromJson(decoded);
  }

  Future<bool> updateBlueprintItem({
    required String locationId,
    required String itemId,
    String? title,
    String? caption,
    String? mediaConcept,
    String? ctaType,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/automation/blueprint/item');
    final body = jsonEncode({
      'location_id': locationId,
      'item_id': itemId,
      if (title != null) 'title': title,
      if (caption != null) 'caption': caption,
      if (mediaConcept != null) 'media_concept': mediaConcept,
      if (ctaType != null) 'cta_type': ctaType,
    });

    final response = await _httpClient.put(uri, headers: headers, body: body);
    return response.statusCode == 200;
  }

  Future<GMBBlueprintItem?> improviseBlueprintItem({
    required String locationId,
    required String itemId,
    String? instruction,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/automation/blueprint/item/improvise');
    final body = jsonEncode({
      'location_id': locationId,
      'item_id': itemId,
      if (instruction != null) 'instruction': instruction,
    });

    final response = await _httpClient.post(uri, headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to improvise item (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['item'] != null) {
      return GMBBlueprintItem.fromJson(decoded['item'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<Map<String, dynamic>> renderAndSchedule(String locationId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/automation/render-and-schedule');
    final body = jsonEncode({'location_id': locationId});

    final response = await _httpClient.post(uri, headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('Failed to schedule blueprint (${response.statusCode})');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
