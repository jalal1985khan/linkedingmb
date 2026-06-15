import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'automation_settings_controller.dart';

class AutomationSettingsScreen extends ConsumerWidget {
  const AutomationSettingsScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(automationSettingsProvider);
    final controller = ref.read(automationSettingsProvider.notifier);

    final body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Control how much your AI assistant can execute automatically.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-apply AI recommendations'),
            subtitle: const Text('Apply selected profile and strategy improvements'),
            value: settings.autoApplyRecommendations,
            onChanged: controller.setAutoApplyRecommendations,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-schedule generated posts'),
            subtitle: const Text('Queue AI generated posts based on preferred frequency'),
            value: settings.autoSchedulePosts,
            onChanged: controller.setAutoSchedulePosts,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Require manual approval'),
            subtitle: const Text('Require confirmation before any publish action'),
            value: settings.requireManualApproval,
            onChanged: controller.setRequireManualApproval,
          ),
        ],
      );

    if (!showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Automation Settings')),
      body: body,
    );
  }
}
