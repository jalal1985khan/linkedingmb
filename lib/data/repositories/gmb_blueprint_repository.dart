import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

int _parseInt(dynamic val, int fallback) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? fallback;
}

double _parseDouble(dynamic val, double fallback) {
  if (val == null) return fallback;
  if (val is double) return val;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? fallback;
}

class GMBBlueprintItem {
  final String id;
  final int? _dayNumber;
  final String? _title;
  final String? _caption;
  final String? _mediaConcept;
  final String? _ctaType;
  final String? _format;
  final String? status;
  final String? scheduledDate;
  final List<String>? _selectionReasons;
  final int? _costCredits;

  GMBBlueprintItem({
    required this.id,
    int? dayNumber,
    String? title,
    String? caption,
    String? mediaConcept,
    String? ctaType,
    String? format,
    this.status,
    this.scheduledDate,
    List<String>? selectionReasons,
    int? costCredits,
  })  : _dayNumber = dayNumber ?? 1,
        _title = title ?? 'Untitled Concept',
        _caption = caption ?? '',
        _mediaConcept = mediaConcept ?? '',
        _ctaType = ctaType ?? 'LEARN_MORE',
        _format = format ?? 'TEXT_IMAGE',
        _selectionReasons = selectionReasons ?? const [],
        _costCredits = costCredits ?? 2;

  int get dayNumber => _dayNumber ?? 1;
  String get title => _title ?? 'Untitled Concept';
  String get caption => _caption ?? '';
  String get mediaConcept => _mediaConcept ?? '';
  String get ctaType => _ctaType ?? 'LEARN_MORE';
  String get format => _format ?? 'TEXT_IMAGE';
  List<String> get selectionReasons => _selectionReasons ?? const [];
  int get costCredits => _costCredits ?? 2;

  factory GMBBlueprintItem.fromJson(Map<String, dynamic> json) {
    final reasons = (json['selection_reasons'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return GMBBlueprintItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      dayNumber: _parseInt(json['day_number'] ?? json['day'], 1),
      title: json['title']?.toString() ?? 'Untitled Concept',
      caption: json['caption']?.toString() ?? '',
      mediaConcept: json['media_concept']?.toString() ?? json['image_concept']?.toString() ?? '',
      ctaType: json['cta_type']?.toString() ?? 'LEARN_MORE',
      format: json['format']?.toString() ?? json['post_type']?.toString() ?? 'TEXT_IMAGE',
      status: json['status']?.toString(),
      scheduledDate: json['scheduled_date']?.toString() ?? json['scheduled_at']?.toString(),
      selectionReasons: reasons,
      costCredits: _parseInt(json['cost_credits'], 2),
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
    'selection_reasons': selectionReasons,
    'cost_credits': costCredits,
  };
}

class GMBBlueprint {
  final bool success;
  final String? _status;
  final int? _totalItems;
  final int? _planDays;
  final int? _estimatedCredits;
  final List<GMBBlueprintItem>? _items;
  final String? message;

  GMBBlueprint({
    required this.success,
    String? status,
    int? totalItems,
    int? planDays,
    int? estimatedCredits,
    List<GMBBlueprintItem>? items,
    this.message,
  })  : _status = status ?? 'NO_BLUEPRINT',
        _totalItems = totalItems ?? 0,
        _planDays = planDays ?? 30,
        _estimatedCredits = estimatedCredits ?? 0,
        _items = items ?? const [];

  String get status => _status ?? 'NO_BLUEPRINT';
  int get totalItems => _totalItems ?? items.length;
  int get planDays => _planDays ?? 30;
  int get estimatedCredits => _estimatedCredits ?? (items.length * 2);
  List<GMBBlueprintItem> get items => _items ?? const [];

  factory GMBBlueprint.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return GMBBlueprint(
      success: json['success'] == true,
      status: json['status']?.toString() ?? 'NO_BLUEPRINT',
      totalItems: _parseInt(json['total_items'], rawItems.length),
      planDays: _parseInt(json['plan_days'], 30),
      estimatedCredits: _parseInt(json['estimated_credits'], rawItems.length * 2),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(GMBBlueprintItem.fromJson)
          .toList(),
      message: json['message']?.toString(),
    );
  }
}

class GMBTriggerSignal {
  final String kind;
  final String label;
  final String type;
  final String? detail;

  GMBTriggerSignal({
    required this.kind,
    required this.label,
    required this.type,
    this.detail,
  });

  factory GMBTriggerSignal.fromJson(Map<String, dynamic> json) {
    return GMBTriggerSignal(
      kind: json['kind']?.toString() ?? 'leaf',
      label: json['label']?.toString() ?? json['name']?.toString() ?? 'Local Signal',
      type: json['type']?.toString() ?? 'Season',
      detail: json['detail']?.toString() ?? json['description']?.toString(),
    );
  }
}

class GMBLearnedArm {
  final String value;
  final double score;
  final int observations;
  final bool earned;

  GMBLearnedArm({
    required this.value,
    required this.score,
    required this.observations,
    required this.earned,
  });

  factory GMBLearnedArm.fromJson(Map<String, dynamic> json) {
    return GMBLearnedArm(
      value: json['value']?.toString() ?? '',
      score: _parseDouble(json['score'], 0.0),
      observations: _parseInt(json['observations'], 0),
      earned: json['earned'] == true,
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
      'allowed_formats': allowedFormats ?? ['VIDEO', 'TEXT_IMAGE', 'OFFER', 'EVENT', 'PRODUCT', 'SERVICE', 'TEXT_ONLY'],
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
      'title': ?title,
      'caption': ?caption,
      'media_concept': ?mediaConcept,
      'cta_type': ?ctaType,
    });

    final response = await _httpClient.put(uri, headers: headers, body: body);
    return response.statusCode == 200;
  }

  Future<GMBBlueprintItem?> improviseBlueprintItem({
    required String locationId,
    required String itemId,
    String improvementType = 'ENGAGING',
    String? customInstruction,
    String? currentTitle,
    String? currentCaption,
    String? currentMediaConcept,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/automation/blueprint/item/improvise');
    final body = jsonEncode({
      'location_id': locationId,
      'item_id': itemId,
      'improvement_type': improvementType,
      'custom_instruction': ?customInstruction,
      'current_title': ?currentTitle,
      'current_caption': ?currentCaption,
      'current_media_concept': ?currentMediaConcept,
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

  Future<List<GMBTriggerSignal>> getTriggers(String locationId, {bool refresh = false}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/gmb/triggers?location_id=${Uri.encodeComponent(locationId)}&refresh=$refresh',
      );
      final response = await _httpClient.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final signals = decoded['signals'] as List<dynamic>? ?? [];
        return signals
            .whereType<Map<String, dynamic>>()
            .map(GMBTriggerSignal.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> getLearning(String locationId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/gmb/learning?location_id=${Uri.encodeComponent(locationId)}',
      );
      final response = await _httpClient.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }
}
