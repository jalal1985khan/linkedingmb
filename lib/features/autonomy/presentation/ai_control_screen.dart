import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/gmb_autonomy_repository.dart';
import '../../business_flow/providers/active_location_provider.dart';

class AIControlScreen extends ConsumerStatefulWidget {
  const AIControlScreen({super.key});

  @override
  ConsumerState<AIControlScreen> createState() => _AIControlScreenState();
}

class _AIControlScreenState extends ConsumerState<AIControlScreen> with SingleTickerProviderStateMixin {
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
    _tabController = TabController(length: 2, vsync: this);
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
            content: Text(newPaused ? 'Automation paused for this location.' : 'Automation resumed.'),
            backgroundColor: newPaused ? Colors.orange : Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pause state: $e'), backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Autonomy settings saved!'), backgroundColor: Colors.green),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
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
            content: Text(decision == 'approved' ? 'Draft approved and applied!' : 'Draft rejected.'),
            backgroundColor: decision == 'approved' ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLocation = ref.watch(activeLocationProvider).activeLocation;

    if (activeLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Control')),
        body: const Center(child: Text('Please select a business location first.')),
      );
    }

    final isPaused = _settings?.isPaused ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Control & Autonomy',
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
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            const Tab(text: 'Autonomy Ladder'),
            Tab(text: 'Approval Inbox (${_approvals.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLadderTab(isPaused),
                _buildApprovalsTab(),
              ],
            ),
    );
  }

  Widget _buildLadderTab(bool isPaused) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Emergency Kill Switch Card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPaused ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPaused ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPaused ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaused ? Icons.pause_rounded : Icons.bolt_rounded,
                  color: Colors.white,
                  size: 20,
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
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isPaused ? const Color(0xFF991B1B) : const Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPaused
                          ? 'No automated writes will be performed on Google Maps.'
                          : 'AI executes within the guardrails configured below.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isPaused ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPaused ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => _togglePause(isPaused),
                child: Text(
                  isPaused ? 'Resume' : 'Pause All',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'CAPABILITY LADDER',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),

        ..._capabilities.map((cap) => _buildCapabilityCard(cap)),

        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 20),
          label: Text(
            _isSaving ? 'Saving Settings...' : 'Save Autonomy Guardrails',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          onPressed: _isSaving ? null : _saveLevels,
        ),
      ],
    );
  }

  Widget _buildCapabilityCard(CapabilityInfo cap) {
    final currentLevel = _editedLevels[cap.key] ?? cap.defaultLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cap.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cap.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
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
              _buildLevelChoice(cap.key, 'advise', 'L0 Advise', currentLevel, cap.maxLevel),
              const SizedBox(width: 8),
              _buildLevelChoice(cap.key, 'approve', 'L1 Approve', currentLevel, cap.maxLevel),
              const SizedBox(width: 8),
              _buildLevelChoice(cap.key, 'autopilot', 'L2 Autopilot', currentLevel, cap.maxLevel),
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
  ) {
    final isSelected = currentLevel == levelKey;
    final isAllowed = maxLevel == 'autopilot' || (maxLevel == 'approve' && levelKey != 'autopilot') || levelKey == 'advise';

    return Expanded(
      child: InkWell(
        onTap: isAllowed ? () => setState(() => _editedLevels[capKey] = levelKey) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: !isAllowed
                ? const Color(0xFFF1F5F9)
                : isSelected
                    ? const Color(0xFFEEF2FF)
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: !isAllowed
                    ? const Color(0xFF94A3B8)
                    : isSelected
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalsTab() {
    if (_approvals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'No Pending Approvals',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'When AI drafts items under the "L1 Approve" level, they will appear here for your sign-off.',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _approvals.length,
      itemBuilder: (context, index) {
        final item = _approvals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.capability.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF92400E),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text('Pending Review', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.summary,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              if (item.reason != null) ...[
                const SizedBox(height: 4),
                Text(
                  item.reason!,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _resolveApproval(item.id, 'rejected'),
                    child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve & Publish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
