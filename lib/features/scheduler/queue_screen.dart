import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/scheduled_post.dart';
import '../dashboard/dashboard_controller.dart';
import '../posts/post_editor_screen.dart';
import 'scheduler_screen.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(dashboardDataProvider);
    final body = queueState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Failed to load queue: $error')),
      data: (dashboard) {
        final posts = [...dashboard.posts]
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _statusLabel(post.status),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          post.contentType,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM d, y • h:mm a').format(post.scheduledAt),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PostEditorScreen(postId: post.id),
                            ),
                          ),
                          child: const Text('Edit'),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SchedulerScreen(postId: post.id),
                            ),
                          ),
                          child: const Text('Schedule'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Queue')),
      body: body,
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
