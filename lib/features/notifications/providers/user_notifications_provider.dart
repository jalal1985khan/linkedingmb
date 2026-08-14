import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.data = const {},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'] ?? json['_id'] ?? '';
    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    DateTime parsedDate;
    if (createdAtRaw is String) {
      parsedDate = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return AppNotification(
      id: idVal.toString(),
      title: (json['title'] ?? 'Notification').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      isRead: json['isRead'] == true || json['is_read'] == true,
      createdAt: parsedDate,
      data: json['data'] is Map<String, dynamic> ? Map<String, dynamic>.from(json['data']) : {},
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data,
    );
  }
}

class UserNotificationsNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  UserNotificationsNotifier() : super(const AsyncValue.loading()) {
    fetchNotifications();
    _startPeriodicRefresh();
  }

  final _secureStorage = const FlutterSecureStorage();
  Timer? _timer;

  void _startPeriodicRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNotifications(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }

    try {
      final token = await _secureStorage.read(key: 'auth_access_token');
      if (token == null || token.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/user-notifications/?limit=50');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> listData = [];
        if (decoded is List) {
          listData = decoded;
        } else if (decoded is Map<String, dynamic> && decoded['notifications'] is List) {
          listData = decoded['notifications'];
        }

        final notifications = listData
            .map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        state = AsyncValue.data(notifications);
      } else {
        if (!silent) {
          state = AsyncValue.error('Failed to fetch notifications: ${response.statusCode}', StackTrace.current);
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[UserNotifications] Error fetching notifications: $e');
      }
      if (!silent) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    final currentList = state.valueOrNull ?? [];
    state = AsyncValue.data(
      currentList.map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n).toList(),
    );

    try {
      final token = await _secureStorage.read(key: 'auth_access_token');
      if (token == null || token.isEmpty) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/user-notifications/$notificationId/read');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('[UserNotifications] Error marking notification read: $e');
      }
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    final currentList = state.valueOrNull ?? [];
    state = AsyncValue.data(
      currentList.map((n) => n.copyWith(isRead: true)).toList(),
    );

    try {
      final token = await _secureStorage.read(key: 'auth_access_token');
      if (token == null || token.isEmpty) return false;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/user-notifications/read-all');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('[UserNotifications] Error marking all notifications read: $e');
      }
      return false;
    }
  }
}

final userNotificationsProvider =
    StateNotifierProvider<UserNotificationsNotifier, AsyncValue<List<AppNotification>>>((ref) {
  return UserNotificationsNotifier();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(userNotificationsProvider);
  final notifs = notifsAsync.valueOrNull ?? [];
  return notifs.where((n) => !n.isRead).length;
});
