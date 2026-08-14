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

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
                        Switch(
                          value: settings.enabled,
                          onChanged: controller.setEnabled,
                          activeThumbColor: AppColors.primaryContainer,
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

                  // 1. SCHEDULE & TIMING CARD
                  _buildSectionCard(
                    title: 'SCHEDULE & TIMING',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: Text('Interval Mode', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                                selected: settings.timingMode == 'interval',
                                selectedColor: const Color(0xFFEEF2FF),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: settings.timingMode == 'interval' ? AppColors.primaryContainer : const Color(0xFF64748B),
                                ),
                                onSelected: (_) => controller.setTimingMode('interval'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: Text('Specific Times', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                                selected: settings.timingMode == 'specific',
                                selectedColor: const Color(0xFFEEF2FF),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: settings.timingMode == 'specific' ? AppColors.primaryContainer : const Color(0xFF64748B),
                                ),
                                onSelected: (_) => controller.setTimingMode('specific'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        if (settings.timingMode == 'interval') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Run Interval', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF475569))),
                              Text('Every ${settings.intervalHours}h', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryContainer)),
                            ],
                          ),
                          Slider(
                            value: settings.intervalHours.toDouble(),
                            min: 1,
                            max: 72,
                            divisions: 71,
                            activeColor: AppColors.primaryContainer,
                            onChanged: (val) => controller.setIntervalHours(val.toInt()),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Schedule Ahead', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF475569))),
                              Text('${settings.scheduleHoursAhead}h ahead', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryContainer)),
                            ],
                          ),
                          Slider(
                            value: settings.scheduleHoursAhead.toDouble(),
                            min: 1,
                            max: 72,
                            divisions: 71,
                            activeColor: AppColors.primaryContainer,
                            onChanged: (val) => controller.setScheduleHoursAhead(val.toInt()),
                          ),
                        ] else ...[
                          Text('Optimal Posting Times (comma separated)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: settings.optimalPostingTimes,
                            onChanged: controller.setOptimalPostingTimes,
                            decoration: InputDecoration(
                              hintText: 'e.g. 09:00, 13:00, 17:00',
                              filled: true,
                              fillColor: const Color(0xFFF8F7FF),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. CONTENT STRATEGY CARD
                  _buildSectionCard(
                    title: 'CONTENT STRATEGY',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Articles', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<int>(
                                    initialValue: settings.maxArticles,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8F7FF),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                    items: [1, 2, 3, 5, 10].map((val) {
                                      return DropdownMenuItem<int>(
                                        value: val,
                                        child: Text('$val article${val > 1 ? 's' : ''}', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) controller.setMaxArticles(val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Posts', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<int>(
                                    initialValue: settings.maxPosts,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8F7FF),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                    items: [1, 2, 3, 5].map((val) {
                                      return DropdownMenuItem<int>(
                                        value: val,
                                        child: Text('$val post${val > 1 ? 's' : ''}', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) controller.setMaxPosts(val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Persona Selector
                        Text('Persona', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: settings.personas.any((p) => p['id'] == settings.personaId) ? settings.personaId : null,
                          decoration: InputDecoration(
                            hintText: 'Select Persona',
                            filled: true,
                            fillColor: const Color(0xFFF8F7FF),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

                        // Template Selector
                        Text('Template', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: settings.templates.any((t) => t['id'] == settings.templateId) ? settings.templateId : null,
                          decoration: InputDecoration(
                            hintText: 'Default New Template',
                            filled: true,
                            fillColor: const Color(0xFFF8F7FF),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          items: settings.templates.map((t) {
                            return DropdownMenuItem<String>(
                              value: t['id'],
                              child: Text(t['name']!, style: GoogleFonts.plusJakartaSans(fontSize: 13), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: controller.setTemplateId,
                        ),
                        const SizedBox(height: 16),

                        // Knowledge Group Selector
                        Text('Knowledge Group', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: settings.knowledgeGroups.any((k) => k['id'] == settings.knowledgeGroupId) ? settings.knowledgeGroupId : null,
                          decoration: InputDecoration(
                            hintText: 'Select RSS / Knowledge Group',
                            filled: true,
                            fillColor: const Color(0xFFF8F7FF),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

                  // 3. VISUALS CARD
                  _buildSectionCard(
                    title: 'VISUALS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Generate Images', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text('Automatically create AI graphics for each post.', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                              ],
                            ),
                            Switch(
                              value: settings.generateImages,
                              onChanged: controller.setGenerateImages,
                              activeThumbColor: AppColors.primaryContainer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Image Style', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: ['professional', 'modern', 'vibrant', 'minimalist', 'realistic'].contains(settings.imageStyle.toLowerCase())
                              ? settings.imageStyle.toLowerCase()
                              : 'professional',
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8F7FF),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          items: ['professional', 'modern', 'vibrant', 'minimalist', 'realistic'].map((st) {
                            return DropdownMenuItem<String>(
                              value: st,
                              child: Text(st[0].toUpperCase() + st.substring(1), style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.setImageStyle(val);
                          },
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Auto-Reply to Reviews', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text('AI drafts & publishes replies after 1h grace period', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                              ],
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Minimum Star Rating', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('Only auto-reply to reviews >= min stars', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
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
                                    content: Text('✅ Automation configuration saved to backend MongoDB!'),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                      icon: settings.isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        settings.isSaving ? 'Saving to Backend...' : 'Save Automation Config',
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
        title: Text('Automation Config', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1E1B4B), fontWeight: FontWeight.w700, fontSize: 18)),
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
