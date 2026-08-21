import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/gmbapi_repository.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../dashboard/widgets/dashboard_header_bar.dart';
import '../notifications/notification_end_drawer.dart';
import 'create_post_flow_screen.dart';

final publishedPostsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final activeLoc = ref.watch(activeLocationProvider).activeLocation;
  final repo = ref.watch(gmbapiRepositoryProvider);
  return repo.getPostsHistory(locationId: activeLoc?.id);
});

class PublishedPostsScreen extends ConsumerStatefulWidget {
  const PublishedPostsScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  ConsumerState<PublishedPostsScreen> createState() => _PublishedPostsScreenState();
}

class _PublishedPostsScreenState extends ConsumerState<PublishedPostsScreen> {
  GlobalKey<ScaffoldState>? _scaffoldKey;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scaffoldKey ??= GlobalKey<ScaffoldState>();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(publishedPostsProvider);
    final activeLoc = ref.watch(activeLocationProvider).activeLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldKey = _scaffoldKey ??= GlobalKey<ScaffoldState>();

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

    final content = Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Standard Unified DashboardHeaderBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
              child: DashboardHeaderBar(
                title: 'Published Posts History',
                subtitle: activeLoc?.name ?? 'SocialHive',
                showSparkle: true,
                showBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
                onOpenNotifications: () {
                  if (scaffoldKey.currentState != null) {
                    scaffoldKey.currentState!.openEndDrawer();
                  } else {
                    Scaffold.maybeOf(context)?.openEndDrawer();
                  }
                },
              ),
            ),

            // 2. Search & Filter Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search published posts...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF6366F1)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: 18, color: textSecondary),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),

            // 3. Posts Stream / List
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF4F46E5),
                onRefresh: () async => ref.refresh(publishedPostsProvider),
                child: postsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  ),
                  error: (err, stack) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.error_outline_rounded, size: 28, color: Color(0xFFDC2626)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load published posts',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              err.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () => ref.refresh(publishedPostsProvider),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(
                                'Try Again',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  data: (rawPosts) {
                    final sortedList = List<dynamic>.from(rawPosts);
                    sortedList.sort((a, b) {
                      final rawA = a['posted_at'] ?? a['created_at'] ?? a['scheduled_time'] ?? a['createTime'] ?? a['updateTime'];
                      final rawB = b['posted_at'] ?? b['created_at'] ?? b['scheduled_time'] ?? b['createTime'] ?? b['updateTime'];
                      final dateA = rawA != null ? (DateTime.tryParse(rawA.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0)) : DateTime.fromMillisecondsSinceEpoch(0);
                      final dateB = rawB != null ? (DateTime.tryParse(rawB.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0)) : DateTime.fromMillisecondsSinceEpoch(0);
                      return dateB.compareTo(dateA); // Newest / latest post at the top
                    });

                    final posts = sortedList.where((p) {
                      if (_searchQuery.isEmpty) return true;
                      final text = (p['content'] ?? p['summary'] ?? p['caption'] ?? p['title'] ?? '').toString().toLowerCase();
                      return text.contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (posts.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                        child: Center(
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
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.published_with_changes_rounded,
                                    size: 32,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _searchQuery.isNotEmpty ? 'No Matching Posts' : 'No Published Posts Yet',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Try searching with a different keyword.'
                                      : 'Your published Google Business Profile posts will automatically appear here.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const CreatePostFlowScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 19),
                                  label: Text(
                                    'Create New GMB Post',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      primary: false,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return _PublishedPostCard(
                          post: post,
                          isDark: isDark,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.showScaffold) {
      return content;
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: content,
    );
  }
}

class _PublishedPostCard extends StatelessWidget {
  const _PublishedPostCard({
    required this.post,
    required this.isDark,
    required this.cardBgColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final dynamic post;
  final bool isDark;
  final Color cardBgColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final content = (post['content'] ?? post['summary'] ?? post['caption'] ?? post['title'] ?? 'GMB Post Update').toString();
    final imageUrl = post['media_url'] ?? post['image_url'] ?? post['image_data'];
    final postType = (post['topic_type'] ?? post['post_type'] ?? 'STANDARD').toString();
    final actionType = post['action_type'] ?? post['cta_type'];
    final postedAtRaw = post['posted_at'] ?? post['created_at'] ?? post['scheduled_time'];

    DateTime? postedDate;
    if (postedAtRaw != null) {
      try {
        postedDate = DateTime.parse(postedAtRaw.toString());
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
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
          // 1. Header Status Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Published',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    postType,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                    ),
                  ),
                ),
                const Spacer(),
                if (postedDate != null)
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, y • h:mm a').format(postedDate),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 2. Post Image (if present)
          if (imageUrl != null && imageUrl.toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl.toString(),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),

          // 3. Content Text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: textPrimary,
                    height: 1.5,
                  ),
                ),
                if (actionType != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 6),
                        Text(
                          'CTA: $actionType',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // 4. Actions Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Post content copied to clipboard!', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(Icons.copy_rounded, size: 16, color: textSecondary),
                  label: Text(
                    'Copy Content',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.g_mobiledata_rounded, size: 18, color: Color(0xFF3B82F6)),
                      Text(
                        'Live GMB',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
