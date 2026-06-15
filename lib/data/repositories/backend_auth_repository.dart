import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

class BackendAuthRepository implements AuthRepository {
  BackendAuthRepository({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _tokenStorageKey = 'auth_access_token';

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<AppUser?> getCurrentUser() async {
    final token = await _secureStorage.read(key: _tokenStorageKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      return await _fetchCurrentUser(token);
    } catch (_) {
      await _secureStorage.delete(key: _tokenStorageKey);
      return null;
    }
  }

  @override
  Future<AppUser> signInWithBackendToken(String token) async {
    final user = await _fetchCurrentUser(token);
    await _secureStorage.write(key: _tokenStorageKey, value: token);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _secureStorage.delete(key: _tokenStorageKey);
  }

  Future<AppUser> _fetchCurrentUser(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/me');
    final response = await _httpClient.get(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch current user (${response.statusCode})');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final id = (data['id'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    if (id.isEmpty || email.isEmpty) {
      throw Exception('Invalid user payload');
    }

    final fullName = (data['full_name'] ?? '').toString().trim();
    final username = (data['username'] ?? '').toString().trim();
    final displayName = fullName.isNotEmpty
        ? fullName
        : (username.isNotEmpty ? username : email.split('@').first);

    return AppUser(
      id: id,
      name: displayName,
      email: email,
    );
  }
}
