import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_controller.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../dashboard/widgets/dashboard_header_bar.dart';
import '../notifications/notification_end_drawer.dart';
import '../shell/providers/shell_nav_provider.dart';
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

  Future<void> _selectCustomTime(BuildContext context, AutomationSettingsController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && context.mounted) {
      final localizations = MaterialLocalizations.of(context);
      final formatted = localizations.formatTimeOfDay(picked, alwaysUse24HourFormat: false);
      controller.addPostingSlot(formatted);
    }
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required Color textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
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
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isChecked
              ? (isDark ? const Color(0xFF312E81).withValues(alpha: 0.3) : const Color(0xFFEEF2FF))
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? const Color(0xFF4F46E5) : borderColor,
            width: isChecked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF4F46E5) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isChecked ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8)),
              ),
              child: isChecked
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: isChecked ? const Color(0xFF4F46E5) : textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isChecked ? textPrimary : textSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = ref.watch(authControllerProvider).valueOrNull;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'Buddy Individual';
    final userEmail = user?.email ?? '';
    final initial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U';

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF0B0F19)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4FF), Color(0xFFFAF8FF), Color(0xFFFFFFFF)],
            stops: [0.0, 0.35, 1.0],
          );

    if (!settings.isLoading && _jobNameController.text != settings.jobName) {
      _jobNameController.text = settings.jobName;
    }

    final body = settings.isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
        : RefreshIndicator(
            color: const Color(0xFF4F46E5),
            backgroundColor: cardBgColor,
            onRefresh: () async {
              final activeLoc = ref.read(activeLocationProvider).activeLocation;
              await controller.fetchSettings(
                locationId: activeLoc?.name,
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile & Connected Location Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (activeLocation != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.storefront_rounded, size: 13, color: Color(0xFF4F46E5)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        activeLocation.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF4F46E5),
                                        ),
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
                  const SizedBox(height: 14),

                  if (settings.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        settings.errorMessage!,
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],

                  if (settings.successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Text(
                        settings.successMessage!,
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF16A34A), fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],

                  // 1. GMB AUTO-PILOT EXECUTION STATUS CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    'Auto-Pilot Status',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: isDark ? Colors.white : const Color(0xFF14532D),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF86EFAC)),
                                    ),
                                    child: Text(
                                      settings.enabled ? '100% Active' : 'Paused',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF15803D),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                settings.enabled
                                    ? 'Auto-Pilot is ACTIVE. Posts will automatically generate & publish to Google.'
                                    : 'Auto-Pilot is PAUSED. Resume anytime to automate posting.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF166534),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: settings.enabled,
                          onChanged: controller.setEnabled,
                          activeThumbColor: const Color(0xFF16A34A),
                          activeTrackColor: const Color(0xFF86EFAC),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. AUTO-PILOT POSTING RULES & FORMATS
                  _buildSectionCard(
                    title: 'AUTO-PILOT POSTING RULES & FORMATS',
                    isDark: isDark,
                    cardBgColor: cardBgColor,
                    borderColor: borderColor,
                    textSecondary: textSecondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job Title & Frequency Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Job Title',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _jobNameController,
                                    onChanged: controller.setJobName,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'GMB Automation',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 12.5),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Frequency',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<int>(
                                    initialValue: settings.postsPerWeek,
                                    dropdownColor: cardBgColor,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
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

                        const SizedBox(height: 18),

                        // LOCAL SEARCH PEAK SCHEDULE TIMES
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF4F46E5)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Peak Search Schedule Times',
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: textPrimary),
                                        ),
                                        Text(
                                          'Times when local customers search on Google Maps.',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Quick Preset Strategy Slots
                              Text(
                                'PRESET STRATEGY SLOTS',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildPresetSlotButton(
                                    icon: Icons.auto_awesome_rounded,
                                    label: 'Recommended Peak',
                                    onTap: () => controller.setPostingSlots(['9:00 AM', '1:00 PM', '5:00 PM']),
                                    isDark: isDark,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                  ),
                                  _buildPresetSlotButton(
                                    icon: Icons.wb_sunny_rounded,
                                    label: 'Business Hours',
                                    onTap: () => controller.setPostingSlots(['10:00 AM', '1:00 PM', '4:00 PM']),
                                    isDark: isDark,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                  ),
                                  _buildPresetSlotButton(
                                    icon: Icons.nightlight_round,
                                    label: 'Evening Demand',
                                    onTap: () => controller.setPostingSlots(['6:00 PM', '8:00 PM', '9:00 PM']),
                                    isDark: isDark,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Selected Posting Slots List
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SELECTED SLOTS (${settings.postingSlots.length})',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _selectCustomTime(context, controller),
                                    child: Text(
                                      '+ Custom Time',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF4F46E5)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              settings.postingSlots.isEmpty
                                  ? Text(
                                      'No posting slots selected. Add slots below.',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                                    )
                                  : Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: settings.postingSlots.map((slot) {
                                        return Container(
                                          padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: borderColor),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF4F46E5)),
                                              const SizedBox(width: 5),
                                              Text(slot, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: textPrimary)),
                                              const SizedBox(width: 2),
                                              GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: () => controller.removePostingSlot(slot),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(3.0),
                                                  child: Icon(Icons.close_rounded, size: 13, color: textSecondary),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),

                              const SizedBox(height: 12),
                              Text(
                                'ADD QUICK LOCAL PEAK SLOT:',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 5,
                                runSpacing: 5,
                                children: ['8:00 AM', '9:00 AM', '10:00 AM', '12:00 PM', '1:00 PM', '3:00 PM', '5:00 PM', '7:00 PM', '8:00 PM'].map((slotText) {
                                  final isAlreadyAdded = settings.postingSlots.contains(slotText);
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: isAlreadyAdded ? null : () => controller.addPostingSlot(slotText),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isAlreadyAdded
                                            ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isAlreadyAdded ? Colors.transparent : borderColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isAlreadyAdded ? Icons.check_rounded : Icons.add_rounded,
                                            size: 12,
                                            color: isAlreadyAdded ? textSecondary : const Color(0xFF4F46E5),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            slotText,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: isAlreadyAdded ? textSecondary : textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // AI Persona & Voice Dropdown
                        Text(
                          'AI Persona & Voice',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: settings.personas.any((p) => p['id'] == settings.personaId) ? settings.personaId : 'socialhive',
                          dropdownColor: cardBgColor,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                          ),
                          items: settings.personas.map((p) {
                            return DropdownMenuItem<String>(
                              value: p['id'],
                              child: Text(p['name']!, style: GoogleFonts.plusJakartaSans(fontSize: 13), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: controller.setPersonaId,
                        ),

                        const SizedBox(height: 14),

                        // Knowledge Base Group Dropdown
                        Text(
                          'Knowledge Base Group',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: settings.knowledgeGroups.any((k) => k['id'] == settings.knowledgeGroupId) ? settings.knowledgeGroupId : 'SocialHive Official Group',
                          dropdownColor: cardBgColor,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
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
                    isDark: isDark,
                    cardBgColor: cardBgColor,
                    borderColor: borderColor,
                    textSecondary: textSecondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormatCheckboxTile(
                          label: 'AI Motion Video Reels',
                          formatKey: 'video_reels',
                          icon: Icons.videocam_rounded,
                          isChecked: settings.allowedFormats.contains('video_reels') || settings.allowedFormats.contains('VIDEO'),
                          onTap: () => controller.toggleAllowedFormat('video_reels'),
                          isDark: isDark,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 8),
                        _buildFormatCheckboxTile(
                          label: 'Branded Images & Graphics',
                          formatKey: 'branded_images',
                          icon: Icons.image_rounded,
                          isChecked: settings.allowedFormats.contains('branded_images') || settings.allowedFormats.contains('TEXT_IMAGE'),
                          onTap: () => controller.toggleAllowedFormat('branded_images'),
                          isDark: isDark,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 8),
                        _buildFormatCheckboxTile(
                          label: 'Promotional Offers & Deals',
                          formatKey: 'promotional_offers',
                          icon: Icons.local_offer_rounded,
                          isChecked: settings.allowedFormats.contains('promotional_offers') || settings.allowedFormats.contains('OFFER'),
                          onTap: () => controller.toggleAllowedFormat('promotional_offers'),
                          isDark: isDark,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 8),
                        _buildFormatCheckboxTile(
                          label: 'Events & Announcements',
                          formatKey: 'events_announcements',
                          icon: Icons.event_rounded,
                          isChecked: settings.allowedFormats.contains('events_announcements') || settings.allowedFormats.contains('EVENT'),
                          onTap: () => controller.toggleAllowedFormat('events_announcements'),
                          isDark: isDark,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 8),
                        _buildFormatCheckboxTile(
                          label: 'Product Spotlights',
                          formatKey: 'product_spotlights',
                          icon: Icons.shopping_bag_rounded,
                          isChecked: settings.allowedFormats.contains('product_spotlights') || settings.allowedFormats.contains('PRODUCT'),
                          onTap: () => controller.toggleAllowedFormat('product_spotlights'),
                          isDark: isDark,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 8),
                        _buildFormatCheckboxTile(
                          label: 'Service Highlights',
                          formatKey: 'service_highlights',
                          icon: Icons.build_rounded,
                          isChecked: settings.allowedFormats.contains('service_highlights') || settings.allowedFormats.contains('SERVICE'),
                          onTap: () => controller.toggleAllowedFormat('service_highlights'),
                          isDark: isDark,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        const SizedBox(height: 8),
                        _buildFormatCheckboxTile(
                          label: 'Quick Tips & Text Updates',
                          formatKey: 'quick_tips',
                          icon: Icons.article_rounded,
                          isChecked: settings.allowedFormats.contains('quick_tips') || settings.allowedFormats.contains('TEXT_ONLY'),
                          onTap: () => controller.toggleAllowedFormat('quick_tips'),
                          isDark: isDark,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SAVE BUTTON (48px Fixed Height)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        settings.isSaving ? 'Saving Auto-Pilot Rules...' : 'Save & Update GMB Auto-Pilot',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                child: DashboardHeaderBar(
                  title: 'Auto-Pilot Hub',
                  subtitle: activeLocation?.name ?? 'Automation Rules',
                  showSparkle: true,
                  showBackButton: widget.showScaffold,
                  onBack: () {
                    if (widget.showScaffold) {
                      Navigator.of(context).maybePop();
                    } else {
                      ref.handleSmartBack(context);
                    }
                  },
                  onOpenNotifications: () {
                    Scaffold.maybeOf(context)?.openEndDrawer();
                  },
                ),
              ),
              const SizedBox(height: 6),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetSlotButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
    required Color textPrimary,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
