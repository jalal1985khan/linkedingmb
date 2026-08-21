import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/api_config.dart';
import '../../../data/models/scheduled_post.dart';
import '../dashboard_controller.dart';
import '../../posts/create_post_flow_screen.dart';
import '../../posts/post_editor_screen.dart';
import '../../scheduler/queue_screen.dart';

class UpcomingPostsCard extends ConsumerWidget {
  final VoidCallback? onSchedulePost;

  const UpcomingPostsCard({super.key, this.onSchedulePost});

  Widget _buildThumbnail(String? imgUrl) {
    if (imgUrl == null || imgUrl.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.remove_red_eye_outlined, size: 20, color: Color(0xFF94A3B8)),
      );
    }

    final trimmed = imgUrl.trim();

    // 1. Base64 Data URI (e.g. data:image/jpeg;base64,...)
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final cleanBase64 = base64Str.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.remove_red_eye_outlined, size: 20, color: Color(0xFF94A3B8)),
          ),
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.remove_red_eye_outlined, size: 20, color: Color(0xFF94A3B8)),
        );
      }
    }

    // 2. Pure base64 without prefix
    if (trimmed.startsWith('/9j/') ||
        trimmed.startsWith('iVBORw0KGgo') ||
        (trimmed.length > 300 && !trimmed.startsWith('http') && !trimmed.startsWith('/'))) {
      try {
        final cleanBase64 = trimmed.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.remove_red_eye_outlined, size: 20, color: Color(0xFF94A3B8)),
          ),
        );
      } catch (_) {}
    }

    // 3. Network URL (HTTP/HTTPS or relative)
    String fullUrl = trimmed;
    if (!fullUrl.startsWith('http')) {
      final cleanPath = fullUrl.startsWith('/') ? fullUrl : '/$fullUrl';
      fullUrl = '${ApiConfig.baseUrl}$cleanPath';
    }

    // Convert Google Drive URLs to resilient Backend Image Proxy to prevent CORS & 429 rate limit blocks
    if (fullUrl.contains('drive.google.com') || fullUrl.contains('lh3.googleusercontent.com')) {
      final idMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(fullUrl);
      final dMatch = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(fullUrl);
      final fileId = idMatch?.group(1) ?? dMatch?.group(1);
      if (fileId != null && fileId.isNotEmpty) {
        fullUrl = '${ApiConfig.baseUrl}/api/scheduler/image-proxy?file_id=$fileId';
      } else {
        fullUrl = '${ApiConfig.baseUrl}/api/scheduler/image-proxy?url=${Uri.encodeComponent(fullUrl)}';
      }
    }

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.remove_red_eye_outlined, size: 20, color: Color(0xFF94A3B8)),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$min $period';
    final dayStr = dt.day.toString().padLeft(2, '0');
    return '$dayStr-${months[dt.month - 1]}-${dt.year} $timeStr';
  }

  String _formatScheduledDateOnly(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$min $period';
    final dayStr = dt.day.toString().padLeft(2, '0');
    return '$dayStr-${months[dt.month - 1]}-${dt.year} • $timeStr';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scheduled Posts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Your upcoming content pipeline ready to be published.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          dashboardAsync.when(
            loading: () => Container(
              padding: const EdgeInsets.all(32),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A07E8)),
                ),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildEmptyState(context),
            ),
            data: (dashboard) {
              final allPosts = dashboard.posts.where((p) {
                return p.status != PostStatus.published;
              }).toList();

              final displayList = allPosts.isNotEmpty ? allPosts : dashboard.posts;

              if (displayList.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildEmptyState(context),
                );
              }

              final displayedPosts = displayList.take(4).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ...displayedPosts.map((post) => _buildWebStylePostItem(context, post)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${displayedPosts.length} of ${displayList.length} posts',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const QueueScreen()),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0F172A)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebStylePostItem(BuildContext context, ScheduledPost post) {
    final now = DateTime.now();
    final isOverdue = post.scheduledAt.isBefore(now) && post.status != PostStatus.published;
    final isDraft = post.status == PostStatus.draft;

    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Top Floating Badge matching Web
          Positioned(
            top: -10,
            left: 12,
            child: isOverdue
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFCD34D), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 11, color: Color(0xFFD97706)),
                        const SizedBox(width: 3),
                        Text(
                          'Overdue',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  )
                : isDraft
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE9D5FF), width: 0.8),
                        ),
                        child: Text(
                          'AI Generated Draft',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7E22CE),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                        ),
                        child: Text(
                          'Scheduled',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildThumbnail(post.imageUrl),
                ),
                const SizedBox(width: 10),

                // Title and Meta Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title.isNotEmpty ? post.title : 'Scheduled Post',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (isOverdue)
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFFB45309)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                'Time passed (${_formatDate(post.scheduledAt)}) - Reschedule required',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFB45309),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else if (isDraft)
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                'No schedule date assigned - Click to set',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                _formatScheduledDateOnly(post.scheduledAt),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Action Button
                if (isOverdue || isDraft)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostEditorScreen(postId: post.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 12),
                    label: Text(
                      isOverdue ? 'Reschedule' : 'Set Date',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                else
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostEditorScreen(postId: post.id),
                        ),
                      );
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.event_available_rounded,
                    size: 22,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No posts scheduled',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF131B2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Schedule posts to keep your profile active',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSchedulePost ??
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreatePostFlowScreen()),
                    );
                  },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(
                'Schedule Post',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A07E8),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
