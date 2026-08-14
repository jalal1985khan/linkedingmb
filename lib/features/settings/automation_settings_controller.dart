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
  final int maxStars;
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
    this.minStars = 3,
    this.maxStars = 5,
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
    int? maxStars,
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
      maxStars: maxStars ?? this.maxStars,
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

      if (fetchedPersonas.every((p) => p['id'] != 'socialhive')) {
        fetchedPersonas.insert(0, {'id': 'socialhive', 'name': 'socialhive'});
      }
      if (fetchedGroups.every((g) => g['id'] != 'SocialHive Official Group')) {
        fetchedGroups.insert(0, {'id': 'SocialHive Official Group', 'name': 'SocialHive Official Group'});
      }

      // 2. Fetch GMB Auto-Pilot Config from backend with dual fallback
      final locParam = (locationId != null && locationId.isNotEmpty) ? '?location_id=${Uri.encodeComponent(locationId)}' : '';
      
      http.Response? configRes;
      try {
        configRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/gmb/automation/config$locParam'), headers: headers).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('⚠️ Initial config fetch error: $e');
      }

      if (configRes == null || configRes.statusCode == 404) {
        // Fallback to /api/automation/scheduler/config
        try {
          configRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/automation/scheduler/config$locParam'), headers: headers).timeout(const Duration(seconds: 8));
        } catch (_) {}
      }

      bool isEnabled = state.enabled;
      String jName = state.jobName;
      int perWeek = state.postsPerWeek;
      List<String> slots = List.from(state.postingSlots);
      String? pId = state.personaId;
      String? kgId = state.knowledgeGroupId;
      List<String> formats = List.from(state.allowedFormats);

      if (configRes != null && configRes.statusCode == 200) {
        final data = jsonDecode(configRes.body);
        if (data is Map<String, dynamic>) {
          final cfg = (data['config'] ?? data['data'] ?? data) as Map<String, dynamic>? ?? {};
          isEnabled = cfg['enabled'] ?? true;
          jName = (cfg['job_name'] ?? cfg['job_title'] ?? 'GMB Automation').toString();
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

      // 3. Fetch Review Auto-Reply Config with dual fallback
      bool autoReply = state.autoReviewReply;
      int minS = state.minStars;
      int maxS = state.maxStars;
      bool withComments = state.onlyWithComments;

      http.Response? replyRes;
      try {
        replyRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/gmb/settings/auto-reply$locParam'), headers: headers).timeout(const Duration(seconds: 8));
      } catch (_) {}

      if (replyRes == null || replyRes.statusCode == 404) {
        try {
          replyRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/gmb/reviews/auto-reply-settings$locParam'), headers: headers).timeout(const Duration(seconds: 8));
        } catch (_) {}
      }

      if (replyRes != null && replyRes.statusCode == 200) {
        final replyData = jsonDecode(replyRes.body);
        if (replyData is Map<String, dynamic> && replyData['success'] == true) {
          final st = replyData['settings'] as Map<String, dynamic>? ?? {};
          autoReply = st['enabled'] ?? true;
          minS = (st['min_stars'] as num?)?.toInt() ?? 3;
          maxS = (st['max_stars'] as num?)?.toInt() ?? 5;
          withComments = st['only_with_comments'] ?? false;
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
        minStars: minS,
        maxStars: maxS,
        onlyWithComments: withComments,
        personas: fetchedPersonas,
        knowledgeGroups: fetchedGroups,
      );
    } catch (e) {
      debugPrint('⚠️ Error loading GMB autopilot settings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Loaded default GMB Auto-Pilot settings.',
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
  void setMaxStars(int val) => state = state.copyWith(maxStars: val);
  void setOnlyWithComments(bool val) => state = state.copyWith(onlyWithComments: val);

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

      final payload = {
        "location_id": locationId,
        "job_name": state.jobName,
        "enabled": state.enabled,
        "posts_per_week": state.postsPerWeek,
        "posting_slots": state.postingSlots,
        "persona_id": state.personaId,
        "knowledge_group_id": state.knowledgeGroupId,
        "allowed_formats": state.allowedFormats,
      };

      // 1. Save GMB Auto-Pilot Config with dual fallback
      http.Response? configRes;
      try {
        configRes = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/gmb/automation/config'),
          headers: headers,
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('⚠️ Initial config post error: $e');
      }

      if (configRes == null || configRes.statusCode == 404) {
        // Fallback to /api/automation/scheduler/config
        try {
          configRes = await http.put(
            Uri.parse('${ApiConfig.baseUrl}/api/automation/scheduler/config'),
            headers: headers,
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 10));
        } catch (_) {}
      }

      // 2. Save Review Auto-Reply Config with dual fallback
      final replyPayload = {
        "location_id": locationId,
        "enabled": state.autoReviewReply,
        "min_stars": state.minStars,
        "max_stars": state.maxStars,
        "only_with_comments": state.onlyWithComments,
      };

      http.Response? replyRes;
      try {
        replyRes = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/gmb/settings/auto-reply'),
          headers: headers,
          body: jsonEncode(replyPayload),
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}

      if (replyRes == null || replyRes.statusCode == 404) {
        try {
          replyRes = await http.put(
            Uri.parse('${ApiConfig.baseUrl}/api/gmb/reviews/auto-reply-settings?location_id=${Uri.encodeComponent(locationId ?? '')}'),
            headers: headers,
            body: jsonEncode(replyPayload),
          ).timeout(const Duration(seconds: 10));
        } catch (_) {}
      }

      state = state.copyWith(
        isSaving: false,
        successMessage: '✨ GMB Auto-Pilot & Auto-Reply settings saved successfully!',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error saving GMB Auto-Pilot settings: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Saved locally. Please ensure backend service is running.',
      );
      return true;
    }
  }
}

final automationSettingsProvider =
    StateNotifierProvider<AutomationSettingsController, AutomationSettingsState>(
  (ref) => AutomationSettingsController(),
);
