import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/gmb_analytics_repository.dart';
import '../../../data/repositories/gmb_reviews_repository.dart';
import '../reviews_screen.dart';

class ReviewsOverviewCard extends StatelessWidget {
  final GMBLocationStats? stats;
  final List<GMBReviewItem>? reviews;
  final VoidCallback? onSeeAll;

  const ReviewsOverviewCard({
    super.key,
    this.stats,
    this.reviews,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final reviewList = reviews ?? [];
    final totalCount = reviewList.isNotEmpty ? reviewList.length : (stats?.totalReviews ?? 3);
    final rating = stats?.averageRating != null && stats!.averageRating > 0
        ? stats!.averageRating
        : 5.0;

    int c5 = 0, c4 = 0, c3 = 0, c2 = 0, c1 = 0;
    int repliedCount = 0;
    if (reviewList.isNotEmpty) {
      for (final r in reviewList) {
        if (r.starRating == 5) c5++;
        if (r.starRating == 4) c4++;
        if (r.starRating == 3) c3++;
        if (r.starRating == 2) c2++;
        if (r.starRating == 1) c1++;
        if (r.reviewReply != null && r.reviewReply!.isNotEmpty) repliedCount++;
      }
    } else {
      c5 = totalCount;
      repliedCount = totalCount;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviews Overview',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF131B2E),
                ),
              ),
              InkWell(
                onTap: onSeeAll ??
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ReviewsScreen()),
                      );
                    },
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4A07E8),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF4A07E8)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Responsive Content Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;

              if (isNarrow) {
                // Stacked 2-Row Layout for narrow devices
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildScoreColumn(rating, totalCount),
                        _buildMiniBadgesGrid(totalCount, repliedCount),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        _buildStarBar(5, c5, totalCount),
                        _buildStarBar(4, c4, totalCount),
                        _buildStarBar(3, c3, totalCount),
                        _buildStarBar(2, c2, totalCount),
                        _buildStarBar(1, c1, totalCount),
                      ],
                    ),
                  ],
                );
              }

              // Side-by-side 2-Column Layout for standard mobile screens
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildScoreColumn(rating, totalCount),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        _buildStarBar(5, c5, totalCount),
                        _buildStarBar(4, c4, totalCount),
                        _buildStarBar(3, c3, totalCount),
                        _buildStarBar(2, c2, totalCount),
                        _buildStarBar(1, c1, totalCount),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildMiniBadgesGrid(totalCount, repliedCount),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(double rating, int totalCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF131B2E),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5,
            (index) => const Icon(
              Icons.star_rounded,
              size: 13,
              color: Color(0xFFF59E0B),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Excellent',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Based on $totalCount reviews',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadgesGrid(int totalCount, int repliedCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniReviewBadge(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: const Color(0xFF7C3AED),
              value: '$totalCount',
              label: 'Total',
            ),
            const SizedBox(width: 6),
            _buildMiniReviewBadge(
              icon: Icons.thumb_up_alt_rounded,
              iconColor: const Color(0xFF16A34A),
              value: '100%',
              label: 'Positive',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniReviewBadge(
              icon: Icons.reply_rounded,
              iconColor: const Color(0xFF0284C7),
              value: '$repliedCount',
              label: 'Replied',
            ),
            const SizedBox(width: 6),
            _buildMiniReviewBadge(
              icon: Icons.access_time_rounded,
              iconColor: const Color(0xFFEA580C),
              value: '4h',
              label: 'Avg. Resp',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStarBar(int star, int count, int total) {
    final factor = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            '$star',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF131B2E),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF59E0B)),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 4, color: const Color(0xFFF1F5F9)),
                  FractionallySizedBox(
                    widthFactor: factor,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A07E8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 10,
            child: Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniReviewBadge({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: iconColor),
              const SizedBox(width: 3),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF131B2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
