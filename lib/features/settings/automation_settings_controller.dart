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
  final String timingMode; // 'interval' or 'specific'
  final int intervalHours;
  final int scheduleHoursAhead;
  final String optimalPostingTimes;
  final int maxArticles;
  final int maxPosts;
  final String? personaId;
  final String? templateId;
  final String? knowledgeGroupId;
  final bool generateImages;
  final String imageStyle;
  final bool autoReviewReply;
  final int minStars;
  final bool onlyWithComments;
  final List<Map<String, String>> personas;
  final List<Map<String, String>> templates;
  final List<Map<String, String>> knowledgeGroups;
  final String? errorMessage;
  final String? successMessage;

  const AutomationSettingsState({
    this.isLoading = true,
    this.isSaving = false,
    this.enabled = true,
    this.timingMode = 'interval',
    this.intervalHours = 20,
    this.scheduleHoursAhead = 31,
    this.optimalPostingTimes = '09:00, 13:00, 17:00',
    this.maxArticles = 1,
    this.maxPosts = 1,
    this.personaId,
    this.templateId,
    this.knowledgeGroupId,
    this.generateImages = true,
    this.imageStyle = 'professional',
    this.autoReviewReply = true,
    this.minStars = 4,
    this.onlyWithComments = false,
    this.personas = const [],
    this.templates = const [],
    this.knowledgeGroups = const [],
    this.errorMessage,
    this.successMessage,
  });

  AutomationSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? enabled,
    String? timingMode,
    int? intervalHours,
    int? scheduleHoursAhead,
    String? optimalPostingTimes,
    int? maxArticles,
    int? maxPosts,
    String? personaId,
    String? templateId,
    String? knowledgeGroupId,
    bool? generateImages,
    String? imageStyle,
    bool? autoReviewReply,
    int? minStars,
    bool? onlyWithComments,
    List<Map<String, String>>? personas,
    List<Map<String, String>>? templates,
    List<Map<String, String>>? knowledgeGroups,
    String? errorMessage,
    String? successMessage,
  }) {
    return AutomationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      enabled: enabled ?? this.enabled,
      timingMode: timingMode ?? this.timingMode,
      intervalHours: intervalHours ?? this.intervalHours,
      scheduleHoursAhead: scheduleHoursAhead ?? this.scheduleHoursAhead,
      optimalPostingTimes: optimalPostingTimes ?? this.optimalPostingTimes,
      maxArticles: maxArticles ?? this.maxArticles,
      maxPosts: maxPosts ?? this.maxPosts,
      personaId: personaId ?? this.personaId,
      templateId: templateId ?? this.templateId,
      knowledgeGroupId: knowledgeGroupId ?? this.knowledgeGroupId,
      generateImages: generateImages ?? this.generateImages,
      imageStyle: imageStyle ?? this.imageStyle,
      autoReviewReply: autoReviewReply ?? this.autoReviewReply,
      minStars: minStars ?? this.minStars,
      onlyWithComments: onlyWithComments ?? this.onlyWithComments,
      personas: personas ?? this.personas,
      templates: templates ?? this.templates,
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

      // 1. Fetch Personas, Templates & Knowledge Groups in parallel
      final personasFuture = _fetchDropdownItems('${ApiConfig.baseUrl}/api/personas', headers, 'personas');
      final templatesFuture = _fetchDropdownItems('${ApiConfig.baseUrl}/api/templates', headers, 'templates');
      final groupsFuture = _fetchDropdownItems('${ApiConfig.baseUrl}/api/knowledge-groups', headers, 'groups');

      final results = await Future.wait([personasFuture, templatesFuture, groupsFuture]);
      final fetchedPersonas = results[0];
      final fetchedTemplates = results[1];
      final fetchedGroups = results[2];

      // 2. Fetch Post Automation Config from backend
      final configUri = Uri.parse('${ApiConfig.baseUrl}/api/automation/scheduler/config');
      final configRes = await http.get(configUri, headers: headers).timeout(const Duration(seconds: 10));

      bool isEnabled = state.enabled;
      String tMode = state.timingMode;
      int interval = state.intervalHours;
      int schedAhead = state.scheduleHoursAhead;
      String optTimes = state.optimalPostingTimes;
      int articles = state.maxArticles;
      int postsCount = state.maxPosts;
      String? pId = state.personaId;
      String? tId = state.templateId;
      String? kgId = state.knowledgeGroupId;
      bool genImages = state.generateImages;
      String style = state.imageStyle;

      if (configRes.statusCode == 200) {
        final data = jsonDecode(configRes.body);
        if (data is Map<String, dynamic> && data['success'] == true) {
          final cfg = data['config'] as Map<String, dynamic>? ?? {};
          isEnabled = cfg['enabled'] ?? true;
          tMode = (cfg['timing_mode'] ?? 'interval').toString();
          interval = (cfg['interval_hours'] as num?)?.toInt() ?? 20;
          schedAhead = (cfg['schedule_hours_ahead'] as num?)?.toInt() ?? 31;
          
          final optRaw = cfg['optimal_posting_times'];
          if (optRaw is List) {
            optTimes = optRaw.join(', ');
          } else if (optRaw != null) {
            optTimes = optRaw.toString();
          }

          articles = (cfg['max_articles'] as num?)?.toInt() ?? 1;
          postsCount = (cfg['max_posts'] as num?)?.toInt() ?? 1;
          pId = cfg['persona_id']?.toString();
          tId = cfg['template_id']?.toString();
          kgId = cfg['knowledge_group_id']?.toString();
          genImages = cfg['generate_images'] ?? true;
          style = (cfg['image_style'] ?? 'professional').toString();
        }
      }

      // Default dropdown selection if not set
      if ((pId == null || pId.isEmpty) && fetchedPersonas.isNotEmpty) {
        pId = fetchedPersonas.first['id'];
      }
      if ((tId == null || tId.isEmpty) && fetchedTemplates.isNotEmpty) {
        tId = fetchedTemplates.first['id'];
      }
      if ((kgId == null || kgId.isEmpty) && fetchedGroups.isNotEmpty) {
        kgId = fetchedGroups.first['id'];
      }

      // 3. Fetch Review Auto-Reply Config from backend (if locationId provided)
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
        timingMode: tMode,
        intervalHours: interval,
        scheduleHoursAhead: schedAhead,
        optimalPostingTimes: optTimes,
        maxArticles: articles,
        maxPosts: postsCount,
        personaId: pId,
        templateId: tId,
        knowledgeGroupId: kgId,
        generateImages: genImages,
        imageStyle: style,
        autoReviewReply: autoReply,
        minStars: stars,
        onlyWithComments: withComments,
        personas: fetchedPersonas,
        templates: fetchedTemplates,
        knowledgeGroups: fetchedGroups,
      );
    } catch (e) {
      debugPrint('⚠️ Error loading automation settings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings from backend',
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
          final id = (item['_id'] ?? item['id'] ?? item['persona_id'] ?? item['template_id'] ?? item['group_id'] ?? '').toString();
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
  void setTimingMode(String val) => state = state.copyWith(timingMode: val);
  void setIntervalHours(int val) => state = state.copyWith(intervalHours: val);
  void setScheduleHoursAhead(int val) => state = state.copyWith(scheduleHoursAhead: val);
  void setOptimalPostingTimes(String val) => state = state.copyWith(optimalPostingTimes: val);
  void setMaxArticles(int val) => state = state.copyWith(maxArticles: val);
  void setMaxPosts(int val) => state = state.copyWith(maxPosts: val);
  void setPersonaId(String? val) => state = state.copyWith(personaId: val);
  void setTemplateId(String? val) => state = state.copyWith(templateId: val);
  void setKnowledgeGroupId(String? val) => state = state.copyWith(knowledgeGroupId: val);
  void setGenerateImages(bool val) => state = state.copyWith(generateImages: val);
  void setImageStyle(String val) => state = state.copyWith(imageStyle: val);
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

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // 1. Save Post Automation Config to backend
      final configUri = Uri.parse('${ApiConfig.baseUrl}/api/automation/scheduler/config');
      final configBody = jsonEncode({
        "enabled": state.enabled,
        "timing_mode": state.timingMode,
        "interval_hours": state.intervalHours,
        "schedule_hours_ahead": state.scheduleHoursAhead,
        "optimal_posting_times": state.optimalPostingTimes,
        "max_articles": state.maxArticles,
        "max_posts": state.maxPosts,
        "persona_id": state.personaId,
        "template_id": state.templateId,
        "knowledge_group_id": state.knowledgeGroupId,
        "generate_images": state.generateImages,
        "image_style": state.imageStyle,
      });

      final configRes = await http.put(configUri, headers: headers, body: configBody).timeout(const Duration(seconds: 10));

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

        await http.put(replyUri, headers: headers, body: replyBody).timeout(const Duration(seconds: 10));
      }

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Automation configuration saved successfully!',
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
