import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class CapabilityInfo {
  final String key;
  final String label;
  final String description;
  final bool reversible;
  final bool immutable;
  final String defaultLevel;
  final String maxLevel;

  CapabilityInfo({
    required this.key,
    required this.label,
    required this.description,
    required this.reversible,
    required this.immutable,
    required this.defaultLevel,
    required this.maxLevel,
  });

  factory CapabilityInfo.fromJson(Map<String, dynamic> json) {
    return CapabilityInfo(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      reversible: json['reversible'] == true,
      immutable: json['immutable'] == true,
      defaultLevel: json['default_level']?.toString() ?? 'approve',
      maxLevel: json['max_level']?.toString() ?? 'autopilot',
    );
  }
}

class AutonomySettings {
  final String locationId;
  final bool isPaused;
  final String? pauseReason;
  final Map<String, String> levels;

  AutonomySettings({
    required this.locationId,
    required this.isPaused,
    this.pauseReason,
    required this.levels,
  });

  factory AutonomySettings.fromJson(Map<String, dynamic> json) {
    final settingsMap = json['settings'] as Map<String, dynamic>? ?? json;
    final levelsMap = <String, String>{};
    final rawLevels = settingsMap['levels'] as Map<String, dynamic>? ?? settingsMap['capabilities'] as Map<String, dynamic>? ?? {};
    rawLevels.forEach((k, v) => levelsMap[k] = v.toString());

    return AutonomySettings(
      locationId: settingsMap['location_id']?.toString() ?? '',
      isPaused: settingsMap['is_paused'] == true || settingsMap['paused'] == true,
      pauseReason: settingsMap['pause_reason']?.toString(),
      levels: levelsMap,
    );
  }
}

class ApprovalItem {
  final String id;
  final String capability;
  final String summary;
  final String? reason;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> preview;
  final String status;
  final String? createdAt;

  ApprovalItem({
    required this.id,
    required this.capability,
    required this.summary,
    this.reason,
    required this.payload,
    required this.preview,
    required this.status,
    this.createdAt,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    return ApprovalItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      capability: json['capability']?.toString() ?? '',
      summary: json['summary']?.toString() ?? 'Pending Action',
      reason: json['reason']?.toString(),
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      preview: (json['preview'] as Map<String, dynamic>?) ?? {},
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString(),
    );
  }
}

final gmbAutonomyRepositoryProvider = Provider<GMBAutonomyRepository>((ref) {
  return GMBAutonomyRepository();
});

class GMBAutonomyRepository {
  GMBAutonomyRepository({
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

  Future<List<CapabilityInfo>> getCapabilities() async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/autonomy/capabilities');
    final response = await _httpClient.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load capabilities (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['capabilities'] as List<dynamic>? ?? []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(CapabilityInfo.fromJson)
        .toList();
  }

  Future<AutonomySettings> getSettings(String locationId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/gmb/autonomy/settings?location_id=${Uri.encodeComponent(locationId)}',
    );
    final response = await _httpClient.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load autonomy settings (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return AutonomySettings.fromJson(decoded);
  }

  Future<bool> updateSettings(String locationId, Map<String, String> updates) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/autonomy/settings');
    final body = jsonEncode({
      'location_id': locationId,
      'updates': updates,
    });

    final response = await _httpClient.post(uri, headers: headers, body: body);
    return response.statusCode == 200;
  }

  Future<bool> setPaused(String locationId, bool paused, {String? reason}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/autonomy/pause');
    final body = jsonEncode({
      'location_id': locationId,
      'paused': paused,
      if (reason != null) 'reason': reason,
    });

    final response = await _httpClient.post(uri, headers: headers, body: body);
    return response.statusCode == 200;
  }

  Future<List<ApprovalItem>> listApprovals(String locationId, {String status = 'pending'}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/gmb/autonomy/approvals?location_id=${Uri.encodeComponent(locationId)}&status=$status',
    );
    final response = await _httpClient.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load approvals (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['approvals'] ?? decoded['items'] ?? []) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(ApprovalItem.fromJson)
        .toList();
  }

  Future<bool> resolveApproval(String approvalId, String decision, {String? note}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/autonomy/approvals/resolve');
    final body = jsonEncode({
      'approval_id': approvalId,
      'decision': decision, // 'approved' or 'rejected'
      if (note != null) 'note': note,
    });

    final response = await _httpClient.post(uri, headers: headers, body: body);
    return response.statusCode == 200;
  }
}
