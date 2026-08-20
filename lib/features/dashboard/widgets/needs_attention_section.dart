import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../autonomy/presentation/ai_control_screen.dart';
import '../../business_flow/business_profile_screen.dart';

class NeedsAttentionSection extends StatelessWidget {
  final int alertCount;
  final VoidCallback? onFixSeo;

  const NeedsAttentionSection({
    super.key,
    this.alertCount = 2,
    this.onFixSeo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Needs your attention',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF131B2E),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AIControlScreen()),
                );
              },
              child: Row(
                children: [
                  Text(
                    '$alertCount alerts',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFEF4444)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Alert Item 1: SEO Health Drop
        _buildAlertCard(
          context: context,
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFEA580C),
          iconBgColor: const Color(0xFFFFF7ED),
          title: 'Local SEO health dropped to 80',
          subtitle: '2 improvements can boost visibility',
          buttonText: 'Fix now',
          buttonTextColor: const Color(0xFFC2410C),
          buttonBgColor: const Color(0xFFFFEDD5),
          onTap: onFixSeo ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
                );
              },
        ),
        const SizedBox(height: 10),

        // Alert Item 2: Post Awaiting Approval
        _buildAlertCard(
          context: context,
          icon: Icons.edit_note_rounded,
          iconColor: const Color(0xFF7C3AED),
          iconBgColor: const Color(0xFFF5F3FF),
          title: '1 post awaiting approval',
          subtitle: 'Review and approve to publish',
          buttonText: 'Review now',
          buttonTextColor: const Color(0xFF6D28D9),
          buttonBgColor: const Color(0xFFEDE9FE),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AIControlScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonTextColor,
    required Color buttonBgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action Button Pill
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: buttonBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buttonText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: buttonTextColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 13,
                    color: buttonTextColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
