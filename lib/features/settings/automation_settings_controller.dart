import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutomationSettings {
  const AutomationSettings({
    this.autoApplyRecommendations = false,
    this.autoSchedulePosts = false,
    this.requireManualApproval = true,
  });

  final bool autoApplyRecommendations;
  final bool autoSchedulePosts;
  final bool requireManualApproval;

  AutomationSettings copyWith({
    bool? autoApplyRecommendations,
    bool? autoSchedulePosts,
    bool? requireManualApproval,
  }) {
    return AutomationSettings(
      autoApplyRecommendations:
          autoApplyRecommendations ?? this.autoApplyRecommendations,
      autoSchedulePosts: autoSchedulePosts ?? this.autoSchedulePosts,
      requireManualApproval: requireManualApproval ?? this.requireManualApproval,
    );
  }
}

class AutomationSettingsController extends StateNotifier<AutomationSettings> {
  AutomationSettingsController() : super(const AutomationSettings());

  void setAutoApplyRecommendations(bool value) {
    state = state.copyWith(autoApplyRecommendations: value);
  }

  void setAutoSchedulePosts(bool value) {
    state = state.copyWith(autoSchedulePosts: value);
  }

  void setRequireManualApproval(bool value) {
    state = state.copyWith(requireManualApproval: value);
  }
}

final automationSettingsProvider =
    StateNotifierProvider<AutomationSettingsController, AutomationSettings>(
  (ref) => AutomationSettingsController(),
);
