import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../auth/auth_controller.dart';
import '../business_flow/providers/active_location_provider.dart';
import 'automation_settings_controller.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeLocation = ref.read(activeLocationProvider).activeLocation;
      ref.read(automationSettingsProvider.notifier).fetchSettings(
            locationId: activeLocation?.name,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(automationSettingsProvider);
    final controller = ref.read(automationSettingsProvider.notifier);
    final activeLocation = ref.watch(activeLocationProvider).activeLocation;

    final user = ref.watch(authControllerProvider).valueOrNull;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'GMB Account';
    final userEmail = user?.email ?? '';
    final initial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U';

    final body = SafeArea(
      child: settings.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile & Connected Location Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.15),
                          child: Text(
                            initial,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(userEmail, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (activeLocation != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.storefront_rounded, size: 12, color: AppColors.primaryContainer),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        activeLocation.name,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryContainer),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (settings.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        settings.errorMessage!,
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF991B1B), fontSize: 13),
                      ),
                    ),
                  ],

                  if (settings.successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Text(
                        settings.successMessage!,
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF166534), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],

                  // AI POST AUTOMATION CARD
                  Text(
                    'CONTENT AUTOMATION',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: settings.enabled,
                          onChanged: controller.setEnabled,
                          activeThumbColor: AppColors.primaryContainer,
                          title: Text('Automatic AI Post Generation', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('Generate and schedule localized GMB posts automatically', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: settings.generateImages,
                          onChanged: controller.setGenerateImages,
                          activeThumbColor: AppColors.primaryContainer,
                          title: Text('Generate AI Images & Graphics', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('Create visual assets for every scheduled GMB post', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Image & Creative Style', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: ['professional', 'modern', 'vibrant', 'minimalist'].map((st) {
                                  final selected = settings.imageStyle.toLowerCase() == st;
                                  return ChoiceChip(
                                    label: Text(st[0].toUpperCase() + st.substring(1)),
                                    selected: selected,
                                    selectedColor: AppColors.primaryContainer,
                                    labelStyle: GoogleFonts.plusJakartaSans(
                                      color: selected ? Colors.white : const Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    onSelected: (_) => controller.setImageStyle(st),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CUSTOMER REVIEWS AUTO-REPLY CARD
                  Text(
                    'CUSTOMER REVIEWS AUTO-REPLY',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: settings.autoReviewReply,
                          onChanged: controller.setAutoReviewReply,
                          activeThumbColor: AppColors.primaryContainer,
                          title: Text('Auto-Reply to Customer Reviews', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('AI draft & auto-publishes replies after 1h grace period', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Minimum Star Rating', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('Only auto-reply to reviews >= min stars', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                                ],
                              ),
                              DropdownButton<int>(
                                value: settings.minStars,
                                items: [1, 2, 3, 4, 5].map((s) {
                                  return DropdownMenuItem<int>(
                                    value: s,
                                    child: Text('$s ★', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) controller.setMinStars(v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: settings.onlyWithComments,
                          onChanged: controller.setOnlyWithComments,
                          activeThumbColor: AppColors.primaryContainer,
                          title: Text('Only Reply With Comments', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('Ignore star-only reviews without text feedback', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: settings.isSaving
                          ? null
                          : () async {
                              final success = await controller.saveSettings(
                                locationId: activeLocation?.name,
                              );
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Automation settings updated on backend MongoDB!'),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                      icon: settings.isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        settings.isSaving ? 'Saving to Backend...' : 'Save Automation Settings',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );

    if (!widget.showScaffold) {
      return Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: body);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E1B4B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Automation Settings', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1E1B4B), fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: body,
    );
  }
}
