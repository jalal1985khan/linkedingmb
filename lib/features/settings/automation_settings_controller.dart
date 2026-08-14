import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class AutomationSettingsState {
  final bool isLoading;
  final bool isSaving;
  final bool enabled;
  final bool generateImages;
  final String imageStyle;
  final int intervalHours;
  final int maxPosts;
  final bool autoReviewReply;
  final int minStars;
  final bool onlyWithComments;
  final String? errorMessage;
  final String? successMessage;

  const AutomationSettingsState({
    this.isLoading = true,
    this.isSaving = false,
    this.enabled = true,
    this.generateImages = true,
    this.imageStyle = 'professional',
    this.intervalHours = 24,
    this.maxPosts = 1,
    this.autoReviewReply = true,
    this.minStars = 4,
    this.onlyWithComments = false,
    this.errorMessage,
    this.successMessage,
  });

  AutomationSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? enabled,
    bool? generateImages,
    String? imageStyle,
    int? intervalHours,
    int? maxPosts,
    bool? autoReviewReply,
    int? minStars,
    bool? onlyWithComments,
    String? errorMessage,
    String? successMessage,
  }) {
    return AutomationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      enabled: enabled ?? this.enabled,
      generateImages: generateImages ?? this.generateImages,
      imageStyle: imageStyle ?? this.imageStyle,
      intervalHours: intervalHours ?? this.intervalHours,
      maxPosts: maxPosts ?? this.maxPosts,
      autoReviewReply: autoReviewReply ?? this.autoReviewReply,
      minStars: minStars ?? this.minStars,
      onlyWithComments: onlyWithComments ?? this.onlyWithComments,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class AutomationSettingsController extends StateNotifier<AutomationSettingsState> {
  AutomationSettingsController() : super(const AutomationSettingsState()) {
    fetchSettings();
  }

  final _secureStorage = const FlutterSecureStorage();

  Future<void> fetchSettings({String? locationId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _secureStorage.read(key: 'auth_access_token');
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // 1. Fetch Post Automation Config from backend
      final configUri = Uri.parse('${ApiConfig.baseUrl}/api/automation/scheduler/config');
      final configRes = await http.get(
        configUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      bool isEnabled = state.enabled;
      bool genImages = state.generateImages;
      String style = state.imageStyle;
      int interval = state.intervalHours;
      int postsCount = state.maxPosts;

      if (configRes.statusCode == 200) {
        final data = jsonDecode(configRes.body);
        if (data is Map<String, dynamic> && data['success'] == true) {
          final cfg = data['config'] as Map<String, dynamic>? ?? {};
          isEnabled = cfg['enabled'] ?? true;
          genImages = cfg['generate_images'] ?? true;
          style = (cfg['image_style'] ?? 'professional').toString();
          interval = (cfg['interval_hours'] as num?)?.toInt() ?? 24;
          postsCount = (cfg['max_posts'] as num?)?.toInt() ?? 1;
        }
      }

      // 2. Fetch Review Auto-Reply Config from backend (if locationId provided)
      bool autoReply = state.autoReviewReply;
      int stars = state.minStars;
      bool withComments = state.onlyWithComments;

      if (locationId != null && locationId.isNotEmpty) {
        final replyUri = Uri.parse(
          '${ApiConfig.baseUrl}/api/gmb/reviews/auto-reply-settings?location_id=${Uri.encodeComponent(locationId)}',
        );
        final replyRes = await http.get(
          replyUri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        if (replyRes.statusCode == 200) {
          final replyData = jsonDecode(replyRes.body);
          if (replyData is Map<String, dynamic> && replyData['success'] == true) {
            final st = replyData['settings'] as Map<String, dynamic>? ?? {};
            autoReply = st['enabled'] ?? true;
            stars = (st['min_stars'] as num?)?.toInt() ?? 4;
            withComments = st['only_with_comments'] ?? false;
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        enabled: isEnabled,
        generateImages: genImages,
        imageStyle: style,
        intervalHours: interval,
        maxPosts: postsCount,
        autoReviewReply: autoReply,
        minStars: stars,
        onlyWithComments: withComments,
      );
    } catch (e) {
      debugPrint('⚠️ Error loading automation settings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings from backend',
      );
    }
  }

  void setEnabled(bool val) => state = state.copyWith(enabled: val);
  void setGenerateImages(bool val) => state = state.copyWith(generateImages: val);
  void setImageStyle(String val) => state = state.copyWith(imageStyle: val);
  void setIntervalHours(int val) => state = state.copyWith(intervalHours: val);
  void setAutoReviewReply(bool val) => state = state.copyWith(autoReviewReply: val);
  void setMinStars(int val) => state = state.copyWith(minStars: val);
  void setOnlyWithComments(bool val) => state = state.copyWith(onlyWithComments: val);

  Future<bool> saveSettings({String? locationId}) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final token = await _secureStorage.read(key: 'auth_access_token');
      if (token == null || token.isEmpty) {
        state = state.copyWith(isSaving: false, errorMessage: 'Not authenticated');
        return false;
      }

      // 1. Save Post Automation Config to backend
      final configUri = Uri.parse('${ApiConfig.baseUrl}/api/automation/scheduler/config');
      final configBody = jsonEncode({
        "enabled": state.enabled,
        "generate_images": state.generateImages,
        "image_style": state.imageStyle,
        "interval_hours": state.intervalHours,
        "max_posts": state.maxPosts,
      });

      final configRes = await http.put(
        configUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: configBody,
      ).timeout(const Duration(seconds: 10));

      if (configRes.statusCode != 200) {
        throw Exception('Failed to update automation config (${configRes.statusCode})');
      }

      // 2. Save Review Auto-Reply Config to backend (if locationId provided)
      if (locationId != null && locationId.isNotEmpty) {
        final replyUri = Uri.parse(
          '${ApiConfig.baseUrl}/api/gmb/reviews/auto-reply-settings?location_id=${Uri.encodeComponent(locationId)}',
        );
        final replyBody = jsonEncode({
          "enabled": state.autoReviewReply,
          "min_stars": state.minStars,
          "max_stars": 5,
          "only_with_comments": state.onlyWithComments,
        });

        await http.put(
          replyUri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: replyBody,
        ).timeout(const Duration(seconds: 10));
      }

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Automation settings saved successfully!',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error saving automation settings: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save settings to backend. Please try again.',
      );
      return false;
    }
  }
}

final automationSettingsProvider =
    StateNotifierProvider<AutomationSettingsController, AutomationSettingsState>(
  (ref) => AutomationSettingsController(),
);
