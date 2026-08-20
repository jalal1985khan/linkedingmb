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
  final int monthlyLimit;
  final int resetDays;
  final String subscriptionType;

  const UserCredits({
    this.availableCredits = 68,
    this.totalEarned = 100,
    this.totalSpent = 32,
    this.monthlyLimit = 100,
    this.resetDays = 12,
    this.subscriptionType = 'pro',
  });

  bool get isZeroCredits => availableCredits <= 0;
  bool get isLowCredits => availableCredits > 0 && availableCredits <= 15;

  String get planLabel {
    final s = subscriptionType.toLowerCase();
    if (s == 'pro' || s == 'premium') return 'Pro Member';
    if (s == 'starter') return 'Starter Member';
    if (s == 'unlimited') return 'Unlimited Member';
    if (s == 'trial') return 'Pro Member';
    return '${subscriptionType[0].toUpperCase()}${subscriptionType.substring(1)} Member';
  }

  factory UserCredits.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> target = json;
    if (json['subscription'] is Map<String, dynamic>) {
      target = json['subscription'] as Map<String, dynamic>;
    }

    Map<String, dynamic> creditsObj = target;
    if (target['credits'] is Map<String, dynamic>) {
      creditsObj = target['credits'] as Map<String, dynamic>;
    } else if (json['credits'] is Map<String, dynamic>) {
      creditsObj = json['credits'] as Map<String, dynamic>;
    }

    int parseVal(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final available = parseVal(
      creditsObj['available_credits'] ??
      target['available_credits'] ??
      json['available_credits'],
      68,
    );

    final earned = parseVal(
      creditsObj['total_earned'] ??
      target['total_earned'] ??
      json['total_earned'],
      100,
    );

    final spent = parseVal(
      creditsObj['total_spent'] ??
      target['total_spent'] ??
      json['total_spent'],
      0,
    );

    final limit = parseVal(
      creditsObj['monthly_limit'] ??
      target['monthly_limit'] ??
      json['monthly_limit'] ??
      (earned > 0 ? earned : 100),
      100,
    );

    final days = parseVal(
      creditsObj['reset_days'] ??
      target['reset_days'] ??
      json['reset_days'],
      12,
    );

    final subType = (target['subscription_type'] ??
      json['subscription_type'] ??
      'pro').toString();

    return UserCredits(
      availableCredits: available,
      totalEarned: earned,
      totalSpent: spent,
      monthlyLimit: limit,
      resetDays: days,
      subscriptionType: subType,
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

      // Call my-subscription endpoint (returns complete user subscription & credit info)
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
          debugPrint('✅ User credits fetched successfully: ${credits.availableCredits} credits (${credits.subscriptionType})');
          state = AsyncValue.data(credits);
          return;
        }
      } else {
        // Try fallback to /my-credits if /my-subscription returns non-200
        final fallbackUri = Uri.parse('${ApiConfig.baseUrl}/api/subscription/my-credits');
        final fallbackResponse = await http.get(
          fallbackUri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        if (fallbackResponse.statusCode == 200) {
          final data = jsonDecode(fallbackResponse.body);
          if (data is Map<String, dynamic>) {
            final credits = UserCredits.fromJson(data);
            debugPrint('✅ User credits fetched from fallback /my-credits: ${credits.availableCredits} credits');
            state = AsyncValue.data(credits);
            return;
          }
        }
      }

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
