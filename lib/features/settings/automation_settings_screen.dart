import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'automation_settings_controller.dart';
import '../auth/auth_controller.dart';

class AutomationSettingsScreen extends ConsumerStatefulWidget {
  const AutomationSettingsScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  @override
  ConsumerState<AutomationSettingsScreen> createState() => _AutomationSettingsScreenState();
}

class _AutomationSettingsScreenState extends ConsumerState<AutomationSettingsScreen> {
  double _personalizationLevel = 0.8;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(automationSettingsProvider);
    final controller = ref.read(automationSettingsProvider.notifier);

    final body = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/user_avatar.jpg'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sarah Jenkins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('CEO, Nexus Dynamics', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Edit', style: TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Settings Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryContainer, width: 1),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryContainer.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.campaign_outlined, color: AppColors.primaryContainer, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Automatic Posting', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Let AI handle your social presence', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                        Switch(
                          value: settings.autoSchedulePosts,
                          onChanged: controller.setAutoSchedulePosts,
                          activeColor: AppColors.primaryContainer,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.psychology_outlined, color: AppColors.primaryContainer, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Personalization Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text('Adjust the creative tone of AI output', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.primaryContainer.withOpacity(0.3),
                            inactiveTrackColor: AppColors.surfaceContainer,
                            thumbColor: AppColors.primaryContainer,
                            overlayColor: AppColors.primaryContainer.withOpacity(0.2),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _personalizationLevel,
                            onChanged: (val) => setState(() => _personalizationLevel = val),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Conservative', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const Text('Creative', style: TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_graph_rounded, color: AppColors.primaryContainer, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Smart Recommendations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Automated daily business tips', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                        Switch(
                          value: settings.autoApplyRecommendations,
                          onChanged: controller.setAutoApplyRecommendations,
                          activeColor: AppColors.primaryContainer,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.dns_outlined, color: AppColors.primaryContainer, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AI Training Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Manage learning history & sources', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Settings
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildListTile(Icons.notifications_none_rounded, 'Notifications'),
                  const Divider(height: 1),
                  _buildListTile(Icons.shield_outlined, 'Privacy'),
                  const Divider(height: 1),
                  _buildListTile(Icons.lock_outline_rounded, 'Security'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('SUPPORT', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, letterSpacing: 1)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildListTile(Icons.help_outline_rounded, 'Help & Support'),
                  const Divider(height: 1),
                  _buildListTile(Icons.info_outline_rounded, 'About AI Suite'),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A)),
                    title: const Text('Logout', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(authControllerProvider.notifier).signOut();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Footer
            Center(
              child: Column(
                children: [
                  Text('AI SUITE', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('v 2.4.0 (Enterprise)', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );

    if (!widget.showScaffold) {
      return Scaffold(backgroundColor: AppColors.background, body: body);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildListTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
      onTap: () {},
    );
  }
}
