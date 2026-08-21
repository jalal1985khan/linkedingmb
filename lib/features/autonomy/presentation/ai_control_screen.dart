import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/gmb_autonomy_repository.dart';
import '../../business_flow/providers/active_location_provider.dart';
import '../../dashboard/widgets/dashboard_header_bar.dart';
import '../../notifications/notification_end_drawer.dart';

class AIControlScreen extends ConsumerStatefulWidget {
  const AIControlScreen({super.key});

  @override
  ConsumerState<AIControlScreen> createState() => _AIControlScreenState();
}

class _AIControlScreenState extends ConsumerState<AIControlScreen> with SingleTickerProviderStateMixin {
  GlobalKey<ScaffoldState>? _scaffoldKey;
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  List<CapabilityInfo> _capabilities = [];
  AutonomySettings? _settings;
  List<ApprovalItem> _approvals = [];
  final Map<String, String> _editedLevels = {};

  @override
  void initState() {
    super.initState();
    _scaffoldKey ??= GlobalKey<ScaffoldState>();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(gmbAutonomyRepositoryProvider);
      final caps = await repo.getCapabilities();
      final settings = await repo.getSettings(activeLocation.id);
      final approvals = await repo.listApprovals(activeLocation.id);

      if (mounted) {
        setState(() {
          _capabilities = caps;
          _settings = settings;
          _approvals = approvals;
          _editedLevels.clear();
          _editedLevels.addAll(settings.levels);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _togglePause(bool isCurrentlyPaused) async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    final newPaused = !isCurrentlyPaused;
    try {
      final repo = ref.read(gmbAutonomyRepositoryProvider);
      final ok = await repo.setPaused(activeLocation.id, newPaused);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newPaused ? 'Automation paused for this location.' : 'Automation resumed.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: newPaused ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update pause state: $e', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveLevels() async {
    final activeLocation = ref.read(activeLocationProvider).activeLocation;
    if (activeLocation == null) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(gmbAutonomyRepositoryProvider);
      final ok = await repo.updateSettings(activeLocation.id, _editedLevels);
      if (ok && mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Autonomy settings saved successfully!', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resolveApproval(String approvalId, String decision) async {
    try {
      final repo = ref.read(gmbAutonomyRepositoryProvider);
      final ok = await repo.resolveApproval(approvalId, decision);
      if (ok && mounted) {
        setState(() {
          _approvals.removeWhere((a) => a.id == approvalId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'approved' ? 'Draft approved and applied to Google!' : 'Draft rejected.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: decision == 'approved' ? const Color(0xFF16A34A) : Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  IconData _getCapabilityIcon(String key) {
    switch (key.toLowerCase()) {
      case 'posts':
      case 'publish_posts':
        return Icons.edit_note_rounded;
      case 'reviews':
      case 'reply_reviews':
        return Icons.chat_bubble_outline_rounded;
      case 'qa':
      case 'publish_qa':
        return Icons.help_outline_rounded;
      case 'description':
      case 'rewrite_description':
        return Icons.auto_stories_outlined;
      case 'photos':
      case 'media':
        return Icons.photo_library_outlined;
      case 'services':
        return Icons.build_outlined;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeLocation = ref.watch(activeLocationProvider).activeLocation;
    final scaffoldKey = _scaffoldKey ??= GlobalKey<ScaffoldState>();

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

    if (activeLocation == null) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
        body: Container(
          decoration: BoxDecoration(gradient: bgGradient),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                  child: DashboardHeaderBar(
                    title: 'AI Control & Autonomy',
                    subtitle: 'Guardrails & Approvals',
                    showSparkle: true,
                    showBackButton: true,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Please select a business location first.',
                      style: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isPaused = _settings?.isPaused ?? false;

    return Scaffold(
      key: scaffoldKey,
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
                  title: 'AI Control & Autonomy',
                  subtitle: activeLocation.name,
                  showSparkle: true,
                  showBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                  onOpenNotifications: () {
                    if (scaffoldKey.currentState != null) {
                      scaffoldKey.currentState!.openEndDrawer();
                    } else {
                      Scaffold.maybeOf(context)?.openEndDrawer();
                    }
                  },
                ),
              ),

              // 2. Consistent Tab Bar Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF4F46E5),
                  unselectedLabelColor: textSecondary,
                  indicatorColor: const Color(0xFF4F46E5),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  padding: const EdgeInsets.all(4),
                  labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: [
                    const Tab(
                      icon: Icon(Icons.tune_rounded, size: 18),
                      iconMargin: EdgeInsets.only(bottom: 2),
                      text: 'Autonomy Ladder',
                    ),
                    Tab(
                      icon: Icon(Icons.inbox_rounded, size: 18),
                      iconMargin: EdgeInsets.only(bottom: 2),
                      text: 'Approval Inbox (${_approvals.length})',
                    ),
                  ],
                ),
              ),

              // 3. Tab Views
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLadderTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary, isPaused),
                          _buildApprovalsTab(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _tabController.index == 0 && !_isLoading
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardBgColor,
                border: Border(top: BorderSide(color: borderColor, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveLevels,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline, size: 19),
                    label: Text(
                      _isSaving ? 'Saving Guardrails...' : 'Save Autonomy Guardrails',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLadderTab(
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isPaused,
  ) {
    // Banner styling
    final bannerBg = isPaused
        ? (isDark ? const Color(0xFF450A0A).withValues(alpha: 0.5) : const Color(0xFFFEF2F2))
        : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFF0FDF4));

    final bannerBorder = isPaused
        ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA))
        : (isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0));

    final bannerTitleColor = isPaused
        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B))
        : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534));

    final bannerSubColor = isPaused
        ? (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C))
        : (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF15803D));

    final bannerIconBg = isPaused ? const Color(0xFFDC2626) : const Color(0xFF10B981);

    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ── Emergency Kill Switch / Status Card ─────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bannerBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bannerBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bannerIconBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: bannerIconBg.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isPaused ? Icons.pause_rounded : Icons.bolt_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPaused ? 'Automation is Paused' : 'Automation Active',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: bannerTitleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPaused
                          ? 'No automated writes will be performed on Google Maps.'
                          : 'AI executes within the guardrails configured below.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: bannerSubColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPaused ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 16,
                ),
                onPressed: () => _togglePause(isPaused),
                label: Text(
                  isPaused ? 'Resume' : 'Pause All',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section Title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF4F46E5)),
            ),
            const SizedBox(width: 8),
            Text(
              'CAPABILITY LADDER',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF6366F1),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._capabilities.map((cap) => _buildCapabilityCard(cap, isDark, cardBgColor, borderColor, textPrimary, textSecondary)),
      ],
    );
  }

  Widget _buildCapabilityCard(
    CapabilityInfo cap,
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final currentLevel = _editedLevels[cap.key] ?? cap.defaultLevel;
    final capIcon = _getCapabilityIcon(cap.key);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  capIcon,
                  size: 20,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cap.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cap.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildLevelChoice(cap.key, 'advise', 'L0 Advise', currentLevel, cap.maxLevel, isDark, borderColor, textSecondary),
              const SizedBox(width: 8),
              _buildLevelChoice(cap.key, 'approve', 'L1 Approve', currentLevel, cap.maxLevel, isDark, borderColor, textSecondary),
              const SizedBox(width: 8),
              _buildLevelChoice(cap.key, 'autopilot', 'L2 Autopilot', currentLevel, cap.maxLevel, isDark, borderColor, textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelChoice(
    String capKey,
    String levelKey,
    String label,
    String currentLevel,
    String maxLevel,
    bool isDark,
    Color borderColor,
    Color textSecondary,
  ) {
    final isSelected = currentLevel == levelKey;
    final isAllowed = maxLevel == 'autopilot' || (maxLevel == 'approve' && levelKey != 'autopilot') || levelKey == 'advise';

    Color bgColor;
    Color borderC;
    Color textColor;

    if (!isAllowed) {
      bgColor = isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF1F5F9);
      borderC = isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0);
      textColor = isDark ? Colors.white30 : const Color(0xFF94A3B8);
    } else if (isSelected) {
      bgColor = isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF);
      borderC = const Color(0xFF4F46E5);
      textColor = isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5);
    } else {
      bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
      borderC = borderColor;
      textColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    }

    return Expanded(
      child: InkWell(
        onTap: isAllowed ? () => setState(() => _editedLevels[capKey] = levelKey) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderC,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalsTab(
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (_approvals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, size: 30, color: Color(0xFF10B981)),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Pending Approvals',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When AI drafts items under the "L1 Approve" level, they will appear here for your sign-off.',
                  style: GoogleFonts.plusJakartaSans(color: textSecondary, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _approvals.length,
      itemBuilder: (context, index) {
        final item = _approvals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.5) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.capability.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Pending Review',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.amber.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.summary,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: textPrimary),
              ),
              if (item.reason != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.reason!,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _resolveApproval(item.id, 'rejected'),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      'Approve & Publish',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _resolveApproval(item.id, 'approved'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
