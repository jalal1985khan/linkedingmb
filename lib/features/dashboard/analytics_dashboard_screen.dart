import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/repositories/gmb_analytics_repository.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../notifications/notification_end_drawer.dart';
import 'competitor_analysis_screen.dart';
import 'widgets/dashboard_header_bar.dart';

final selectedTimeframeProvider = StateProvider.autoDispose<String>((ref) => 'Weekly');

final gmbAnalyticsProvider = FutureProvider.autoDispose<GMBLocationStats>((ref) async {
  final activeLoc = ref.watch(activeLocationProvider).activeLocation;
  if (activeLoc == null) return const GMBLocationStats();
  final timeframe = ref.watch(selectedTimeframeProvider);
  final repo = GMBAnalyticsRepository();
  return repo.fetchStats(activeLoc.id, timeframe: timeframe);
});

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  GlobalKey<ScaffoldState>? _scaffoldKey;

  @override
  void initState() {
    super.initState();
    _scaffoldKey ??= GlobalKey<ScaffoldState>();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldKey = _scaffoldKey ??= GlobalKey<ScaffoldState>();
    final activeLoc = ref.watch(activeLocationProvider).activeLocation;

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

    final selectedTimeframe = ref.watch(selectedTimeframeProvider);
    final statsAsync = ref.watch(gmbAnalyticsProvider);

    final body = Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Standard Unified DashboardHeaderBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
              child: DashboardHeaderBar(
                title: 'Performance Insights',
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

            // 2. Main Scrollable Analytics Content
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF4F46E5),
                onRefresh: () async {
                  ref.invalidate(gmbAnalyticsProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle Description Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.analytics_rounded, size: 20, color: Color(0xFF4F46E5)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Track your business growth, customer interactions, and engagement metrics in real-time.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Segmented Control (Weekly / Monthly / Yearly)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _buildSegment('Weekly', selectedTimeframe == 'Weekly', isDark, textPrimary, textSecondary)),
                            Expanded(child: _buildSegment('Monthly', selectedTimeframe == 'Monthly', isDark, textPrimary, textSecondary)),
                            Expanded(child: _buildSegment('Yearly', selectedTimeframe == 'Yearly', isDark, textPrimary, textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

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
                            const SizedBox(height: 14),

                            // Metric Cards
                            _buildMetricCard(
                              icon: Icons.phone_rounded,
                              iconColor: const Color(0xFF4F46E5),
                              iconBg: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                              value: '${stats.calls}',
                              label: 'Call Clicks',
                              change: stats.callsChange,
                              changeColor: const Color(0xFF15803D),
                              changeBg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7),
                              isDark: isDark,
                              cardBgColor: cardBgColor,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              icon: Icons.directions_rounded,
                              iconColor: const Color(0xFF0D9488),
                              iconBg: isDark ? const Color(0xFF134E4A).withValues(alpha: 0.5) : const Color(0xFFCCFBF1),
                              value: '${stats.directionRequests}',
                              label: 'Direction Requests',
                              change: stats.directionsChange,
                              changeColor: const Color(0xFF15803D),
                              changeBg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7),
                              isDark: isDark,
                              cardBgColor: cardBgColor,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              icon: Icons.language_rounded,
                              iconColor: const Color(0xFFE11D48),
                              iconBg: isDark ? const Color(0xFF881337).withValues(alpha: 0.5) : const Color(0xFFFFE4E6),
                              value: '${stats.websiteClicks}',
                              label: 'Website Visits',
                              change: stats.websiteClicksChange,
                              changeColor: const Color(0xFF15803D),
                              changeBg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7),
                              isDark: isDark,
                              cardBgColor: cardBgColor,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(height: 16),

                            // Competitor Rank Card
                            _buildCompetitorRankCard(
                              context: context,
                              stats: stats,
                              isDark: isDark,
                              cardBgColor: cardBgColor,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                          ],
                        ),
                        loading: () => _buildLoadingSkeleton(isDark, cardBgColor, borderColor),
                        error: (err, stack) => _buildErrorCard(err, isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: body,
    );
  }

  Widget _buildSegment(
    String title,
    bool isSelected,
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
              ? const Color(0xFF4F46E5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : textSecondary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.show_chart_rounded, size: 13, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 8),
              Text(
                'TOTAL IMPRESSIONS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6366F1),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                '${stats.totalImpressions}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.impressionsChange} $periodLabel',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Real-time Google Business search & maps views',
                  style: GoogleFonts.plusJakartaSans(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dynamic Bar Chart
          SizedBox(
            height: 130,
            child: stats.chartHeights.isEmpty
                ? Center(
                    child: Text(
                      'Google has not returned performance data for this listing yet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Row(
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
          height: 90 * heightFactor,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4F46E5)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isActive ? const Color(0xFF4F46E5) : textSecondary,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
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
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: changeBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              change,
              style: GoogleFonts.plusJakartaSans(
                color: changeColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorRankCard({
    required BuildContext context,
    required GMBLocationStats stats,
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final competitorsList = stats.competitors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Competitor Rank',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Based on local search visibility',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  stats.competitorRank ?? 'Unranked',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (competitorsList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No local pack results available for this category and city yet.',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...competitorsList.map((comp) {
              final details = <String>[
                if (comp.position != null) 'Position ${comp.position}',
                if (comp.rating != null) '${comp.rating} ★',
                if (comp.reviewCount != null) '${comp.reviewCount} reviews',
              ].join('  ·  ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comp.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (details.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              details,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CompetitorAnalysisScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'View Full Competitor Analysis',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(
    Object error,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFDC2626)),
          const SizedBox(height: 12),
          Text(
            'Unable to Load Performance Stats',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Could not retrieve live metrics for this location.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(gmbAnalyticsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              'Retry',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
