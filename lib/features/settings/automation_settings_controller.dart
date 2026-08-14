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
  final String jobName;
  final int postsPerWeek;
  final List<String> postingSlots;
  final String? personaId;
  final String? knowledgeGroupId;
  final List<String> allowedFormats;
  final bool autoReviewReply;
  final int minStars;
  final bool onlyWithComments;
  final List<Map<String, String>> personas;
  final List<Map<String, String>> knowledgeGroups;
  final String? errorMessage;
  final String? successMessage;

  const AutomationSettingsState({
    this.isLoading = true,
    this.isSaving = false,
    this.enabled = true,
    this.jobName = 'GMB Automation',
    this.postsPerWeek = 3,
    this.postingSlots = const ['9:00 AM', '1:00 PM', '5:00 PM'],
    this.personaId,
    this.knowledgeGroupId,
    this.allowedFormats = const [
      'product_spotlights',
      'service_highlights',
      'quick_tips',
    ],
    this.autoReviewReply = true,
    this.minStars = 4,
    this.onlyWithComments = false,
    this.personas = const [],
    this.knowledgeGroups = const [],
    this.errorMessage,
    this.successMessage,
  });

  AutomationSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? enabled,
    String? jobName,
    int? postsPerWeek,
    List<String>? postingSlots,
    String? personaId,
    String? knowledgeGroupId,
    List<String>? allowedFormats,
    bool? autoReviewReply,
    int? minStars,
    bool? onlyWithComments,
    List<Map<String, String>>? personas,
    List<Map<String, String>>? knowledgeGroups,
    String? errorMessage,
    String? successMessage,
  }) {
    return AutomationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      enabled: enabled ?? this.enabled,
      jobName: jobName ?? this.jobName,
      postsPerWeek: postsPerWeek ?? this.postsPerWeek,
      postingSlots: postingSlots ?? this.postingSlots,
      personaId: personaId ?? this.personaId,
      knowledgeGroupId: knowledgeGroupId ?? this.knowledgeGroupId,
      allowedFormats: allowedFormats ?? this.allowedFormats,
      autoReviewReply: autoReviewReply ?? this.autoReviewReply,
      minStars: minStars ?? this.minStars,
      onlyWithComments: onlyWithComments ?? this.onlyWithComments,
      personas: personas ?? this.personas,
      knowledgeGroups: knowledgeGroups ?? this.knowledgeGroups,
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

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // 1. Fetch Personas & Knowledge Groups in parallel
      final personasFuture = _fetchDropdownItems('${ApiConfig.baseUrl}/api/personas', headers, 'personas');
      final groupsFuture = _fetchDropdownItems('${ApiConfig.baseUrl}/api/knowledge-groups', headers, 'groups');

      final results = await Future.wait([personasFuture, groupsFuture]);
      final fetchedPersonas = results[0];
      final fetchedGroups = results[1];

      // Add default "socialhive" persona & "SocialHive Official Group" if empty
      if (fetchedPersonas.every((p) => p['id'] != 'socialhive')) {
        fetchedPersonas.insert(0, {'id': 'socialhive', 'name': 'socialhive'});
      }
      if (fetchedGroups.every((g) => g['id'] != 'SocialHive Official Group')) {
        fetchedGroups.insert(0, {'id': 'SocialHive Official Group', 'name': 'SocialHive Official Group'});
      }

      // 2. Fetch GMB Auto-Pilot Config from backend
      final locParam = locationId != null ? '?location_id=${Uri.encodeComponent(locationId)}' : '';
      final configUri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/automation/config$locParam');
      final configRes = await http.get(configUri, headers: headers).timeout(const Duration(seconds: 10));

      bool isEnabled = state.enabled;
      String jName = state.jobName;
      int perWeek = state.postsPerWeek;
      List<String> slots = List.from(state.postingSlots);
      String? pId = state.personaId;
      String? kgId = state.knowledgeGroupId;
      List<String> formats = List.from(state.allowedFormats);

      if (configRes.statusCode == 200) {
        final data = jsonDecode(configRes.body);
        if (data is Map<String, dynamic> && data['success'] == true) {
          final cfg = data['config'] as Map<String, dynamic>? ?? {};
          isEnabled = cfg['enabled'] ?? true;
          jName = (cfg['job_name'] ?? 'GMB Automation').toString();
          perWeek = (cfg['posts_per_week'] as num?)?.toInt() ?? 3;
          
          if (cfg['posting_slots'] is List) {
            slots = (cfg['posting_slots'] as List).map((e) => e.toString()).toList();
          }
          if (cfg['allowed_formats'] is List) {
            formats = (cfg['allowed_formats'] as List).map((e) => e.toString()).toList();
          }

          pId = cfg['persona_id']?.toString();
          kgId = cfg['knowledge_group_id']?.toString();
        }
      }

      pId ??= 'socialhive';
      kgId ??= 'SocialHive Official Group';

      // 3. Fetch Review Auto-Reply Config
      bool autoReply = state.autoReviewReply;
      int stars = state.minStars;
      bool withComments = state.onlyWithComments;

      if (locationId != null && locationId.isNotEmpty) {
        final replyUri = Uri.parse(
          '${ApiConfig.baseUrl}/api/gmb/reviews/auto-reply-settings?location_id=${Uri.encodeComponent(locationId)}',
        );
        final replyRes = await http.get(replyUri, headers: headers).timeout(const Duration(seconds: 10));

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
        jobName: jName,
        postsPerWeek: perWeek,
        postingSlots: slots,
        personaId: pId,
        knowledgeGroupId: kgId,
        allowedFormats: formats,
        autoReviewReply: autoReply,
        minStars: stars,
        onlyWithComments: withComments,
        personas: fetchedPersonas,
        knowledgeGroups: fetchedGroups,
      );
    } catch (e) {
      debugPrint('⚠️ Error loading GMB autopilot settings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load GMB Auto-Pilot settings from backend',
      );
    }
  }

  Future<List<Map<String, String>>> _fetchDropdownItems(String url, Map<String, String> headers, String key) async {
    try {
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map<String, dynamic>) {
          rawList = data[key] ?? data['items'] ?? data['data'] ?? [];
        }
        return rawList.map<Map<String, String>>((item) {
          final id = (item['_id'] ?? item['id'] ?? item['persona_id'] ?? item['group_id'] ?? '').toString();
          final name = (item['name'] ?? item['persona_name'] ?? item['title'] ?? id).toString();
          return {'id': id, 'name': name};
        }).where((m) => m['id']!.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching $key dropdown items: $e');
    }
    return [];
  }

  void setEnabled(bool val) => state = state.copyWith(enabled: val);
  void setJobName(String val) => state = state.copyWith(jobName: val);
  void setPostsPerWeek(int val) => state = state.copyWith(postsPerWeek: val);
  
  void setPostingSlots(List<String> slots) {
    state = state.copyWith(postingSlots: slots);
  }

  void addPostingSlot(String slot) {
    if (!state.postingSlots.contains(slot)) {
      state = state.copyWith(postingSlots: [...state.postingSlots, slot]);
    }
  }

  void removePostingSlot(String slot) {
    state = state.copyWith(postingSlots: state.postingSlots.where((s) => s != slot).toList());
  }

  void toggleAllowedFormat(String format) {
    final current = List<String>.from(state.allowedFormats);
    if (current.contains(format)) {
      current.remove(format);
    } else {
      current.add(format);
    }
    state = state.copyWith(allowedFormats: current);
  }

  void setPersonaId(String? val) => state = state.copyWith(personaId: val);
  void setKnowledgeGroupId(String? val) => state = state.copyWith(knowledgeGroupId: val);
  void setAutoReviewReply(bool val) => state = state.copyWith(autoReviewReply: val);
  void setMinStars(int val) => state = state.copyWith(minStars: val);

  Future<bool> saveSettings({String? locationId}) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final token = await _secureStorage.read(key: 'auth_access_token');
      if (token == null || token.isEmpty) {
        state = state.copyWith(isSaving: false, errorMessage: 'Not authenticated');
        return false;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // 1. Save GMB Auto-Pilot Config to backend
      final configUri = Uri.parse('${ApiConfig.baseUrl}/api/gmb/automation/config');
      final configBody = jsonEncode({
        "location_id": locationId,
        "job_name": state.jobName,
        "enabled": state.enabled,
        "posts_per_week": state.postsPerWeek,
        "posting_slots": state.postingSlots,
        "persona_id": state.personaId,
        "knowledge_group_id": state.knowledgeGroupId,
        "allowed_formats": state.allowedFormats,
      });

      final configRes = await http.post(configUri, headers: headers, body: configBody).timeout(const Duration(seconds: 10));

      if (configRes.statusCode != 200) {
        throw Exception('Failed to save GMB Auto-Pilot config (${configRes.statusCode})');
      }

      // Also trigger blueprint generation & auto-scheduling on backend
      try {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/gmb/automation/generate-blueprint'),
          headers: headers,
          body: jsonEncode({
            "location_id": locationId ?? "",
            "posts_per_week": state.postsPerWeek,
            "allowed_formats": state.allowedFormats,
            "auto_schedule": true
          }),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('⚠️ Blueprint trigger notification: $e');
      }

      // 2. Save Review Auto-Reply Config
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

        await http.put(replyUri, headers: headers, body: replyBody).timeout(const Duration(seconds: 10));
      }

      state = state.copyWith(
        isSaving: false,
        successMessage: 'GMB Auto-Pilot configuration saved & synced with backend!',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error saving GMB Auto-Pilot settings: $e');
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
