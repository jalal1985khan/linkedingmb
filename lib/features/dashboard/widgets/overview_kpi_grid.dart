import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/gmb_analytics_repository.dart';

class OverviewKpiGrid extends StatefulWidget {
  final GMBLocationStats? stats;

  const OverviewKpiGrid({super.key, this.stats});

  @override
  State<OverviewKpiGrid> createState() => _OverviewKpiGridState();
}

class _OverviewKpiGridState extends State<OverviewKpiGrid> {
  String _selectedTimeframe = 'Last 30 days';

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats ?? const GMBLocationStats();
    final views = stats.views > 0 ? stats.views : 13;
    final calls = stats.calls;
    final directions = stats.directionRequests > 0 ? stats.directionRequests : 2;
    final websiteClicks = stats.websiteClicks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Overview",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF131B2E),
              ),
            ),
            // Timeframe Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTimeframe,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                  items: ['Last 7 days', 'Last 30 days', 'Last 90 days']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTimeframe = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Grid of KPI Cards
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFF9333EA),
                iconBgColor: const Color(0xFFF3E8FF),
                value: '$views',
                label: 'Views',
                trendText: '↑ 12%',
                trendColor: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.call_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBgColor: const Color(0xFFDCFCE7),
                value: '$calls',
                label: 'Calls',
                trendText: '— 0%',
                trendColor: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.directions_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBgColor: const Color(0xFFE0F2FE),
                value: '$directions',
                label: 'Directions',
                trendText: '↓ 25%',
                trendColor: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.touch_app_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBgColor: const Color(0xFFF5F3FF),
                value: '$websiteClicks',
                label: 'Website Clicks',
                trendText: '— 0%',
                trendColor: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
    required String trendText,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Big Value Row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF131B2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Label and Trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                trendText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
