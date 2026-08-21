import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/scheduled_post.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/widgets/dashboard_header_bar.dart';
import '../notifications/notification_end_drawer.dart';
import '../posts/create_post_flow_screen.dart';
import '../posts/post_editor_screen.dart';
import '../shell/providers/shell_nav_provider.dart';

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
    final activeLoc = ref.watch(activeLocationProvider).activeLocation;
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

    final body = Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header Bar with New Post Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: DashboardHeaderBar(
                      title: 'Post Queue & Scheduler',
                      subtitle: activeLoc?.name ?? 'SocialHive',
                      showSparkle: true,
                      showBackButton: true,
                      onBack: () => ref.handleSmartBack(context),
                      onOpenNotifications: () {
                        Scaffold.maybeOf(context)?.openEndDrawer();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreatePostFlowScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      'New Post',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 2. Queue Posts State Handling
            Expanded(
              child: queueState.when(
                loading: () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF4F46E5)),
                      const SizedBox(height: 16),
                      Text(
                        'Loading post queue...',
                        style: GoogleFonts.plusJakartaSans(
                          color: textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (error, stackTrace) => Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFDC2626)),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to Load Queue',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          error.toString(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(dashboardDataProvider),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(
                            'Retry',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                        ),
                      ],
                    ),
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
                    color: const Color(0xFF4F46E5),
                    onRefresh: () async {
                      ref.invalidate(dashboardDataProvider);
                    },
                    child: Column(
                      children: [
                        // Horizontal Themed Filter Chips Bar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('ALL', 'All', allPosts.length, isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                                const SizedBox(width: 8),
                                _buildFilterChip('SCHEDULED', 'Scheduled', scheduledCount, isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                                const SizedBox(width: 8),
                                _buildFilterChip('DRAFT', 'Drafts', draftCount, isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                                const SizedBox(width: 8),
                                _buildFilterChip('PUBLISHED', 'Published', publishedCount, isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                                const SizedBox(width: 8),
                                _buildFilterChip('FAILED', 'Failed', failedCount, isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                              ],
                            ),
                          ),
                        ),

                        // Posts List or Empty State
                        Expanded(
                          child: filteredPosts.isEmpty
                              ? _buildEmptyState(context, isDark, cardBgColor, borderColor, textPrimary, textSecondary)
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                                  itemCount: filteredPosts.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final post = filteredPosts[index];
                                    return _ThemedQueuePostCard(
                                      post: post,
                                      isDark: isDark,
                                      cardBgColor: cardBgColor,
                                      borderColor: borderColor,
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                      onOpen: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PostEditorScreen(postId: post.id),
                                        ),
                                      ),
                                      onPublishNow: () => _handlePublishNow(post),
                                      onReschedule: () => _handleReschedule(post),
                                      onActionSelected: (actionId) => _handleAction(actionId, post),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: body,
    );
  }

  Widget _buildFilterChip(
    String key,
    String label,
    int count,
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = key;
        });
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
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
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
                child: const Icon(Icons.post_add_rounded, size: 32, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(height: 18),
              Text(
                'No Posts Found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFilter == 'ALL'
                    ? 'Your post queue is empty. Click "+ New Post" to schedule or publish your first update.'
                    : 'No posts match the selected filter. Try choosing a different tab.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreatePostFlowScreen()),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Create New Post',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
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
            backgroundColor: Color(0xFF4F46E5),
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
            backgroundColor: Color(0xFF4F46E5),
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

class _ThemedQueuePostCard extends StatelessWidget {
  const _ThemedQueuePostCard({
    required this.post,
    required this.isDark,
    required this.cardBgColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onOpen,
    required this.onPublishNow,
    required this.onReschedule,
    required this.onActionSelected,
  });

  final ScheduledPost post;
  final bool isDark;
  final Color cardBgColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onOpen;
  final VoidCallback onPublishNow;
  final VoidCallback onReschedule;
  final ValueChanged<String> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, y • h:mm a').format(post.scheduledAt);

    Color statusBgColor;
    Color statusTextColor;
    Color statusBorderColor;
    IconData statusIcon;
    String statusLabel;

    switch (post.status) {
      case PostStatus.draft:
        statusBgColor = isDark ? const Color(0xFF78350F).withValues(alpha: 0.5) : const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFD97706);
        statusBorderColor = isDark ? const Color(0xFFB45309) : const Color(0xFFFDE68A);
        statusIcon = Icons.edit_note_rounded;
        statusLabel = 'Draft';
        break;
      case PostStatus.queued:
      case PostStatus.scheduled:
        statusBgColor = isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF);
        statusTextColor = const Color(0xFF4F46E5);
        statusBorderColor = isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE);
        statusIcon = Icons.schedule_rounded;
        statusLabel = 'Scheduled';
        break;
      case PostStatus.published:
        statusBgColor = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7);
        statusTextColor = const Color(0xFF16A34A);
        statusBorderColor = isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC);
        statusIcon = Icons.check_circle_outline_rounded;
        statusLabel = 'Published';
        break;
      case PostStatus.failed:
        statusBgColor = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.5) : const Color(0xFFFEE2E2);
        statusTextColor = const Color(0xFFDC2626);
        statusBorderColor = isDark ? const Color(0xFFB91C1C) : const Color(0xFFFCA5A5);
        statusIcon = Icons.error_outline_rounded;
        statusLabel = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
          // 1. Status & Badges Top Row
          Row(
            children: [
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusTextColor),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Content Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  post.contentType.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              if (post.isAiGenerated) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, size: 11, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 3),
                      Text(
                        'AI',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Popup Menu Button
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: textSecondary, size: 20),
                color: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor),
                ),
                onSelected: onActionSelected,
                itemBuilder: (context) => [
                  _buildPopupMenuItem('edit', 'Edit Content', Icons.edit_outlined, textPrimary),
                  _buildPopupMenuItem('reschedule', 'Reschedule', Icons.calendar_today_outlined, textPrimary),
                  _buildPopupMenuItem('duplicate', 'Duplicate Post', Icons.copy_outlined, textPrimary),
                  const PopupMenuDivider(),
                  _buildPopupMenuItem('delete', 'Delete Post', Icons.delete_outline_rounded, const Color(0xFFDC2626)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Headline Title
          Text(
            post.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // 3. Summary/Preview
          if (post.preview.isNotEmpty)
            Text(
              post.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 12),

          // 4. Scheduled Date Row
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 13.5, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5. Action Buttons Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (post.status == PostStatus.draft || post.status == PostStatus.scheduled || post.status == PostStatus.queued)
                ElevatedButton.icon(
                  onPressed: onPublishNow,
                  icon: const Icon(Icons.send_rounded, size: 13),
                  label: Text(
                    'Publish Now',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.edit_outlined, size: 13),
                label: Text(
                  'Edit',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              if (post.status != PostStatus.published)
                OutlinedButton.icon(
                  onPressed: onReschedule,
                  icon: const Icon(Icons.event_outlined, size: 13),
                  label: Text(
                    'Reschedule',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String id, String label, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: id,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
