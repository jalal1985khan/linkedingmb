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
  final _jobNameController = TextEditingController();

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
  void dispose() {
    _jobNameController.dispose();
    super.dispose();
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ],
    );
  }

  Widget _buildFormatCheckboxTile({
    required String label,
    required String formatKey,
    required IconData icon,
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isChecked ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: isChecked ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isChecked ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: isChecked ? AppColors.primaryContainer : const Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isChecked ? const Color(0xFF0F172A) : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

    if (!settings.isLoading && _jobNameController.text != settings.jobName) {
      _jobNameController.text = settings.jobName;
    }

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

                  // 1. GMB AUTO-PILOT EXECUTION STATUS CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'GMB Auto-Pilot Status',
                                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF14532D)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF86EFAC)),
                                    ),
                                    child: Text(
                                      settings.enabled ? '100% Active' : 'Paused',
                                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                settings.enabled
                                    ? 'Auto-Pilot is ACTIVE. Posts will automatically generate & publish to Google.'
                                    : 'Auto-Pilot is PAUSED.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: settings.enabled,
                          onChanged: controller.setEnabled,
                          activeThumbColor: const Color(0xFF16A34A),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. AUTO-PILOT POSTING RULES & FORMATS
                  _buildSectionCard(
                    title: 'AUTO-PILOT POSTING RULES & FORMATS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job Title & Frequency Row
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Automation Job Title', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _jobNameController,
                                    onChanged: controller.setJobName,
                                    decoration: InputDecoration(
                                      hintText: 'GMB Automation',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Weekly Frequency', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF475569))),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<int>(
                                    initialValue: settings.postsPerWeek,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                    items: [1, 2, 3, 5, 7].map((freq) {
                                      return DropdownMenuItem<int>(
                                        value: freq,
                                        child: Text('$freq / wk', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) controller.setPostsPerWeek(val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Local Search Peak Schedule Times Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 18, color: AppColors.primaryContainer),
                                  const SizedBox(width: 8),
                                  Text('Local Search Peak Schedule Times', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('Times when local customers search for services on Google Maps.', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                              const SizedBox(height: 12),

                              Text('SELECTED POSTING SLOTS (${settings.postingSlots.length})', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8))),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: settings.postingSlots.map((slot) {
                                  return Chip(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    avatar: const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primaryContainer),
                                    label: Text(slot, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                                    deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF64748B)),
                                    onDeleted: () => controller.removePostingSlot(slot),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 12),
                              Text('Add Quick Local Peak Slot:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: ['+ 8:00 AM', '+ 9:00 AM', '+ 10:00 AM', '+ 12:00 PM', '+ 1:00 PM', '+ 3:00 PM', '+ 5:00 PM', '+ 7:00 PM'].map((slotText) {
                                  final cleanSlot = slotText.replaceAll('+ ', '');
                                  final isAlreadyAdded = settings.postingSlots.contains(cleanSlot);
                                  return ActionChip(
                                    label: Text(slotText, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
                                    backgroundColor: isAlreadyAdded ? const Color(0xFFE2E8F0) : Colors.white,
                                    onPressed: isAlreadyAdded ? null : () => controller.addPostingSlot(cleanSlot),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // AI Persona & Voice Dropdown
                        Text('AI Persona & Voice', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF475569))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: settings.personas.any((p) => p['id'] == settings.personaId) ? settings.personaId : 'socialhive',
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          items: settings.personas.map((p) {
                            return DropdownMenuItem<String>(
                              value: p['id'],
                              child: Text(p['name']!, style: GoogleFonts.plusJakartaSans(fontSize: 13), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: controller.setPersonaId,
                        ),

                        const SizedBox(height: 16),

                        // Knowledge Base Group Dropdown
                        Text('Knowledge Base Group', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF475569))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: settings.knowledgeGroups.any((k) => k['id'] == settings.knowledgeGroupId) ? settings.knowledgeGroupId : 'SocialHive Official Group',
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          items: settings.knowledgeGroups.map((k) {
                            return DropdownMenuItem<String>(
                              value: k['id'],
                              child: Text(k['name']!, style: GoogleFonts.plusJakartaSans(fontSize: 13), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: controller.setKnowledgeGroupId,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. ALLOWED GMB CONTENT FORMATS CARD
                  _buildSectionCard(
                    title: 'ALLOWED GMB CONTENT FORMATS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormatCheckboxTile(
                          label: 'AI Motion Video Reels',
                          formatKey: 'video_reels',
                          icon: Icons.videocam_outlined,
                          isChecked: settings.allowedFormats.contains('video_reels'),
                          onTap: () => controller.toggleAllowedFormat('video_reels'),
                        ),
                        const SizedBox(height: 10),
                        _buildFormatCheckboxTile(
                          label: 'Branded Images & Graphics',
                          formatKey: 'branded_images',
                          icon: Icons.image_outlined,
                          isChecked: settings.allowedFormats.contains('branded_images'),
                          onTap: () => controller.toggleAllowedFormat('branded_images'),
                        ),
                        const SizedBox(height: 10),
                        _buildFormatCheckboxTile(
                          label: 'Promotional Offers & Deals',
                          formatKey: 'promotional_offers',
                          icon: Icons.local_offer_outlined,
                          isChecked: settings.allowedFormats.contains('promotional_offers'),
                          onTap: () => controller.toggleAllowedFormat('promotional_offers'),
                        ),
                        const SizedBox(height: 10),
                        _buildFormatCheckboxTile(
                          label: 'Events & Announcements',
                          formatKey: 'events_announcements',
                          icon: Icons.event_outlined,
                          isChecked: settings.allowedFormats.contains('events_announcements'),
                          onTap: () => controller.toggleAllowedFormat('events_announcements'),
                        ),
                        const SizedBox(height: 10),
                        _buildFormatCheckboxTile(
                          label: 'Product Spotlights',
                          formatKey: 'product_spotlights',
                          icon: Icons.shopping_bag_outlined,
                          isChecked: settings.allowedFormats.contains('product_spotlights'),
                          onTap: () => controller.toggleAllowedFormat('product_spotlights'),
                        ),
                        const SizedBox(height: 10),
                        _buildFormatCheckboxTile(
                          label: 'Service Highlights',
                          formatKey: 'service_highlights',
                          icon: Icons.build_outlined,
                          isChecked: settings.allowedFormats.contains('service_highlights'),
                          onTap: () => controller.toggleAllowedFormat('service_highlights'),
                        ),
                        const SizedBox(height: 10),
                        _buildFormatCheckboxTile(
                          label: 'Quick Tips & Text Updates',
                          formatKey: 'quick_tips',
                          icon: Icons.article_outlined,
                          isChecked: settings.allowedFormats.contains('quick_tips'),
                          onTap: () => controller.toggleAllowedFormat('quick_tips'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. CUSTOMER REVIEWS AUTO-REPLY CARD
                  _buildSectionCard(
                    title: 'CUSTOMER REVIEWS AUTO-REPLY',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Auto-Reply to Reviews', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('AI drafts & publishes replies after 1h grace period', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Switch(
                              value: settings.autoReviewReply,
                              onChanged: controller.setAutoReviewReply,
                              activeThumbColor: AppColors.primaryContainer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Minimum Star Rating', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text('Only auto-reply to reviews >= min stars', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                                ],
                              ),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
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
                                    content: Text('✨ GMB Auto-Pilot Configuration updated & synced live!'),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                      icon: settings.isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome_rounded, size: 20),
                      label: Text(
                        settings.isSaving ? 'Saving Auto-Pilot Rules...' : 'Save & Update GMB Auto-Pilot',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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
        title: Text('GMB Auto-Pilot Hub', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1E1B4B), fontWeight: FontWeight.w700, fontSize: 18)),
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
