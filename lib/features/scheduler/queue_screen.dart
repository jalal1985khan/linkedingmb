import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/scheduled_post.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/widgets/post_card.dart';
import '../posts/create_post_flow_screen.dart';
import '../posts/post_editor_screen.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(dashboardDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final body = queueState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load queue',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(error.toString(), style: GoogleFonts.inter(fontSize: 13, color: textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(dashboardDataProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      data: (dashboard) {
        final allPosts = [...dashboard.posts]
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

        final filteredPosts = allPosts.where((post) {
          if (_selectedFilter == 'ALL') return true;
          if (_selectedFilter == 'SCHEDULED') return post.status == PostStatus.scheduled || post.status == PostStatus.queued;
          if (_selectedFilter == 'DRAFT') return post.status == PostStatus.draft;
          if (_selectedFilter == 'PUBLISHED') return post.status == PostStatus.published;
          if (_selectedFilter == 'FAILED') return post.status == PostStatus.failed;
          return true;
        }).toList();

        final scheduledCount = allPosts.where((p) => p.status == PostStatus.scheduled || p.status == PostStatus.queued).length;
        final draftCount = allPosts.where((p) => p.status == PostStatus.draft).length;
        final publishedCount = allPosts.where((p) => p.status == PostStatus.published).length;
        final failedCount = allPosts.where((p) => p.status == PostStatus.failed).length;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardDataProvider);
          },
          child: Column(
            children: [
              // Filter Chips Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All', allPosts.length, isDark, borderColor, textPrimary, textSecondary),
                      const SizedBox(width: 8),
                      _buildFilterChip('SCHEDULED', 'Scheduled', scheduledCount, isDark, borderColor, textPrimary, textSecondary),
                      const SizedBox(width: 8),
                      _buildFilterChip('DRAFT', 'Drafts', draftCount, isDark, borderColor, textPrimary, textSecondary),
                      const SizedBox(width: 8),
                      _buildFilterChip('PUBLISHED', 'Published', publishedCount, isDark, borderColor, textPrimary, textSecondary),
                      const SizedBox(width: 8),
                      _buildFilterChip('FAILED', 'Failed', failedCount, isDark, borderColor, textPrimary, textSecondary),
                    ],
                  ),
                ),
              ),

              // Posts List or Empty State
              Expanded(
                child: filteredPosts.isEmpty
                    ? _buildEmptyState(context, isDark, textPrimary, textSecondary)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = filteredPosts[index];
                          return PostCard(
                            post: post,
                            onOpen: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PostEditorScreen(postId: post.id),
                              ),
                            ),
                            onPublishNow: () => _handlePublishNow(post),
                            onReschedule: () => _handleReschedule(post),
                            actions: const [
                              PostActionItem(id: 'edit', label: 'Edit Content', icon: Icons.edit_outlined),
                              PostActionItem(id: 'reschedule', label: 'Reschedule', icon: Icons.event_outlined),
                              PostActionItem(id: 'duplicate', label: 'Duplicate Post', icon: Icons.copy_outlined),
                              PostActionItem(id: 'delete', label: 'Delete Post', icon: Icons.delete_outline),
                            ],
                            onActionSelected: (actionId) => _handleAction(actionId, post),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );

    if (!widget.showScaffold) {
      return Container(color: bgColor, child: body);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Post Queue & Scheduler',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostFlowScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text('New Post', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildFilterChip(
    String key,
    String label,
    int count,
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSelected = _selectedFilter == key;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : textSecondary,
              ),
            ),
          ),
        ],
      ),
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      side: BorderSide(
        color: isSelected ? AppColors.primary : borderColor,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) {
        setState(() {
          _selectedFilter = key;
        });
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.blueGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.post_add_outlined, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'No Posts Found',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'ALL'
                  ? 'Your post queue is empty. Click "+ New Post" to schedule or publish your first update.'
                  : 'No posts match the selected filter. Try choosing a different status.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostFlowScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text('Create New Post', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePublishNow(ScheduledPost post) async {
    try {
      await ref.read(postRepositoryProvider).publishNow(post.id);
      ref.invalidate(dashboardDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Post published successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish post: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReschedule(ScheduledPost post) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: post.scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(post.scheduledAt),
    );
    if (pickedTime == null || !mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    try {
      await ref.read(postRepositoryProvider).schedulePost(postId: post.id, scheduledAt: newDateTime);
      ref.invalidate(dashboardDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📅 Post rescheduled successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reschedule: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleAction(String actionId, ScheduledPost post) async {
    if (actionId == 'edit') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostEditorScreen(postId: post.id)),
      );
    } else if (actionId == 'reschedule') {
      _handleReschedule(post);
    } else if (actionId == 'duplicate') {
      await ref.read(postRepositoryProvider).duplicatePost(post.id);
      ref.invalidate(dashboardDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content duplicated to drafts!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else if (actionId == 'delete') {
      await ref.read(postRepositoryProvider).deletePost(post.id);
      ref.invalidate(dashboardDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted from queue.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
