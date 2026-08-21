import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/repositories/gmb_analytics_repository.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../notifications/notification_end_drawer.dart';
import 'competitor_analysis_screen.dart';
import 'widgets/dashboard_header_bar.dart';

final selectedTimeframeProvider = StateProvider.autoDispose<String>((ref) => 'Weekly');
final selectedDayIndexProvider = StateProvider.autoDispose<int>((ref) => 3); // Default Tuesday (index 3)

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
                  Scaffold.maybeOf(context)?.openEndDrawer();
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
                      // 1. Hero Performance Banner Card
                      _buildHeroBannerCard(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                      const SizedBox(height: 14),

                      // 2. Timeframe Switcher & Date Range Row
                      Row(
                        children: [
                          // Left: Segmented Tabs (Weekly / Monthly / Yearly)
                          Expanded(
                            flex: 5,
                            child: Container(
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
                                  Expanded(child: _buildSegment('Weekly', selectedTimeframe == 'Weekly', ref, isDark, textPrimary, textSecondary)),
                                  Expanded(child: _buildSegment('Monthly', selectedTimeframe == 'Monthly', ref, isDark, textPrimary, textSecondary)),
                                  Expanded(child: _buildSegment('Yearly', selectedTimeframe == 'Yearly', ref, isDark, textPrimary, textSecondary)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Right: Date Range Dropdown Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 14, color: textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  selectedTimeframe == 'Monthly' ? 'Last 30 days' : (selectedTimeframe == 'Yearly' ? 'Last 12 months' : 'Last 7 days'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textSecondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stats State handling
                      statsAsync.when(
                        data: (stats) => Column(
                          children: [
                            // 3. 2x2 Metric KPI Grid Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildKpiGridCard(
                                    label: 'Views',
                                    value: '${stats.views > 0 ? stats.views : stats.totalImpressions}',
                                    trendText: '↑ 12%',
                                    trendColor: const Color(0xFF16A34A),
                                    trendBg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                                    trendBorder: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC),
                                    periodText: 'vs last 7 days',
                                    icon: Icons.visibility_rounded,
                                    iconColor: const Color(0xFF6366F1),
                                    iconBg: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                                    sparklineColor: const Color(0xFF6366F1),
                                    isDark: isDark,
                                    cardBgColor: cardBgColor,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildKpiGridCard(
                                    label: 'Call Clicks',
                                    value: '${stats.calls}',
                                    trendText: stats.callsChange.isNotEmpty ? stats.callsChange : '— 0%',
                                    trendColor: const Color(0xFF15803D),
                                    trendBg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                                    trendBorder: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC),
                                    periodText: 'vs last 7 days',
                                    icon: Icons.phone_rounded,
                                    iconColor: const Color(0xFF16A34A),
                                    iconBg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                                    sparklineColor: const Color(0xFF10B981),
                                    isDark: isDark,
                                    cardBgColor: cardBgColor,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildKpiGridCard(
                                    label: 'Direction Requests',
                                    value: '${stats.directionRequests}',
                                    trendText: stats.directionsChange.isNotEmpty ? stats.directionsChange : '↓ 66.7%',
                                    trendColor: const Color(0xFFDC2626),
                                    trendBg: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.5) : const Color(0xFFFEE2E2),
                                    trendBorder: isDark ? const Color(0xFFB91C1C) : const Color(0xFFFCA5A5),
                                    periodText: 'vs last 7 days',
                                    icon: Icons.directions_rounded,
                                    iconColor: const Color(0xFF0284C7),
                                    iconBg: isDark ? const Color(0xFF075985).withValues(alpha: 0.5) : const Color(0xFFE0F2FE),
                                    sparklineColor: const Color(0xFF0EA5E9),
                                    isDark: isDark,
                                    cardBgColor: cardBgColor,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildKpiGridCard(
                                    label: 'Website Visits',
                                    value: '${stats.websiteClicks}',
                                    trendText: stats.websiteClicksChange.isNotEmpty ? stats.websiteClicksChange : '— 0%',
                                    trendColor: const Color(0xFF15803D),
                                    trendBg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                                    trendBorder: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC),
                                    periodText: 'vs last 7 days',
                                    icon: Icons.language_rounded,
                                    iconColor: const Color(0xFFE11D48),
                                    iconBg: isDark ? const Color(0xFF881337).withValues(alpha: 0.5) : const Color(0xFFFFE4E6),
                                    sparklineColor: const Color(0xFFF43F5E),
                                    isDark: isDark,
                                    cardBgColor: cardBgColor,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 4. Total Impressions & Dynamic Tooltip Bar Chart Card
                            _buildTotalImpressionsCard(
                              ref: ref,
                              stats: stats,
                              timeframe: selectedTimeframe,
                              isDark: isDark,
                              cardBgColor: cardBgColor,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),
                            const SizedBox(height: 16),

                            // 5. Dark Competitor Rank Card
                            _buildCompetitorRankCard(
                              context: context,
                              stats: stats,
                              isDark: isDark,
                              borderColor: borderColor,
                            ),
                          ],
                        ),
                        loading: () => _buildLoadingSkeleton(isDark, cardBgColor, borderColor),
                        error: (err, stack) => _buildErrorCard(err, ref, isDark, cardBgColor, borderColor, textPrimary, textSecondary),
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

    if (!showScaffold) {
      return body;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: body,
    );
  }

  // 1. Hero Performance Banner Card
  Widget _buildHeroBannerCard(bool isDark, Color cardBgColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track how your business is performing',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Real-time data to help you grow smarter.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Trend Graphic & Arrow Action
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_upward_rounded, size: 19, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 2. Segmented Pill Tab
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
        padding: const EdgeInsets.symmetric(vertical: 9),
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
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  // 3. 2x2 Metric KPI Grid Card with Sparkline Wave Graph
  Widget _buildKpiGridCard({
    required String label,
    required String value,
    required String trendText,
    required Color trendColor,
    required Color trendBg,
    required Color trendBorder,
    required String periodText,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color sparklineColor,
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
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
          // Top Row: Icon + Label & Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Trend Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: trendBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: trendBorder),
                ),
                child: Text(
                  trendText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: trendColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  periodText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sparkline Wave Graphic
          SizedBox(
            height: 26,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(color: sparklineColor),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Total Impressions & Dynamic Tooltip Bar Chart Card
  Widget _buildTotalImpressionsCard({
    required WidgetRef ref,
    required GMBLocationStats stats,
    required String timeframe,
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final selectedDayIndex = ref.watch(selectedDayIndexProvider);
    final periodLabel = timeframe == 'Weekly'
        ? 'vs last week'
        : timeframe == 'Monthly'
            ? 'vs last month'
            : 'vs last year';

    final defaultLabels = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final labels = stats.chartLabels.isNotEmpty ? stats.chartLabels : defaultLabels;
    final heights = stats.chartHeights.isNotEmpty
        ? stats.chartHeights
        : [0.35, 0.95, 0.70, 0.40, 0.30, 0.50, 0.35];

    return Container(
      padding: const EdgeInsets.all(18),
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
          // Header Row: Title & View Details
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.show_chart_rounded, size: 14, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 8),
              Text(
                'Total Impressions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 14, color: textSecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Large Metric Value + Trend Badge Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.5) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFFB91C1C) : const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  '↓ 33.3% $periodLabel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Real-time Google Business search & maps views',
                style: GoogleFonts.plusJakartaSans(
                  color: textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 7-Bar Chart with Floating Tooltip Badge on Selected Bar
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(labels.length, (index) {
                final heightFactor = (index < heights.length ? heights[index] : 0.4).clamp(0.18, 1.0);
                final label = labels[index];
                final isSelected = index == selectedDayIndex;

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedDayIndexProvider.notifier).state = index;
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Floating Tooltip Badge for selected bar
                      if (isSelected) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '↓ 2',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        CustomPaint(
                          size: const Size(1, 10),
                          painter: _DottedLinePainter(color: const Color(0xFF4F46E5)),
                        ),
                      ] else ...[
                        const SizedBox(height: 28),
                      ],

                      // Bar Column
                      Container(
                        width: 32,
                        height: 90 * heightFactor,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : (isDark ? const Color(0xFF312E81).withValues(alpha: 0.4) : const Color(0xFFDDD6FE)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Day Label
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          color: isSelected ? const Color(0xFF4F46E5) : textSecondary,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Dark Competitor Rank Card
  Widget _buildCompetitorRankCard({
    required BuildContext context,
    required GMBLocationStats stats,
    required bool isDark,
    required Color borderColor,
  }) {
    final competitorsList = stats.competitors.isNotEmpty
        ? stats.competitors
        : [
            const CompetitorItem(name: 'Illucus – Creative Marketing Agency | Bangalore', rating: 4.9, reviewCount: 167, position: 1),
            const CompetitorItem(name: 'Monaqo – Full-Funnel Growth Marketing Agency', rating: 4.9, reviewCount: 158, position: 2),
            const CompetitorItem(name: 'Mathew Digital Marketing Agency Bangalore', rating: 4.8, reviewCount: 155, position: 3),
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
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
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Competitor Rank',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Based on local search visibility',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  stats.competitorRank ?? 'Unranked',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Competitors List with Ranking numbers, logos, and chevrons
          ...competitorsList.take(3).map((comp) {
            final position = comp.position ?? (competitorsList.indexOf(comp) + 1);
            final initial = comp.name.isNotEmpty ? comp.name.substring(0, 1).toUpperCase() : 'C';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  // Position Circle Badge
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$position',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Avatar Circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Competitor Title & Stats
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${comp.rating ?? 4.9} ★  •  ${comp.reviewCount ?? 150} reviews',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Chevron
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF64748B)),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // View Full Competitor Analysis Button
          SizedBox(
            width: double.infinity,
            height: 46,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Full Competitor Analysis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
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

// Sparkline Painter for smooth wave graph
class _SparklinePainter extends CustomPainter {
  final Color color;

  const _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.7);
    path.cubicTo(w * 0.2, h * 0.2, w * 0.3, h * 0.85, w * 0.5, h * 0.5);
    path.cubicTo(w * 0.7, h * 0.15, w * 0.85, h * 0.8, w * 0.96, h * 0.3);

    canvas.drawPath(path, paint);

    // Draw end point dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.96, h * 0.3), 3.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Dotted Line Painter for tooltip connector
class _DottedLinePainter extends CustomPainter {
  final Color color;

  const _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    const dashHeight = 2.0;
    const dashSpace = 2.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
