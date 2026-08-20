import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class GMBQAPair {
  final String question;
  final String answer;
  final String? createTime;
  final String? status;

  GMBQAPair({
    required this.question,
    required this.answer,
    this.createTime,
    this.status,
  });

  factory GMBQAPair.fromJson(Map<String, dynamic> json) {
    return GMBQAPair(
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      createTime: json['createTime']?.toString() ?? json['created_at']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
    'createTime': createTime,
    'status': status,
  };
}

final gmbQARepositoryProvider = Provider<GMBQARepository>((ref) {
  return GMBQARepository();
});

class GMBQARepository {
  GMBQARepository({
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

  Future<List<GMBQAPair>> getPublishedQA(String locationId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/gmb/qa?location_id=${Uri.encodeComponent(locationId)}',
    );
    final response = await _httpClient.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load published Q&As (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['qa_list'] ?? decoded['items'] ?? []) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(GMBQAPair.fromJson)
        .toList();
  }

  Future<List<GMBQAPair>> getDrafts(String locationId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/gmb/qa/drafts?location_id=${Uri.encodeComponent(locationId)}',
    );
    final response = await _httpClient.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load Q&A drafts (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['drafts'] ?? decoded['qa_list'] ?? []) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(GMBQAPair.fromJson)
        .toList();
  }

  Future<List<GMBQAPair>> generateQA({
    required String locationId,
    String? businessName,
    String? category,
    String? city,
    int count = 5,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/qa/generate');
    final body = jsonEncode({
      'location_id': locationId,
      if (businessName != null) 'business_name': businessName,
      if (category != null) 'category': category,
      if (city != null) 'city': city,
      'count': count,
    });

    final response = await _httpClient.post(uri, headers: headers, body: body);
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['message'] ?? 'Failed to generate Q&As');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (decoded['qa_list'] ?? []) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(GMBQAPair.fromJson)
        .toList();
  }

  Future<bool> postQA({
    required String locationId,
    required String question,
    required String answer,
  }) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/qa/post');
    final body = jsonEncode({
      'location_id': locationId,
      'question': question,
      'answer': answer,
    });

    final response = await _httpClient.post(uri, headers: headers, body: body);
    return response.statusCode == 200;
  }
}
