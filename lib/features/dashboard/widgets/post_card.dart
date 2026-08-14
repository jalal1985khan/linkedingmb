import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/scheduled_post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onOpen,
    required this.onActionSelected,
    required this.actions,
    this.onPublishNow,
    this.onReschedule,
  });

  final ScheduledPost post;
  final VoidCallback onOpen;
  final ValueChanged<String> onActionSelected;
  final List<PostActionItem> actions;
  final VoidCallback? onPublishNow;
  final VoidCallback? onReschedule;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final formattedDate = DateFormat('MMM d, y • h:mm a').format(post.scheduledAt);
    final statusColor = _statusColor(post.status);
    final statusIcon = _statusIcon(post.status);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Platform Header Row
            Row(
              children: [
                _StatusBadge(
                  label: _statusLabel(post.status),
                  color: statusColor,
                  icon: statusIcon,
                ),
                const SizedBox(width: 8),
                if (post.isAiGenerated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(
                          'AI',
                          style: GoogleFonts.inter(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    post.contentType.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: textSecondary, size: 20),
                  color: cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: borderColor),
                  ),
                  onSelected: onActionSelected,
                  itemBuilder: (context) => [
                    for (final action in actions)
                      PopupMenuItem<String>(
                        value: action.id,
                        child: Row(
                          children: [
                            Icon(
                              action.icon,
                              size: 16,
                              color: action.id == 'delete' ? AppColors.error : textPrimary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              action.label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: action.id == 'delete' ? AppColors.error : textPrimary,
                                fontWeight: action.id == 'delete' ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Post Content Title
            Text(
              post.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Post Preview
            if (post.preview.isNotEmpty)
              Text(
                post.preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 12),

            // Date & Schedule Info
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: textSecondary),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Button Action Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (post.status == PostStatus.draft || post.status == PostStatus.scheduled || post.status == PostStatus.queued)
                  ElevatedButton.icon(
                    onPressed: onPublishNow,
                    icon: const Icon(Icons.send_outlined, size: 14),
                    label: Text('Publish Now', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: Text('Edit', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                if (onReschedule != null && post.status != PostStatus.published)
                  OutlinedButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.event_outlined, size: 14),
                    label: Text('Reschedule', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(PostStatus status) {
    switch (status) {
      case PostStatus.draft:
        return Colors.amber[700]!;
      case PostStatus.queued:
        return Colors.indigo[500]!;
      case PostStatus.scheduled:
        return AppColors.primary;
      case PostStatus.published:
        return AppColors.success;
      case PostStatus.failed:
        return AppColors.error;
    }
  }

  IconData _statusIcon(PostStatus status) {
    switch (status) {
      case PostStatus.draft:
        return Icons.edit_note_outlined;
      case PostStatus.queued:
        return Icons.hourglass_empty_outlined;
      case PostStatus.scheduled:
        return Icons.schedule_outlined;
      case PostStatus.published:
        return Icons.check_circle_outline;
      case PostStatus.failed:
        return Icons.error_outline;
    }
  }

  String _statusLabel(PostStatus status) {
    switch (status) {
      case PostStatus.draft:
        return 'Draft';
      case PostStatus.queued:
        return 'Queued';
      case PostStatus.scheduled:
        return 'Scheduled';
      case PostStatus.published:
        return 'Published';
      case PostStatus.failed:
        return 'Failed';
    }
  }
}

class PostActionItem {
  const PostActionItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
