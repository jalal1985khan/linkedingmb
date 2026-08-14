import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';

class UserCredits {
  final int availableCredits;
  final int totalEarned;
  final int totalSpent;
  final String subscriptionType;

  const UserCredits({
    this.availableCredits = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    this.subscriptionType = 'trial',
  });

  bool get isZeroCredits => availableCredits <= 0;
  bool get isLowCredits => availableCredits <= 10;

  factory UserCredits.fromJson(Map<String, dynamic> json) {
    final creditsObj = json['credits'] is Map<String, dynamic>
        ? json['credits']
        : <String, dynamic>{};

    int parseVal(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return UserCredits(
      availableCredits: parseVal(creditsObj['available_credits'] ?? json['available_credits']),
      totalEarned: parseVal(creditsObj['total_earned'] ?? json['total_earned']),
      totalSpent: parseVal(creditsObj['total_spent'] ?? json['total_spent']),
      subscriptionType: (json['subscription_type'] ?? 'trial').toString(),
    );
  }
}

class UserCreditsNotifier extends StateNotifier<AsyncValue<UserCredits>> {
  UserCreditsNotifier() : super(const AsyncValue.loading()) {
    fetchCredits();
  }

  final _secureStorage = const FlutterSecureStorage();

  Future<void> fetchCredits() async {
    try {
      final token = await _secureStorage.read(key: 'auth_access_token');
      if (token == null || token.isEmpty) {
        state = AsyncValue.data(const UserCredits());
        return;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/subscription/my-subscription');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final credits = UserCredits.fromJson(data);
          state = AsyncValue.data(credits);
          return;
        }
      }
      // If endpoint call fails or returns non-200, fallback cleanly to 0
      state = AsyncValue.data(state.valueOrNull ?? const UserCredits());
    } catch (e) {
      debugPrint('⚠️ Error fetching user credits: $e');
      state = AsyncValue.data(state.valueOrNull ?? const UserCredits());
    }
  }
}

final userCreditsProvider =
    StateNotifierProvider<UserCreditsNotifier, AsyncValue<UserCredits>>((ref) {
  return UserCreditsNotifier();
});
