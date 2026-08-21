import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/gmb_blueprint_repository.dart';
import '../../business_flow/providers/active_location_provider.dart';
import '../../dashboard/widgets/dashboard_header_bar.dart';
import '../../notifications/notification_end_drawer.dart';
import '../../shell/providers/shell_nav_provider.dart';
import 'widgets/blueprint_config_modal.dart';
import 'widgets/blueprint_signals_panel.dart';
import 'widgets/edit_concept_modal.dart';

class BlueprintPlannerScreen extends ConsumerStatefulWidget {
  const BlueprintPlannerScreen({super.key});

  @override
  ConsumerState<BlueprintPlannerScreen> createState() => _BlueprintPlannerScreenState();
}

class _BlueprintPlannerScreenState extends ConsumerState<BlueprintPlannerScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _selectedFormat;
  GMBBlueprint? _blueprint;

  final List<String> _formats = [
    'ALL',
    'VIDEO',
    'TEXT_IMAGE',
    'OFFER',
    'EVENT',
    'PRODUCT',
    'SERVICE',
    'TEXT_ONLY',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBlueprint());
  }

  Future<void> _loadBlueprint() async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(gmbBlueprintRepositoryProvider);
      final bp = await repo.getBlueprint(activeLocation.id);
      if (mounted) {
        setState(() {
          _blueprint = bp;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showConfigModal() {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlueprintConfigModal(
        planDays: _blueprint?.planDays ?? 30,
        isGenerating: _isGenerating,
        onGenerateLocation: (postsPerWeek, selectedFormats, autoSchedule) {
          _generateBlueprint(postsPerWeek, selectedFormats, autoSchedule);
        },
        onGenerateWebsite: (profilerInputs) {
          _generateBlueprintFromWebsite(profilerInputs);
        },
      ),
    );
  }

  Future<void> _generateBlueprint(
    int postsPerWeek,
    List<String> selectedFormats,
    bool autoSchedule,
  ) async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    setState(() => _isGenerating = true);
    try {
      final repo = ref.read(gmbBlueprintRepositoryProvider);
      final res = await repo.generateBlueprint(
        locationId: activeLocation.id,
        postsPerWeek: postsPerWeek,
        allowedFormats: selectedFormats,
        autoSchedule: autoSchedule,
      );
      if (mounted) {
        setState(() {
          _blueprint = res;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Generated ${res.totalItems} content concepts!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        ref.invalidate(blueprintTriggersProvider(activeLocation.id));
        ref.invalidate(blueprintLearningProvider(activeLocation.id));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  Future<void> _generateBlueprintFromWebsite(Map<String, String> profilerInputs) async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    setState(() => _isGenerating = true);
    try {
      final repo = ref.read(gmbBlueprintRepositoryProvider);
      final res = await repo.generateBlueprint(
        locationId: activeLocation.id,
        postsPerWeek: 5,
        allowedFormats: _formats.where((f) => f != 'ALL').toList(),
        autoSchedule: false,
      );

      if (mounted) {
        setState(() {
          _blueprint = res;
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Generated website-tailored blueprint with ${res.totalItems} concepts!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  void _openEditConceptModal(GMBBlueprintItem item) {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditConceptModal(
        item: item,
        locationId: activeLocation.id,
        repository: ref.read(gmbBlueprintRepositoryProvider),
        onSaved: _loadBlueprint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLocation = ref.watch(activeLocationProvider).activeLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Design System Tokens
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

    final items = _blueprint?.items ?? [];
    final filteredItems = (_selectedFormat == null || _selectedFormat == 'ALL')
        ? items
        : items.where((i) => i.format.toUpperCase() == _selectedFormat).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Standard Unified DashboardHeaderBar
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                child: DashboardHeaderBar(
                  title: 'Content Strategy Blueprint',
                  subtitle: activeLocation?.name ?? 'SocialHive',
                  showSparkle: true,
                  showBackButton: true,
                  onBack: () => ref.handleSmartBack(context),
                  onOpenNotifications: () {
                    Scaffold.maybeOf(context)?.openEndDrawer();
                  },
                ),
              ),
              const SizedBox(height: 6),

              // 2. Main Body Content
              Expanded(
                child: _isLoading || _isGenerating
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFF4F46E5)),
                            const SizedBox(height: 16),
                            Text(
                              _isGenerating
                                  ? 'AI is crafting your 30-day strategy...'
                                  : 'Loading content blueprint...',
                              style: GoogleFonts.plusJakartaSans(
                                color: textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : items.isEmpty
                        ? _buildEmptyState(isDark, cardBgColor, borderColor, textPrimary, textSecondary)
                        : RefreshIndicator(
                            color: const Color(0xFF4F46E5),
                            onRefresh: _loadBlueprint,
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 30),
                              children: [
                                // Top Hero Strategy Banner
                                _buildHeaderStats(),

                                // Live Signals & Posting Triggers Panel
                                const BlueprintSignalsPanel(),

                                // Horizontal Format Filter Pills
                                _buildFormatFilterBar(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                                const SizedBox(height: 10),

                                // Cards List
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredItems.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      return _buildBlueprintCard(
                                        filteredItems[index],
                                        isDark,
                                        cardBgColor,
                                        borderColor,
                                        textPrimary,
                                        textSecondary,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    final total = _blueprint?.totalItems ?? 0;
    final planDays = _blueprint?.planDays ?? 30;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$planDays-Day Content Plan',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total AI-optimized concepts ready for publishing',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            icon: const Icon(Icons.settings_suggest_rounded, size: 16),
            label: Text(
              'Re-plan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            onPressed: _showConfigModal,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatFilterBar(
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: _formats.map((fmt) {
          final isSelected = (_selectedFormat == null && fmt == 'ALL') || _selectedFormat == fmt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFormat = fmt == 'ALL' ? null : fmt);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5) : cardBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF4F46E5) : borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF4F46E5).withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                      blurRadius: isSelected ? 6 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      fmt.replaceAll('_', ' '),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBlueprintCard(
    GMBBlueprintItem item,
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openEditConceptModal(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE)),
                    ),
                    child: Text(
                      'DAY ${item.dayNumber}',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF4F46E5),
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      item.format.replaceAll('_', ' '),
                      style: GoogleFonts.plusJakartaSans(
                        color: textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      'CTA: ${item.ctaType.replaceAll('_', ' ')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item.costCredits} Credits',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
                ],
              ),
              const SizedBox(height: 8),

              // Title (Single line, prominent)
              Text(
                item.title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Caption Preview (1 line snippet)
              Text(
                item.caption,
                style: GoogleFonts.plusJakartaSans(
                  color: textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 32, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(height: 18),
              Text(
                'No Strategy Blueprint Yet',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate an AI-powered 30-day posting strategy tailored to your Google business category and local audience.',
                style: GoogleFonts.plusJakartaSans(
                  color: textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(
                  'Generate Strategy Blueprint',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                onPressed: _showConfigModal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
