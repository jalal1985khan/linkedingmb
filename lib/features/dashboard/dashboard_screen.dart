import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import '../../data/repositories/gmb_analytics_repository.dart';
import '../../data/repositories/gmb_reviews_repository.dart';
import '../../data/repositories/gmbapi_repository.dart';
import '../business_flow/business_profile_screen.dart';
import '../business_flow/presentation/location_switcher_sheet.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../posts/published_posts_screen.dart';
import '../scheduler/queue_screen.dart';
import 'providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (!widget.showScaffold) {
      return Scaffold(backgroundColor: const Color(0xFFF1F5F9), body: body);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final activeLocState = ref.watch(activeLocationProvider);
    final activeLocation = activeLocState.activeLocation ??
        const BusinessProfile(
          id: 'social_hive_default',
          name: 'SocialHive',
          category: 'Google Business Profile',
          location: 'Global Ediffice Celesta',
          address: 'Global Ediffice Celesta, E-308, Bangalore, KA',
          phone: '+1 800-555-0199',
          hoursSummary: 'Mon-Fri: 9AM-6PM',
          website: 'https://socialhive.pro',
          targetAudience: 'Local Customers',
          brandTone: 'Professional',
          postingFrequency: 3,
        );

    final locationId = activeLocation.id;
    final statsAsync = ref.watch(dashboardStatsProvider(locationId));
    final postActivityAsync = ref.watch(postActivityProvider(locationId));
    final reviewsAsync = ref.watch(dashboardReviewsProvider(locationId));
    final profileScore = ref.watch(profileCompletenessProvider(activeLocation));

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.read(activeLocationProvider.notifier).refresh();
          ref.invalidate(dashboardStatsProvider(locationId));
          ref.invalidate(postActivityProvider(locationId));
          ref.invalidate(dashboardReviewsProvider(locationId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Google Business Profile Header Card + Profile Strength + Quick Actions
              _buildBusinessProfileCard(context, activeLocation, profileScore),

              const SizedBox(height: 16),

              // Performance Section (Dynamic from backend API stats)
              _buildPerformanceCard(context, statsAsync),

              const SizedBox(height: 16),

              // Post Generation Activity Card (Dynamic from backend API activity-chart)
              _buildPostActivityCard(context, postActivityAsync),

              const SizedBox(height: 24),

              // Reviews Overview Card (New UI Design)
              _buildReviewsOverviewCard(context, statsAsync, reviewsAsync),

              const SizedBox(height: 24),

              // Recent Reviews Section (New UI Design)
              _buildRecentReviewsSection(context, reviewsAsync),

              const SizedBox(height: 24),

              // AI Smart Post Card
              _buildAISmartPostCard(context),

              const SizedBox(height: 16),

              // Auto-Review Response Card (Dynamic from backend API reviews)
              _buildAutoReviewCard(context, reviewsAsync),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessProfileCard(
    BuildContext context,
    BusinessProfile profile,
    int profileScore,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo/Avatar + Business Name & Address + Location Switcher Chevron
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const LocationSwitcherSheet(),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo with AI & Verified Checkmark Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'S',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Verified Blue Checkmark Badge
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Title & Address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 24,
                            color: Color(0xFF0F172A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.address,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BusinessProfileScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            'See Business Profile',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Dynamic Profile Strength Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile strength',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profileScore >= 90
                            ? 'Your profile is highly optimized'
                            : 'See how to improve your score',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Circular Progress Indicator
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          value: profileScore / 100.0,
                          strokeWidth: 4.5,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                        ),
                      ),
                      Text(
                        '$profileScore%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
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



  Widget _buildPerformanceCard(
    BuildContext context,
    AsyncValue<GMBLocationStats> statsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time production metrics',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Text(
                'See more',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D9488),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Dynamic Metric Columns
          statsAsync.when(
            loading: () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPerformanceMetricColumn('...', 'Views'),
                _buildPerformanceMetricColumn('...', 'Calls'),
                _buildPerformanceMetricColumn('...', 'Directions'),
                _buildPerformanceMetricColumn('...', 'Clicks'),
              ],
            ),
            error: (_, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPerformanceMetricColumn('0', 'Views'),
                _buildPerformanceMetricColumn('0', 'Calls'),
                _buildPerformanceMetricColumn('0', 'Directions'),
                _buildPerformanceMetricColumn('0', 'Clicks'),
              ],
            ),
            data: (stats) {
              final viewsStr = _formatNumber(stats.views);
              final callsStr = _formatNumber(stats.calls);
              final directionsStr = _formatNumber(stats.directionRequests);
              final clicksStr = _formatNumber(stats.websiteClicks);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPerformanceMetricColumn(viewsStr, 'Views'),
                  _buildPerformanceMetricColumn(callsStr, 'Calls'),
                  _buildPerformanceMetricColumn(directionsStr, 'Directions'),
                  _buildPerformanceMetricColumn(clicksStr, 'Clicks'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostActivityCard(BuildContext context, AsyncValue<PostActivityStats> activityAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Post Generation Activity',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Showing total posts generated and posted for last 30 days',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          activityAsync.when(
            loading: () => Row(
              children: [
                Expanded(child: _buildActivityMetricColumn('AI', '...')),
                Container(width: 1, height: 44, color: const Color(0xFFF1F5F9)),
                Expanded(child: _buildActivityMetricColumn('Manual', '...')),
                Container(width: 1, height: 44, color: const Color(0xFFF1F5F9)),
                Expanded(child: _buildActivityMetricColumn('Queue', '...')),
                Container(width: 1, height: 44, color: const Color(0xFFF1F5F9)),
                Expanded(child: _buildActivityMetricColumn('Posted', '...')),
              ],
            ),
            error: (_, _) => Row(
              children: [
                Expanded(child: _buildActivityMetricColumn('AI', '0')),
                Container(width: 1, height: 44, color: const Color(0xFFF1F5F9)),
                Expanded(child: _buildActivityMetricColumn('Manual', '0')),
                Container(width: 1, height: 44, color: const Color(0xFFF1F5F9)),
                Expanded(child: _buildActivityMetricColumn('Queue', '0')),
                Container(width: 1, height: 44, color: const Color(0xFFF1F5F9)),
                Expanded(child: _buildActivityMetricColumn('Posted', '0')),
              ],
            ),
            data: (stats) => Row(
              children: [
                Expanded(child: _buildActivityMetricColumn('AI', '${stats.aiGenerated}')),
                Container(width: 1, height: 44, color: const Color(0xFFF1F5F9)),
                Expanded(child: _buildActivityMetricColumn('Manual', '${stats.manualGenerated}')),
                Container(width: 1, height: 44, color: const Color(0xFFF1F5F9)),
                Expanded(
                  child: _buildActivityMetricColumn(
                    'Queue',
                    '${stats.queued}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QueueScreen()),
                    ),
                  ),
                ),
                Container(width: 1, height: 44, color: const Color(0xFFF1F5F9)),
                Expanded(
                  child: _buildActivityMetricColumn(
                    'Posted',
                    '${stats.posted}',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PublishedPostsScreen()),
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

  Widget _buildActivityMetricColumn(String label, String value, {VoidCallback? onTap}) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: onTap != null ? AppColors.primary : const Color(0xFF0F172A),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildPerformanceMetricColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAISmartPostCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amberAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'AI Assistant',
              style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI Smart Post',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Generate high-engagement social content for your business using trending aesthetics and customer insights.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Generate Draft',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoReviewCard(
    BuildContext context,
    AsyncValue<List<GMBReviewItem>> reviewsAsync,
  ) {
    final countText = reviewsAsync.when(
      loading: () => 'Fetching latest customer reviews...',
      error: (_, _) => '6 new 5-star reviews received today. AI has drafted responses based on your tone of voice.',
      data: (reviews) {
        if (reviews.isEmpty) {
          return 'No new unreplied reviews. All customer feedback is up to date!';
        }
        return '${reviews.length} customer reviews received. AI has drafted responses based on your brand tone.';
      },
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          const Text(
            'Auto-Review',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            countText,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Review & Approve',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsOverviewCard(
    BuildContext context,
    AsyncValue<GMBLocationStats> statsAsync,
    AsyncValue<List<GMBReviewItem>> reviewsAsync,
  ) {
    final stats = statsAsync.value ?? const GMBLocationStats();
    final reviews = reviewsAsync.value ?? const <GMBReviewItem>[];

    final double rating = stats.averageRating;

    final int count5 = reviews.where((r) => r.starRating == 5).length;
    final int count4 = reviews.where((r) => r.starRating == 4).length;
    final int count3 = reviews.where((r) => r.starRating == 3).length;
    final int count2 = reviews.where((r) => r.starRating == 2).length;
    final int count1 = reviews.where((r) => r.starRating == 1).length;

    final int calcTotal = count5 + count4 + count3 + count2 + count1;
    final int baseCount = stats.totalReviews > 0 ? stats.totalReviews : calcTotal;

    final double p5 = calcTotal > 0 ? count5 / calcTotal : 0.0;
    final double p4 = calcTotal > 0 ? count4 / calcTotal : 0.0;
    final double p3 = calcTotal > 0 ? count3 / calcTotal : 0.0;
    final double p2 = calcTotal > 0 ? count2 / calcTotal : 0.0;
    final double p1 = calcTotal > 0 ? count1 / calcTotal : 0.0;

    String ratingStatus = 'No Rating';
    Color statusColor = const Color(0xFF64748B);
    if (rating >= 4.5) {
      ratingStatus = 'Excellent';
      statusColor = const Color(0xFF10B981);
    } else if (rating >= 4.0) {
      ratingStatus = 'Very Good';
      statusColor = const Color(0xFF10B981);
    } else if (rating >= 3.0) {
      ratingStatus = 'Good';
      statusColor = const Color(0xFFF59E0B);
    } else if (rating >= 2.0) {
      ratingStatus = 'Average';
      statusColor = const Color(0xFFF97316);
    } else if (rating > 0.0) {
      ratingStatus = 'Needs Attention';
      statusColor = const Color(0xFFEF4444);
    }

    final int positiveCount = count5 + count4;
    final int positivePercent = calcTotal > 0
        ? ((positiveCount / calcTotal) * 100).round()
        : (baseCount > 0 && rating >= 4.0 ? 100 : 0);

    final int repliedCount = reviews.where((r) => r.reviewReply != null && r.reviewReply!.trim().isNotEmpty).length;

    String avgResponse = '-';
    final repliedReviews = reviews.where((r) => r.reviewReply != null && r.createTime.isNotEmpty && r.replyTime != null && r.replyTime!.isNotEmpty).toList();
    if (repliedReviews.isNotEmpty) {
      int totalMinutes = 0;
      int validCount = 0;
      for (final r in repliedReviews) {
        try {
          final cDate = DateTime.parse(r.createTime);
          final rDate = DateTime.parse(r.replyTime!);
          final diff = rDate.difference(cDate).inMinutes;
          if (diff >= 0) {
            totalMinutes += diff;
            validCount++;
          }
        } catch (_) {}
      }
      if (validCount > 0) {
        final avgMin = totalMinutes ~/ validCount;
        if (avgMin < 60) {
          avgResponse = '${avgMin > 0 ? avgMin : 1}m';
        } else if (avgMin < 1440) {
          avgResponse = '${avgMin ~/ 60}h';
        } else {
          avgResponse = '${avgMin ~/ 1440}d';
        }
      }
    } else if (repliedCount > 0) {
      avgResponse = 'Fast';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Color(0xFF6366F1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviews Overview',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track and respond to customer reviews',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Rating Overview & Distribution
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Rating Box
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: index < rating.round()
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        ratingStatus,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on $baseCount reviews',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 100,
                color: const Color(0xFFF1F5F9),
              ),
              const SizedBox(width: 16),

              // Right: Star Distribution Bars
              Expanded(
                child: Column(
                  children: [
                    _buildStarProgressRow(5, p5, count5),
                    const SizedBox(height: 6),
                    _buildStarProgressRow(4, p4, count4),
                    const SizedBox(height: 6),
                    _buildStarProgressRow(3, p3, count3),
                    const SizedBox(height: 6),
                    _buildStarProgressRow(2, p2, count2),
                    const SizedBox(height: 6),
                    _buildStarProgressRow(1, p1, count1),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Bottom 4 Metric Pillars
          Row(
            children: [
              _buildMetricPill(
                Icons.chat_bubble_outline_rounded,
                '$baseCount',
                'Total Reviews',
              ),
              _buildVerticalDivider(),
              _buildMetricPill(
                Icons.star_outline_rounded,
                '$positivePercent%',
                'Positive',
              ),
              _buildVerticalDivider(),
              _buildMetricPill(
                Icons.reply_rounded,
                '$repliedCount',
                'Replied',
              ),
              _buildVerticalDivider(),
              _buildMetricPill(
                Icons.access_time_rounded,
                avgResponse,
                'Avg. Response',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarProgressRow(int star, double progress, int count) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$star',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildMetricPill(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviewsSection(
    BuildContext context,
    AsyncValue<List<GMBReviewItem>> reviewsAsync,
  ) {
    final reviews = reviewsAsync.value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title & Filter Dropdown Pill
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Reviews',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All Platforms',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // List of Live Review Cards or Empty State
        if (reviews.isNotEmpty)
          for (final review in reviews.take(3)) ...[
            _buildRecentReviewCard(context, review),
            const SizedBox(height: 12),
          ]
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.rate_review_outlined,
                  size: 36,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 12),
                Text(
                  'No reviews received yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer reviews for your location will appear here in real-time.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRecentReviewCard(BuildContext context, GMBReviewItem review) {
    final isReplied = review.reviewReply != null && review.reviewReply!.trim().isNotEmpty;
    final initials = review.reviewerName.trim().isNotEmpty
        ? review.reviewerName
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'KN';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isReplied) {
              _showReplyDetailsModal(context, review);
            } else {
              _showReplyDialog(context, review);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Avatar + Name & Stars + Timestamp + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Circle with Google Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'G',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2563EB),
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // Name, Stars & Timestamp
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.reviewerName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: i < review.starRating
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formatTimeAgo(review.createTime),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Badge: 'Replied' (Green) or 'New' (Indigo)
                    if (isReplied)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 12,
                              color: Color(0xFF15803D),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Replied',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'New',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Review Comment Text
                Text(
                  review.comment.isNotEmpty
                      ? review.comment
                      : "It's nice platform to use digital marketing, it's very useful for all the marketing people and it will helpful for all marketing platforms.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF334155),
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 14),

                // Action Buttons: Reply or View Reply + Share
                Row(
                  children: [
                    if (isReplied)
                      OutlinedButton.icon(
                        onPressed: () {
                          _showReplyDetailsModal(context, review);
                        },
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF15803D),
                        ),
                        label: Text(
                          'View Reply',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0FDF4),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () {
                          _showReplyDialog(context, review);
                        },
                        icon: const Icon(
                          Icons.reply_rounded,
                          size: 16,
                          color: Color(0xFF6366F1),
                        ),
                        label: Text(
                          'Reply',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        ),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review link copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.share_outlined, size: 16, color: Color(0xFF64748B)),
                      label: Text(
                        'Share',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(String rawTime) {
    if (rawTime.isEmpty) return '2h ago';
    if (rawTime.contains('ago') || rawTime.contains('Just now') || rawTime.contains('Recently')) {
      return rawTime;
    }
    try {
      final dt = DateTime.parse(rawTime);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes > 0 ? diff.inMinutes : 1}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 30) {
        return '${diff.inDays}d ago';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return rawTime.length > 12 ? '${rawTime.substring(0, 10)}...' : rawTime;
    }
  }

  void _showReplyDialog(BuildContext context, GMBReviewItem review) {
    String originalText = review.reviewReply ?? '';
    final controller = TextEditingController(text: originalText);
    bool isAiApplied = false;
    bool isGenerating = false;
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle Indicator
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Row: Left Icon + Title & Subtitle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Chat Sparkle Icon Badge
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.forum_outlined,
                          color: Color(0xFF6366F1),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title and Subtitle Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reply to ${review.reviewerName}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Your public reply will be visible on Google',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Reply Main Input Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Editable Text Field (Taller Height)
                        TextField(
                          controller: controller,
                          minLines: 7,
                          maxLines: 10,
                          onChanged: (_) => setModalState(() {}),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF1E293B),
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Write your public reply here...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Bottom Row: AI Enhance Button (Left) + Character Counter & Emoji (Right)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // AI Enhance Button at Bottom-Left
                            OutlinedButton.icon(
                              onPressed: isGenerating
                                  ? null
                                  : () async {
                                      setModalState(() => isGenerating = true);
                                      try {
                                        final repo = ref.read(gmbapiRepositoryProvider);
                                        final aiReply = await repo.enhanceReviewReply(
                                          reviewerName: review.reviewerName,
                                          starRating: review.starRating.toString(),
                                          reviewComment: review.comment,
                                        );
                                        setModalState(() {
                                          if (originalText.isEmpty) {
                                            originalText = controller.text;
                                          }
                                          controller.text = aiReply;
                                          isAiApplied = true;
                                          isGenerating = false;
                                        });
                                      } catch (e) {
                                        setModalState(() => isGenerating = false);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('AI Enhancement error: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: isGenerating
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF6366F1),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 15,
                                      color: Color(0xFF6366F1),
                                    ),
                              label: Text(
                                isGenerating ? 'Enhancing...' : 'AI Enhance',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFC7D2FE)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),

                            const Spacer(),

                            Text(
                              '${controller.text.length}/4000',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.sentiment_satisfied_alt_rounded,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // AI Enhance Applied Banner
                        if (isAiApplied)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 14,
                                            color: Color(0xFF10B981),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'AI Enhance applied',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF4C1D95),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Your reply is more professional, warm and engaging.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setModalState(() {
                                      controller.text = originalText;
                                      isAiApplied = false;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.undo_rounded,
                                    size: 14,
                                    color: Color(0xFF6366F1),
                                  ),
                                  label: Text(
                                    'View original',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6366F1),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom Primary Post Reply Button with Real API Submission
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (isPosting || controller.text.trim().isEmpty)
                          ? null
                          : () async {
                              setModalState(() => isPosting = true);
                              try {
                                final repo = ref.read(gmbapiRepositoryProvider);
                                await repo.replyToReview(
                                  review.id.isNotEmpty ? review.id : review.name,
                                  controller.text.trim(),
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                ref.invalidate(dashboardReviewsProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reply posted successfully to Google My Business!'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isPosting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to post reply: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: isPosting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.near_me_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                      label: Text(
                        isPosting ? 'Posting...' : 'Post Reply',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showReplyDetailsModal(BuildContext context, GMBReviewItem review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row: Green Check Icon + Title + Replied Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF15803D),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Reply Details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Published to Google My Business',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Color(0xFF15803D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Replied',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Customer Review Summary Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.reviewerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: i < review.starRating
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTimeAgo(review.createTime),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    if (review.comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        review.comment,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Published Owner Response Box (Read-Only)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.reply_rounded,
                          size: 16,
                          color: Color(0xFF15803D),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Your Published Response',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        const Spacer(),
                        if (review.replyTime != null && review.replyTime!.isNotEmpty)
                          Text(
                            _formatTimeAgo(review.replyTime!),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      review.reviewReply ?? 'No reply content available.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
