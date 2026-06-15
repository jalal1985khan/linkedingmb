import '../models/dashboard_data.dart';
import '../models/scheduled_post.dart';
import '../repositories/post_repository.dart';

class MockPostRepository implements PostRepository {
  final List<ScheduledPost> _posts = [
    ScheduledPost(
      id: 'p_1',
      title: "Will a Global AI Pause Happen? Probably Not, and Here's Why:",
      preview: 'The concept of a global AI pause has been gaining traction...',
      platform: 'GOOGLE BUSINESS',
      status: PostStatus.queued,
      isAiGenerated: true,
      scheduledAt: DateTime.now().subtract(const Duration(minutes: 2)),
      contentType: 'Image',
    ),
    ScheduledPost(
      id: 'p_2',
      title: 'Boost Your Design Collaboration with RhinoCollab',
      preview: 'Imagine working on a complex design project with your team...',
      platform: 'GOOGLE BUSINESS',
      status: PostStatus.queued,
      isAiGenerated: true,
      scheduledAt: DateTime.now().subtract(const Duration(hours: 10)),
      contentType: 'Image',
    ),
    ScheduledPost(
      id: 'p_3',
      title: '5 Local SEO Upgrades Every Cafe Should Do This Week',
      preview: 'Small local improvements in your profile can create faster leads...',
      platform: 'GOOGLE BUSINESS',
      status: PostStatus.scheduled,
      isAiGenerated: false,
      scheduledAt: DateTime.now().add(const Duration(hours: 4)),
      contentType: 'Offer',
    ),
    ScheduledPost(
      id: 'p_4',
      title: 'Behind-the-scenes bakery prep for fresh breads',
      preview: 'Last publish attempt failed due to missing image dimensions.',
      platform: 'GOOGLE BUSINESS',
      status: PostStatus.failed,
      isAiGenerated: true,
      scheduledAt: DateTime.now().subtract(const Duration(hours: 3)),
      contentType: 'Image',
    ),
  ];

  @override
  Future<DashboardData> fetchDashboardData() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final posts = [..._posts]..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return DashboardData(
      queuedCount: posts.where((post) => post.status == PostStatus.queued).length,
      aiGeneratedCount: posts.where((post) => post.isAiGenerated).length,
      posts: posts,
    );
  }

  @override
  Future<ScheduledPost> generatePostDraft({
    required String businessName,
    required String topic,
    required String goal,
    required String contentType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final draft = ScheduledPost(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: '$topic - $businessName',
      preview: 'AI draft focused on $goal. Optimized for local engagement and conversion.',
      platform: 'GOOGLE BUSINESS',
      status: PostStatus.draft,
      isAiGenerated: true,
      scheduledAt: DateTime.now(),
      contentType: contentType,
    );
    _posts.insert(0, draft);
    return draft;
  }

  @override
  Future<ScheduledPost> schedulePost({
    required String postId,
    required DateTime scheduledAt,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final index = _posts.indexWhere((item) => item.id == postId);
    if (index < 0) {
      throw Exception('Post not found');
    }
    final updated = _posts[index].copyWith(
      status: PostStatus.scheduled,
      scheduledAt: scheduledAt,
    );
    _posts[index] = updated;
    return updated;
  }

  @override
  Future<ScheduledPost?> getPostById(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final index = _posts.indexWhere((item) => item.id == postId);
    if (index < 0) {
      return null;
    }
    return _posts[index];
  }

  @override
  Future<ScheduledPost> updatePostDraft({
    required String postId,
    required String title,
    required String preview,
    required String contentType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final index = _posts.indexWhere((item) => item.id == postId);
    if (index < 0) {
      throw Exception('Post not found');
    }
    final updated = _posts[index].copyWith(
      title: title,
      preview: preview,
      contentType: contentType,
      status: _posts[index].status == PostStatus.published
          ? PostStatus.published
          : PostStatus.draft,
    );
    _posts[index] = updated;
    return updated;
  }

  @override
  Future<ScheduledPost> publishNow(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final index = _posts.indexWhere((item) => item.id == postId);
    if (index < 0) {
      throw Exception('Post not found');
    }
    final updated = _posts[index].copyWith(
      status: PostStatus.published,
      scheduledAt: DateTime.now(),
    );
    _posts[index] = updated;
    return updated;
  }

  @override
  Future<ScheduledPost> duplicatePost(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final index = _posts.indexWhere((item) => item.id == postId);
    if (index < 0) {
      throw Exception('Post not found');
    }
    final source = _posts[index];
    final copy = source.copyWith(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: '${source.title} (Copy)',
      status: PostStatus.draft,
      scheduledAt: DateTime.now(),
    );
    _posts.insert(0, copy);
    return copy;
  }

  @override
  Future<void> deletePost(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _posts.removeWhere((item) => item.id == postId);
  }

  @override
  Future<ScheduledPost> retryFailedPost(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final index = _posts.indexWhere((item) => item.id == postId);
    if (index < 0) {
      throw Exception('Post not found');
    }
    final updated = _posts[index].copyWith(
      status: PostStatus.queued,
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
    );
    _posts[index] = updated;
    return updated;
  }
}
