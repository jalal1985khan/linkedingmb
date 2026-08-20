import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/gmb_blueprint_repository.dart';
import '../../business_flow/providers/active_location_provider.dart';

class BlueprintPlannerScreen extends ConsumerStatefulWidget {
  const BlueprintPlannerScreen({super.key});

  @override
  ConsumerState<BlueprintPlannerScreen> createState() => _BlueprintPlannerScreenState();
}

class _BlueprintPlannerScreenState extends ConsumerState<BlueprintPlannerScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isScheduling = false;
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
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1)),
              const SizedBox(width: 10),
              Text(
                'Generate 30-Day Blueprint',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI will analyze your local category, reviews, and search keywords to craft a 30-day content calendar.',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Text('Posting Frequency', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: postsPerWeek,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: [3, 5, 7].map((p) => DropdownMenuItem(value: p, child: Text('$p posts / week'))).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => postsPerWeek = v);
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Auto-schedule to Post Queue',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Automatically push generated posts into the scheduler calendar.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                ),
                value: autoSchedule,
                onChanged: (v) => setDialogState(() => autoSchedule = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Generate Strategy'),
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
            content: Text('Generated ${res.totalItems} content concepts!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _renderAndScheduleAll() async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    setState(() => _isScheduling = true);
    try {
      final repo = ref.read(gmbBlueprintRepositoryProvider);
      await repo.renderAndSchedule(activeLocation.id);
      if (mounted) {
        setState(() => _isScheduling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All blueprint items rendered and added to Post Queue!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBlueprint();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScheduling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _improviseItem(GMBBlueprintItem item) async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI is improvising a fresh angle for this post...')),
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
          const SnackBar(content: Text('Concept improvised!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLocation = ref.watch(activeLocationProvider).activeLocation;

    if (activeLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Strategy Blueprint')),
        body: const Center(child: Text('Please select a business location first.')),
      );
    }

    final items = _blueprint?.items ?? [];
    final filteredItems = (_selectedFormat == null || _selectedFormat == 'ALL')
        ? items
        : items.where((i) => i.format.toUpperCase() == _selectedFormat).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Strategy Blueprint',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              activeLocation.name,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _loadBlueprint,
            tooltip: 'Refresh Blueprint',
          ),
        ],
      ),
      body: _isLoading || _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6366F1)),
                  const SizedBox(height: 16),
                  Text(
                    _isGenerating
                        ? 'AI is crafting your 30-day strategy...'
                        : 'Loading content blueprint...',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : items.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildHeaderStats(),
                    _buildFormatFilterBar(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          return _buildBlueprintCard(filteredItems[index]);
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: items.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              icon: _isScheduling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.calendar_month_rounded),
              label: Text(_isScheduling ? 'Scheduling...' : 'Schedule All to Queue'),
              onPressed: _isScheduling ? null : _renderAndScheduleAll,
            )
          : null,
    );
  }

  Widget _buildHeaderStats() {
    final total = _blueprint?.totalItems ?? 0;
    final planDays = _blueprint?.planDays ?? 30;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.25),
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
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Re-plan', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: _showGenerateDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: _formats.map((fmt) {
          final isSelected = (_selectedFormat == null && fmt == 'ALL') || _selectedFormat == fmt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(fmt.replaceAll('_', ' ')),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedFormat = fmt == 'ALL' ? null : fmt);
              },
              selectedColor: const Color(0xFFEEF2FF),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBlueprintCard(GMBBlueprintItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.format,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF6366F1)),
                onPressed: () => _improviseItem(item),
                tooltip: 'Improvise with AI',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.caption,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF475569),
              fontSize: 12,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.mediaConcept.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Visual: ${item.mediaConcept}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 48, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 20),
            Text(
              'No Strategy Blueprint Yet',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate an AI-powered 30-day posting strategy tailored to your Google business category and local audience.',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Generate 30-Day Plan', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: _showGenerateDialog,
            ),
          ],
        ),
      ),
    );
  }
}
