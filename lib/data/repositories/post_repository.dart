import '../models/dashboard_data.dart';
import '../models/scheduled_post.dart';

abstract class PostRepository {
  Future<DashboardData> fetchDashboardData();
  Future<ScheduledPost> generatePostDraft({
    required String businessName,
    required String topic,
    required String goal,
    required String contentType,
  });
  Future<ScheduledPost> schedulePost({
    required String postId,
    required DateTime scheduledAt,
  });
  Future<ScheduledPost?> getPostById(String postId);
  Future<ScheduledPost> updatePostDraft({
    required String postId,
    required String title,
    required String preview,
    required String contentType,
  });
  Future<ScheduledPost> publishNow(String postId);
  Future<ScheduledPost> duplicatePost(String postId);
  Future<void> deletePost(String postId);
  Future<ScheduledPost> retryFailedPost(String postId);
}
