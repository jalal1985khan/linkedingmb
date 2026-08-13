class ScheduledPost {
  final String id;
  final String content;
  final String? title;
  final DateTime scheduledTime;
  final String status;
  final String platform;
  final bool hasImage;
  final String? imageUrl;

  ScheduledPost({
    required this.id,
    required this.content,
    this.title,
    required this.scheduledTime,
    required this.status,
    required this.platform,
    required this.hasImage,
    this.imageUrl,
  });

  factory ScheduledPost.fromJson(Map<String, dynamic> json) {
    return ScheduledPost(
      id: json['id'] ?? json['_id'] ?? '',
      content: json['content'] ?? json['caption'] ?? json['summary'] ?? '',
      title: json['title'] ?? json['topic'],
      scheduledTime: DateTime.parse(json['scheduled_time'] ?? json['scheduled_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      platform: json['platform'] ?? 'gmb',
      hasImage: json['has_image'] ?? false,
      imageUrl: json['image_url'] ?? json['media_url'] ?? json['image_data'],
    );
  }
}
