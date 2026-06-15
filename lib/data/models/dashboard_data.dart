import 'scheduled_post.dart';

class DashboardData {
  const DashboardData({
    required this.queuedCount,
    required this.aiGeneratedCount,
    required this.posts,
  });

  final int queuedCount;
  final int aiGeneratedCount;
  final List<ScheduledPost> posts;
}
