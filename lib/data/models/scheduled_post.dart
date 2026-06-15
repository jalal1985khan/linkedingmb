enum PostStatus { draft, queued, scheduled, published, failed }

class ScheduledPost {
  const ScheduledPost({
    required this.id,
    required this.title,
    required this.preview,
    required this.platform,
    required this.status,
    required this.isAiGenerated,
    required this.scheduledAt,
    required this.contentType,
  });

  final String id;
  final String title;
  final String preview;
  final String platform;
  final PostStatus status;
  final bool isAiGenerated;
  final DateTime scheduledAt;
  final String contentType;

  ScheduledPost copyWith({
    String? id,
    String? title,
    String? preview,
    String? platform,
    PostStatus? status,
    bool? isAiGenerated,
    DateTime? scheduledAt,
    String? contentType,
  }) {
    return ScheduledPost(
      id: id ?? this.id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      contentType: contentType ?? this.contentType,
    );
  }
}
