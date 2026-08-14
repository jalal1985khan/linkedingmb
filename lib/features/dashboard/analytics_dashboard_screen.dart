import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/gmb_analytics_repository.dart';
import '../business_flow/providers/active_location_provider.dart';

final selectedTimeframeProvider = StateProvider.autoDispose<String>((ref) => 'Weekly');

final gmbAnalyticsProvider = FutureProvider.autoDispose<GMBLocationStats>((ref) async {
  final activeLoc = ref.watch(activeLocationProvider).activeLocation;
  if (activeLoc == null) return const GMBLocationStats();
  final timeframe = ref.watch(selectedTimeframeProvider);
  final repo = GMBAnalyticsRepository();
  return repo.fetchStats(activeLoc.id, timeframe: timeframe);
});

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final selectedTimeframe = ref.watch(selectedTimeframeProvider);
    final statsAsync = ref.watch(gmbAnalyticsProvider);

    final body = SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gmbAnalyticsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Insights',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Track your business growth, customer interactions, and engagement metrics in real-time.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Segmented Control (Weekly / Monthly / Yearly)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildSegment('Weekly', selectedTimeframe == 'Weekly', ref, isDark, textPrimary, textSecondary)),
                    Expanded(child: _buildSegment('Monthly', selectedTimeframe == 'Monthly', ref, isDark, textPrimary, textSecondary)),
                    Expanded(child: _buildSegment('Yearly', selectedTimeframe == 'Yearly', ref, isDark, textPrimary, textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stats Async State handling
              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    // Total Impressions Card
                    _buildImpressionsCard(
                      stats: stats,
                      timeframe: selectedTimeframe,
                      isDark: isDark,
                      cardBgColor: cardBgColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 16),

                    // Metric Cards
                    _buildMetricCard(
                      icon: Icons.phone_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primary.withValues(alpha: 0.12),
                      value: '${stats.calls}',
                      label: 'Call Clicks',
                      change: stats.callsChange,
                      changeColor: const Color(0xFF0D9488),
                      changeBg: isDark ? const Color(0xFF115E59).withValues(alpha: 0.3) : const Color(0xFFCCFBF1),
                      isDark: isDark,
                      cardBgColor: cardBgColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),
                    _buildMetricCard(
                      icon: Icons.directions_rounded,
                      iconColor: const Color(0xFF0D9488),
                      iconBg: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      value: '${stats.directionRequests}',
                      label: 'Direction Requests',
                      change: stats.directionsChange,
                      changeColor: const Color(0xFF0D9488),
                      changeBg: isDark ? const Color(0xFF115E59).withValues(alpha: 0.3) : const Color(0xFFCCFBF1),
                      isDark: isDark,
                      cardBgColor: cardBgColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 14),
                    _buildMetricCard(
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFFE11D48),
                      iconBg: const Color(0xFFE11D48).withValues(alpha: 0.12),
                      value: '${stats.websiteClicks}',
                      label: 'Website Visits',
                      change: stats.websiteClicksChange,
                      changeColor: const Color(0xFF0D9488),
                      changeBg: isDark ? const Color(0xFF115E59).withValues(alpha: 0.3) : const Color(0xFFCCFBF1),
                      isDark: isDark,
                      cardBgColor: cardBgColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 20),

                    // Competitor Rank Card
                    _buildCompetitorRankCard(
                      stats: stats,
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                  ],
                ),
                loading: () => _buildLoadingSkeleton(isDark, cardBgColor, borderColor),
                error: (err, stack) => _buildErrorCard(err, ref, isDark, cardBgColor, borderColor, textPrimary, textSecondary),
              ),
              const SizedBox(height: 80), // Padding for shell bottom nav
            ],
          ),
        ),
      ),
    );

    if (!showScaffold) {
      return Container(color: bgColor, child: body);
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: body,
    );
  }

  Widget _buildSegment(
    String title,
    bool isSelected,
    WidgetRef ref,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedTimeframeProvider.notifier).state = title;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: isSelected ? AppColors.primary : textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildImpressionsCard({
    required GMBLocationStats stats,
    required String timeframe,
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final periodLabel = timeframe == 'Weekly'
        ? 'vs last week'
        : timeframe == 'Monthly'
            ? 'vs last month'
            : 'vs last year';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL IMPRESSIONS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stats.totalImpressions}',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF115E59).withValues(alpha: 0.4) : const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Color(0xFF0D9488), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.impressionsChange} $periodLabel',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0D9488),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Real-time Google Business search & maps views',
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Dynamic Bar Chart
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                stats.chartHeights.length,
                (index) {
                  final heightFactor = stats.chartHeights[index].clamp(0.15, 1.0);
                  final label = index < stats.chartLabels.length ? stats.chartLabels[index] : '';
                  final isActive = index == (stats.chartHeights.length / 2).floor();
                  return _buildChartBar(heightFactor, isActive, label, isDark, textSecondary);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(
    double heightFactor,
    bool isActive,
    String label,
    bool isDark,
    Color textSecondary,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 100 * heightFactor,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? AppColors.primary : textSecondary,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
    required String change,
    required Color changeColor,
    required Color changeBg,
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: changeBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              change,
              style: GoogleFonts.inter(
                color: changeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorRankCard({
    required GMBLocationStats stats,
    required bool isDark,
    required Color borderColor,
  }) {
    final competitorsList = stats.competitors.isNotEmpty
        ? stats.competitors
        : const [
            CompetitorItem(name: 'Urban Brew Coffee', matchPercentage: 98),
            CompetitorItem(name: 'City Roast & Co.', matchPercentage: 82),
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark navy container
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Competitor Rank',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Based on local search visibility',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stats.competitorRank,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Competitors List
          ...competitorsList.map((comp) {
            final percentage = comp.matchPercentage / 100.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comp.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${comp.matchPercentage}% Match',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage.clamp(0.05, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), AppColors.primary],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'View Full Competitor Analysis',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark, Color cardBgColor, Color borderColor) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(
    Object error,
    WidgetRef ref,
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'Unable to Load Performance Stats',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Could not retrieve live metrics for this location.',
            style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(gmbAnalyticsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
