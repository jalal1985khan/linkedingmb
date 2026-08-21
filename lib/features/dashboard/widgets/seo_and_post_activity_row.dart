import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/gmb_analytics_repository.dart';
import '../../business_flow/business_profile_screen.dart';
import '../../posts/published_posts_screen.dart';
import '../../scheduler/queue_screen.dart';

class SeoAndPostActivityRow extends StatelessWidget {
  final PostActivityStats? postActivity;
  final String locationId;
  final VoidCallback? onViewRecommendations;

  const SeoAndPostActivityRow({
    super.key,
    this.postActivity,
    required this.locationId,
    this.onViewRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Render 2-column or stacked vertically if compact
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLocalSeoCard(context)),
              const SizedBox(width: 14),
              Expanded(child: _buildPostActivityCard(context)),
            ],
          );
        }

        return Column(
          children: [
            _buildLocalSeoCard(context),
            const SizedBox(height: 14),
            _buildPostActivityCard(context),
          ],
        );
      },
    );
  }

  // Local SEO Health Card
  Widget _buildLocalSeoCard(BuildContext context) {
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
          // Header: Icon + Title + Score Badge
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 6),
              Text(
                'Local SEO Health',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF131B2E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '80 / 100',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Good • 2 improvements available',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),

          // Mini Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 5, width: double.infinity, color: const Color(0xFFF1F5F9)),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Container(
                    height: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Improvement 1: Missing cover photo
          _buildImprovementItem(
            icon: Icons.photo_size_select_actual_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Missing cover photo',
            subtitle: 'Add a high quality cover photo',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 8),

          // Improvement 2: Missing business attributes
          _buildImprovementItem(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Missing business attributes',
            subtitle: 'Add 3 attributes to improve ranking',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
              );
            },
          ),
          const SizedBox(height: 14),

          // View Recommendations Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewRecommendations ??
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
                    );
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A07E8),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'View Recommendations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF131B2E),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // Post Activity Card
  Widget _buildPostActivityCard(BuildContext context) {
    final activity = postActivity ?? const PostActivityStats();
    final aiGenerated = activity.aiGenerated;
    final manual = activity.manualGenerated;
    final inQueue = activity.queued;
    final published = activity.posted;

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
          // Header: Icon + Title + Timeframe
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 18),
              const SizedBox(width: 6),
              Text(
                'Post Activity',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF131B2E),
                ),
              ),
              const Spacer(),
              Text(
                'Last 30 days ⌄',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Sub-metrics
          Row(
            children: [
              Expanded(
                child: _buildSubMetricBox(
                  value: '$aiGenerated',
                  label: 'AI Generated',
                  icon: Icons.auto_awesome_rounded,
                  iconColor: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSubMetricBox(
                  value: '$manual',
                  label: 'Manual',
                  icon: Icons.edit_outlined,
                  iconColor: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSubMetricBox(
                  value: '$inQueue',
                  label: 'In Queue',
                  icon: Icons.access_time_rounded,
                  iconColor: const Color(0xFF0284C7),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QueueScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSubMetricBox(
                  value: '$published',
                  label: 'Published',
                  icon: Icons.send_rounded,
                  iconColor: const Color(0xFF16A34A),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PublishedPostsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // View All Posts Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PublishedPostsScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4A07E8),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                backgroundColor: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'View All Posts',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetricBox({
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF131B2E),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 12, color: iconColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
    );
  }
}
