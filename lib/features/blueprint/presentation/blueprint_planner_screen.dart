import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/gmb_blueprint_repository.dart';
import '../../business_flow/providers/active_location_provider.dart';
import '../../dashboard/widgets/dashboard_header_bar.dart';
import '../../notifications/notification_end_drawer.dart';
import '../../shell/providers/shell_nav_provider.dart';

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

  Future<void> _showGenerateDialog() async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    int postsPerWeek = 5;
    bool autoSchedule = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Generate Blueprint',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI will analyze your local category, reviews, and search keywords to craft a 30-day content calendar.',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Text(
                'Posting Frequency',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: postsPerWeek,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: [3, 5, 7].map((p) => DropdownMenuItem(value: p, child: Text('$p posts / week', style: GoogleFonts.plusJakartaSans()))).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => postsPerWeek = v);
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Auto-schedule to Post Queue',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Automatically push generated posts into the scheduler calendar.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                value: autoSchedule,
                onChanged: (v) => setDialogState(() => autoSchedule = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 0,
              ),
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text('Generate Strategy', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
              onPressed: () {
                Navigator.pop(ctx);
                _generateBlueprint(postsPerWeek, autoSchedule);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateBlueprint(int postsPerWeek, bool autoSchedule) async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    setState(() => _isGenerating = true);
    try {
      final repo = ref.read(gmbBlueprintRepositoryProvider);
      final res = await repo.generateBlueprint(
        locationId: activeLocation.id,
        postsPerWeek: postsPerWeek,
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

  Future<void> _improviseItem(GMBBlueprintItem item) async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✨ AI is improvising a fresh angle for this post...')),
    );

    try {
      final repo = ref.read(gmbBlueprintRepositoryProvider);
      final updated = await repo.improviseBlueprintItem(
        locationId: activeLocation.id,
        itemId: item.id,
      );

      if (updated != null && mounted) {
        _loadBlueprint();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ Concept improvised!'), backgroundColor: Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
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
                            child: Column(
                              children: [
                                // Top Hero Strategy Banner
                                _buildHeaderStats(),

                                // Horizontal Format Filter Pills
                                _buildFormatFilterBar(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                                const SizedBox(height: 6),

                                // Cards List
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
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
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text(
              'Re-plan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            onPressed: _showGenerateDialog,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE)),
                ),
                child: Text(
                  'DAY ${item.dayNumber}',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF4F46E5),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  item.format.replaceAll('_', ' '),
                  style: GoogleFonts.plusJakartaSans(
                    color: textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF4F46E5)),
                onPressed: () => _improviseItem(item),
                tooltip: 'Improvise with AI',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Headline Title
          Text(
            item.title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Caption Preview
          Text(
            item.caption,
            style: GoogleFonts.plusJakartaSans(
              color: textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // Visual Prompt Concept Box
          if (item.mediaConcept.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, size: 16, color: textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Visual: ${item.mediaConcept}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
                  'Generate 30-Day Plan',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                onPressed: _showGenerateDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
