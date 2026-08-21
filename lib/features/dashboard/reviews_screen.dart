import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/gmb_analytics_repository.dart';
import '../../data/repositories/gmb_reviews_repository.dart';
import '../../data/repositories/gmbapi_repository.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../notifications/notification_end_drawer.dart';
import '../settings/automation_settings_controller.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/dashboard_header_bar.dart';

/// Provider for location-specific reviews supporting both backend repositories
final customerReviewsFamilyProvider =
    FutureProvider.family<List<GMBReviewItem>, String>((ref, locationId) async {
  // 1. Try fetching from GMBReviewsRepository first if locationId is present
  if (locationId.isNotEmpty) {
    try {
      final reviews =
          await ref.read(gmbReviewsRepositoryProvider).fetchReviews(locationId);
      if (reviews.isNotEmpty) return reviews;
    } catch (e) {
      debugPrint('Notice: GMBReviewsRepository fetch failed: $e');
    }
  }

  // 2. Fallback to GmbapiRepository
  try {
    final data = await ref.read(gmbapiRepositoryProvider).getLocationReviews();
    dynamic rawData = data['data'];
    if (rawData == null &&
        data['payload'] != null &&
        data['payload']['data'] != null) {
      rawData = data['payload']['data'];
    }
    List<dynamic> list = [];
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData['data'] is List) {
      list = rawData['data'];
    } else if (data['reviews'] is List) {
      list = data['reviews'];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(GMBReviewItem.fromJson)
        .toList();
  } catch (e) {
    debugPrint('Notice: GmbapiRepository fetch failed: $e');
    return [];
  }
});

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  int _selectedFilter = 0; // 0: All, 1: Unreplied, 2: Positive, 3: Negative

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeLocation = ref.read(activeLocationProvider).activeLocation;
      ref.read(automationSettingsProvider.notifier).fetchSettings(
            locationId: activeLocation?.name ?? activeLocation?.id,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeLocState = ref.watch(activeLocationProvider);
    final activeLocation = activeLocState.activeLocation;
    final locationId = activeLocation?.id ?? activeLocation?.name ?? '';

    final reviewsAsync = ref.watch(customerReviewsFamilyProvider(locationId));
    final statsAsync = ref.watch(dashboardStatsProvider(locationId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark ? AppColors.backgroundGradientDark : AppColors.backgroundGradientLight;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    final content = Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Standard Fixed DashboardHeaderBar across the app
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
              child: DashboardHeaderBar(
                title: 'Customer Reviews',
                subtitle: 'Track and respond to customer reviews',
                showSparkle: true,
                showBackButton: widget.showScaffold,
                onBack: widget.showScaffold ? () => Navigator.of(context).maybePop() : null,
                onOpenDrawer: () => Scaffold.of(context).openDrawer(),
                onOpenNotifications: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
            Expanded(
              child: reviewsAsync.when(
                data: (allReviews) {
                  final stats = statsAsync.value ?? const GMBLocationStats();

                  // Calculate metrics
                  double rating = stats.averageRating;
                  if (allReviews.isNotEmpty) {
                    final valid = allReviews.where((r) => r.starRating > 0).toList();
                    if (valid.isNotEmpty) {
                      final double sum =
                          valid.fold<double>(0.0, (acc, r) => acc + r.starRating);
                      final double computedRating = sum / valid.length;
                      if (rating <= 0.0 || computedRating > 0.0) {
                        rating = computedRating;
                      }
                    }
                  }

                  final unrepliedReviews = allReviews
                      .where((r) => r.reviewReply == null || r.reviewReply!.trim().isEmpty)
                      .toList();

                  final positiveReviews =
                      allReviews.where((r) => r.starRating >= 4).toList();
                  final negativeReviews =
                      allReviews.where((r) => r.starRating > 0 && r.starRating <= 2).toList();

                  List<GMBReviewItem> displayReviews = allReviews;
                  if (_selectedFilter == 1) displayReviews = unrepliedReviews;
                  if (_selectedFilter == 2) displayReviews = positiveReviews;
                  if (_selectedFilter == 3) displayReviews = negativeReviews;

                  return RefreshIndicator(
                    color: const Color(0xFF4F46E5),
                    onRefresh: () async {
                      ref.invalidate(customerReviewsFamilyProvider(locationId));
                      ref.invalidate(dashboardStatsProvider(locationId));
                      try {
                        await Future.wait([
                          ref.read(customerReviewsFamilyProvider(locationId).future),
                          ref.read(dashboardStatsProvider(locationId).future),
                          ref.read(automationSettingsProvider.notifier).fetchSettings(
                                locationId: activeLocation?.name ?? activeLocation?.id,
                              ),
                        ]);
                      } catch (e) {
                        debugPrint('Refresh error: $e');
                      }
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Header with Active Location Indicator & Auto-Reply Button
                                if (activeLocation != null) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: isDark ? const Color(0xFF3730A3) : const Color(0xFFC7D2FE)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.storefront_rounded,
                                              size: 14,
                                              color: Color(0xFF4F46E5),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              activeLocation.name,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF4F46E5),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _showAutoReplySettingsModal(
                                            context, locationId),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: cardBgColor,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: borderColor),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.auto_awesome,
                                                size: 14,
                                                color: Color(0xFF4F46E5),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Auto-Reply',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                // 1. Overall Rating & Distribution Overview Card
                                _buildReviewsOverviewCard(
                                  context,
                                  rating,
                                  stats.totalReviews > 0
                                      ? stats.totalReviews
                                      : allReviews.length,
                                  allReviews,
                                ),
                                const SizedBox(height: 18),

                                // 2. Filter Chips
                                _buildFilters(
                                  allCount: allReviews.length,
                                  unrepliedCount: unrepliedReviews.length,
                                  positiveCount: positiveReviews.length,
                                  negativeCount: negativeReviews.length,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),

                  // Reviews List
                  if (displayReviews.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                        child: _buildEmptyState(),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _ReviewCard(
                              review: displayReviews[index],
                              locationId: locationId,
                            );
                          },
                          childCount: displayReviews.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            ),
          ),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 40, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading customer reviews: $e',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(customerReviewsFamilyProvider(locationId)),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),
);

    if (!widget.showScaffold) {
      return Material(
        color: Colors.transparent,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: content,
    );
  }

  /// Replicated Overall Rating & Distribution Card from Dashboard Screen
  Widget _buildReviewsOverviewCard(
    BuildContext context,
    double rating,
    int totalCount,
    List<GMBReviewItem> reviews,
  ) {
    final int count5 = reviews.where((r) => r.starRating == 5).length;
    final int count4 = reviews.where((r) => r.starRating == 4).length;
    final int count3 = reviews.where((r) => r.starRating == 3).length;
    final int count2 = reviews.where((r) => r.starRating == 2).length;
    final int count1 = reviews.where((r) => r.starRating == 1).length;

    final int calcTotal = count5 + count4 + count3 + count2 + count1;
    final int baseCount = totalCount > 0 ? totalCount : calcTotal;

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

    final int repliedCount = reviews
        .where((r) => r.reviewReply != null && r.reviewReply!.trim().isNotEmpty)
        .length;

    String avgResponse = '-';
    final repliedReviews = reviews
        .where((r) =>
            r.reviewReply != null &&
            r.createTime.isNotEmpty &&
            r.replyTime != null &&
            r.replyTime!.isNotEmpty)
        .toList();
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                  color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
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
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track and respond to customer reviews',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: textSecondary,
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
                      color: textPrimary,
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

          // Key Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  context: context,
                  icon: Icons.thumb_up_alt_rounded,
                  iconColor: const Color(0xFF10B981),
                  bgColor: const Color(0xFFF0FDF4),
                  label: 'Positive',
                  value: '$positivePercent%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  context: context,
                  icon: Icons.mark_chat_read_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFEFF6FF),
                  label: 'Replied',
                  value: '$repliedCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  context: context,
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFFFBEB),
                  label: 'Avg Speed',
                  value: avgResponse,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarProgressRow(int stars, double pct, int count) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '$stars★',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFFF1F5F9),
              color: stars >= 4
                  ? const Color(0xFF10B981)
                  : (stars == 3 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricPill({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final badgeBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? iconColor.withValues(alpha: 0.12) : bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? iconColor.withValues(alpha: 0.3)
              : iconColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: isDark ? 0.25 : 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: 15, color: iconColor),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1.5),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAutoReplySettingsModal(BuildContext context, String locationId) {
    ref.read(automationSettingsProvider.notifier).fetchSettings(locationId: locationId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildAutoReplySheet(ctx, locationId),
    );
  }

  Widget _buildFilters({
    required int allCount,
    required int unrepliedCount,
    required int positiveCount,
    required int negativeCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildFilterChip('All Reviews ($allCount)', 0),
          _buildFilterChip('Unreplied ($unrepliedCount)', 1),
          _buildFilterChip('Positive ($positiveCount)', 2),
          _buildFilterChip('Negative ($negativeCount)', 3),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int filterIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedFilter == filterIndex;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterIndex),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : borderColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              size: 32,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Reviews Found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'There are no customer reviews matching your selected filter.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  final GMBReviewItem review;
  final String locationId;

  const _ReviewCard({
    required this.review,
    required this.locationId,
  });

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final textBody = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    final review = widget.review;
    final reviewerName = review.reviewerName;
    final profilePhotoUrl = review.reviewerPhoto;
    final starRating = review.starRating;
    final comment = review.comment.trim().isNotEmpty
        ? review.comment.trim()
        : 'Left a rating without a comment.';
    final reply = review.reviewReply;
    final isReplied = reply != null && reply.trim().isNotEmpty;

    String timeAgo = 'Recently';
    if (review.createTime.isNotEmpty) {
      try {
        final time = DateTime.parse(review.createTime);
        final diff = DateTime.now().difference(time);
        if (diff.inDays >= 365) {
          final y = (diff.inDays / 365).floor();
          timeAgo = '$y year${y == 1 ? '' : 's'} ago';
        } else if (diff.inDays >= 30) {
          final m = (diff.inDays / 30).floor();
          timeAgo = '$m month${m == 1 ? '' : 's'} ago';
        } else if (diff.inDays > 0) {
          timeAgo = '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
        } else if (diff.inHours > 0) {
          timeAgo = '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
        } else if (diff.inMinutes > 0) {
          timeAgo = '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
        } else {
          timeAgo = 'Just now';
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                    ? NetworkImage(profilePhotoUrl)
                    : null,
                child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
                    ? Text(
                        reviewerName.isNotEmpty
                            ? reviewerName[0].toUpperCase()
                            : 'A',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF4F46E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < starRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                timeAgo,
                style: GoogleFonts.plusJakartaSans(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            comment,
            style: GoogleFonts.plusJakartaSans(
              color: textBody,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          if (!isReplied)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReplyDialog(
                        context,
                        ref,
                        review.id,
                        comment,
                        isAi: true,
                        reviewerName: reviewerName,
                        rating: starRating,
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 18),
                      label: Text(
                        'Reply with AI',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showReplyDialog(
                    context,
                    ref,
                    review.id,
                    comment,
                    isAi: false,
                  ),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF475569), size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.flag_outlined,
                        color: Color(0xFFEF4444), size: 20),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF15803D), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Replied to Customer',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF15803D),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.chat_bubble_outline_rounded,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.subdirectory_arrow_right_rounded,
                                color: Color(0xFF4F46E5), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Owner Response',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4F46E5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reply,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF334155),
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _showReplyDialog(
    BuildContext context,
    WidgetRef ref,
    String reviewId,
    String originalComment, {
    bool isAi = false,
    int rating = 5,
    String reviewerName = 'Customer',
  }) {
    final textController = TextEditingController();
    bool isGeneratingAi = isAi;
    bool aiGenerationFailed = false;

    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            if (isGeneratingAi) {
              isGeneratingAi = false;
              final ratings = ['ONE', 'TWO', 'THREE', 'FOUR', 'FIVE'];
              final starStr =
                  rating > 0 && rating <= 5 ? ratings[rating - 1] : 'FIVE';

              ref
                  .read(gmbapiRepositoryProvider)
                  .enhanceReviewReply(
                    reviewerName: reviewerName,
                    starRating: starStr,
                    reviewComment: originalComment,
                    locationId: widget.locationId,
                  )
                  .then((generatedText) {
                if (context.mounted) {
                  setState(() {
                    textController.text = generatedText;
                  });
                }
              }).catchError((e) {
                if (context.mounted) {
                  setState(() {
                    aiGenerationFailed = true;
                  });
                }
              });
              isGeneratingAi = true;
            }

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                    isAi
                        ? Icons.auto_awesome_rounded
                        : Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFF4F46E5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAi ? 'AI Generated Reply' : 'Manual Reply',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: isGeneratingAi &&
                        textController.text.isEmpty &&
                        !aiGenerationFailed
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: Color(0xFF4F46E5)),
                            const SizedBox(height: 16),
                            Text(
                              "AI is crafting a personalized response...",
                              style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF64748B), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : TextField(
                        controller: textController,
                        minLines: 4,
                        maxLines: 7,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5),
                        decoration: InputDecoration(
                          hintText: aiGenerationFailed
                              ? 'AI generation failed. Type your reply here...'
                              : 'Type your reply here...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13.5,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF4F46E5), width: 1.5),
                          ),
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final replyText = textController.text.trim();
                          if (replyText.isEmpty) return;

                          setState(() => isSubmitting = true);
                          try {
                            // 1. Try GmbapiRepository
                            try {
                              await ref
                                  .read(gmbapiRepositoryProvider)
                                  .replyToReview(reviewId, replyText);
                            } catch (_) {
                              // 2. Fallback to GMBReviewsRepository
                              await ref
                                  .read(gmbReviewsRepositoryProvider)
                                  .postReply(
                                      reviewName: reviewId, replyText: replyText);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ref.invalidate(
                                  customerReviewsFamilyProvider(widget.locationId));
                              ref.invalidate(
                                  dashboardReviewsProvider(widget.locationId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✨ Reply posted successfully!'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to post reply: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Post Reply',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

Widget _buildAutoReplySheet(BuildContext context, String locationId) {
  return AutoReplySettingsModalSheet(
    key: ValueKey('auto_reply_sheet_$locationId'),
    locationId: locationId,
  );
}

class AutoReplySettingsModalSheet extends ConsumerWidget {
  final String locationId;

  const AutoReplySettingsModalSheet({super.key, required this.locationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(automationSettingsProvider);
    final controller = ref.read(automationSettingsProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle indicator bar
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Row with Icon and Close Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: AppColors.primaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Review Auto-Reply',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Automatically respond to incoming customer reviews.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active Switch Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automation Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.autoReviewReply ? 'Active & monitoring' : 'Off',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: settings.autoReviewReply
                              ? const Color(0xFF15803D)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: settings.autoReviewReply,
                    onChanged: controller.setAutoReviewReply,
                    activeThumbColor: AppColors.primaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Star Rating Range Dropdowns
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Minimum Rating',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: const Color(0xFF475569))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: settings.minStars,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          items: [1, 2, 3, 4, 5].map((s) {
                            return DropdownMenuItem<int>(
                              value: s,
                              child: Text('$s ★',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13, fontWeight: FontWeight.w700)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.setMinStars(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Maximum Rating',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: const Color(0xFF475569))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: settings.maxStars,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          items: [1, 2, 3, 4, 5].map((s) {
                            return DropdownMenuItem<int>(
                              value: s,
                              child: Text('$s ★',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13, fontWeight: FontWeight.w700)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) controller.setMaxStars(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Only reviews within this star rating range will receive auto-replies.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Written Comment Only Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Only Reply to Written Comments',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                            'Ignore reviews that only leave a star rating without text.',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.onlyWithComments,
                    onChanged: controller.setOnlyWithComments,
                    activeThumbColor: AppColors.primaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save Rules Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: settings.isSaving
                      ? null
                      : () async {
                          final success = await controller.saveSettings(
                            locationId: locationId,
                          );
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('✨ Auto-Reply Settings saved & synced!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                  icon: settings.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    settings.isSaving
                        ? 'Saving Auto-Reply Rules...'
                        : 'Save Auto-Reply Rules',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800, fontSize: 13),
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
