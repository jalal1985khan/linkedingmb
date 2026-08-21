import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../business_flow/providers/active_location_provider.dart';
import '../dashboard/widgets/dashboard_header_bar.dart';
import '../notifications/notification_end_drawer.dart';
import '../shell/providers/shell_nav_provider.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLocation = ref.watch(activeLocationProvider).activeLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
                child: DashboardHeaderBar(
                  title: 'Active Services',
                  subtitle: activeLocation?.name ?? 'SocialHive',
                  showSparkle: true,
                  showBackButton: true,
                  onBack: () => ref.handleSmartBack(context),
                  onOpenNotifications: () {
                    Scaffold.maybeOf(context)?.openEndDrawer();
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Intro Description Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16),
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.business_center_rounded, color: Color(0xFF4F46E5), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Service Catalog & Bookings',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Manage professional offerings synced with Google Search & Maps.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section Title: Performance Snapshot
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF4F46E5), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PERFORMANCE SNAPSHOT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textSecondary,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2x2 Metric KPI Cards Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.28,
                        children: [
                          _buildStatCard(
                            title: 'Total Bookings',
                            value: '8,432',
                            subLabel: 'Daily Avg: 280',
                            icon: Icons.calendar_month_rounded,
                            isDark: isDark,
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          _buildStatCard(
                            title: 'Revenue',
                            value: '\$14.2k',
                            pillText: '↑ 21%',
                            pillColor: const Color(0xFF16A34A),
                            icon: Icons.attach_money_rounded,
                            isDark: isDark,
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          _buildStatCard(
                            title: 'Unique Views',
                            value: '1,284',
                            pillText: '↑ 8%',
                            pillColor: const Color(0xFF16A34A),
                            icon: Icons.visibility_rounded,
                            isDark: isDark,
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                          _buildStatCard(
                            title: 'Conversion Rate',
                            value: '3.8%',
                            hasProgress: true,
                            icon: Icons.trending_up_rounded,
                            isDark: isDark,
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Section Title: Service Offerings
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF4F46E5), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'FEATURED OFFERINGS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textSecondary,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Service Card 1
                      _buildServiceCard(
                        title: 'Latte Art Workshop',
                        imageUrl: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=500&q=80',
                        priceTag: '\$85 / Person',
                        subtitle: '60 min • Individual or Groups',
                        stat1Icon: Icons.calendar_today_rounded,
                        stat1Text: '12 Booked Today',
                        stat2Icon: Icons.star_rounded,
                        stat2Text: '4.9 (124 reviews)',
                        stat2Color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 16),

                      // Service Card 2
                      _buildServiceCard(
                        title: 'Organic Beans Subscription',
                        imageUrl: 'https://images.unsplash.com/photo-1559525839-b184a4d698c7?w=500&q=80',
                        priceTag: '\$45 / Month',
                        subtitle: 'Monthly • Recurring Revenue',
                        stat1Icon: Icons.people_alt_rounded,
                        stat1Text: '442 Active Members',
                        stat2Icon: Icons.trending_up_rounded,
                        stat2Text: '+12% Monthly Growth',
                        stat2Color: const Color(0xFF16A34A),
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 24),

                      // Scale Your Catalog Promo Banner
                      _buildScaleCatalogCard(isDark, cardBgColor, borderColor, textPrimary, textSecondary),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subLabel,
    String? pillText,
    Color? pillColor,
    bool hasProgress = false,
    required IconData icon,
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 6,
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
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: textSecondary),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          if (subLabel != null)
            Text(
              subLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (pillText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                pillText,
                style: GoogleFonts.plusJakartaSans(
                  color: pillColor ?? const Color(0xFF16A34A),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (hasProgress) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Expanded(
                    flex: 38,
                    child: Container(
                      height: 5,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                  Expanded(
                    flex: 62,
                    child: Container(
                      height: 5,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String imageUrl,
    required String priceTag,
    required String subtitle,
    required IconData stat1Icon,
    required String stat1Text,
    required IconData stat2Icon,
    required String stat2Text,
    Color? stat2Color,
    required bool isDark,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    child: const Center(
                      child: Icon(Icons.image_not_supported_rounded, size: 36, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    priceTag,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF16A34A),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(stat1Icon, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      stat1Text,
                      style: GoogleFonts.plusJakartaSans(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(stat2Icon, size: 14, color: stat2Color ?? textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      stat2Text,
                      style: GoogleFonts.plusJakartaSans(
                        color: stat2Color ?? textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Edit Details',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.analytics_outlined, size: 16),
                          label: Text(
                            'Analytics',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleCatalogCard(
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF312E81).withValues(alpha: 0.4), const Color(0xFF1E1B4B).withValues(alpha: 0.6)]
              : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF4F46E5), size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'Scale Your Service Catalog',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bundle popular services and publish to Google Maps to increase average customer booking value.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: textSecondary,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 15),
              label: Text(
                'AI Service Bundler',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
