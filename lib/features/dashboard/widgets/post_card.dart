import 'package:flutter/material.dart';
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
  });

  final ScheduledPost post;
  final VoidCallback onOpen;
  final ValueChanged<String> onActionSelected;
  final List<PostActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, y • h:mm a').format(post.scheduledAt);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSoft, width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusPill(label: _statusLabel(post.status), color: AppColors.queuedBlue),
                const SizedBox(width: 8),
                if (post.isAiGenerated)
                  const _StatusPill(
                    label: 'AI',
                    color: AppColors.secondary,
                  ),
                const Spacer(),
                Text(
                  post.platform,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  onSelected: onActionSelected,
                  itemBuilder: (context) => [
                    for (final action in actions)
                      PopupMenuItem<String>(
                        value: action.id,
                        child: Text(action.label),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              post.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 14),
            Text(
              '$formattedDate   •   ${post.contentType}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
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
  });

  final String id;
  final String label;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
