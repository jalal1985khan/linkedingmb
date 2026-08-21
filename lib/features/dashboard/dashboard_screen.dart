import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../notifications/notification_end_drawer.dart';
import 'dashboard_controller.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/ai_working_banner.dart';
import 'widgets/business_identity_card.dart';
import 'widgets/dashboard_header_bar.dart';
import 'widgets/needs_attention_section.dart';
import 'widgets/overview_kpi_grid.dart';
import 'widgets/reviews_overview_card.dart';
import 'widgets/seo_and_post_activity_row.dart';
import 'widgets/upcoming_posts_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark ? AppColors.backgroundGradientDark : AppColors.backgroundGradientLight;
    final body = _buildBody(context);

    final gradientBody = Container(
      decoration: BoxDecoration(gradient: bgGradient),
      child: body,
    );

    if (!widget.showScaffold) {
      return Material(
        color: Colors.transparent,
        child: gradientBody,
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFFAF8FF),
      endDrawer: const NotificationEndDrawer(),
      body: gradientBody,
    );
  }

  Widget _buildBody(BuildContext context) {
    final activeLocState = ref.watch(activeLocationProvider);
    final activeLocation = activeLocState.activeLocation ??
        const BusinessProfile(
          id: 'social_hive_default',
          name: 'SocialHive',
          category: 'Google Business Profile',
          location: 'Bangalore, Karnataka, India',
          address: 'Bangalore, Karnataka, India',
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
      child: Column(
        children: [
          // 1. Fixed App Header Bar (Pinned to top, doesn't scroll)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: DashboardHeaderBar(
              onOpenDrawer: () {
                Scaffold.of(context).openDrawer();
              },
              onOpenNotifications: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),

          // 2. Scrollable Dashboard Content
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF4A07E8),
              onRefresh: () async {
                ref.read(activeLocationProvider.notifier).refresh();
                ref.invalidate(dashboardStatsProvider(locationId));
                ref.invalidate(postActivityProvider(locationId));
                ref.invalidate(dashboardReviewsProvider(locationId));
                ref.invalidate(dashboardDataProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Business Identity Card & Profile Strength
              BusinessIdentityCard(
                business: activeLocation,
                profileScore: profileScore,
              ),

              const SizedBox(height: 14),

              // 3. AI Working For You Glowing Banner
              const AiWorkingBanner(),

              const SizedBox(height: 18),

              // 4. Needs Your Attention Section (Alerts)
              const NeedsAttentionSection(),

              const SizedBox(height: 18),

              // 5. Today's Overview Section (2x2 KPI Grid)
              OverviewKpiGrid(
                stats: statsAsync.valueOrNull,
              ),

              const SizedBox(height: 18),

              // 6. Local SEO Health & Post Activity
              SeoAndPostActivityRow(
                locationId: locationId,
                postActivity: postActivityAsync.valueOrNull,
              ),

              const SizedBox(height: 18),

              // 7. Reviews Overview Card (5.0 Rating, Star Breakdown, Metrics)
              ReviewsOverviewCard(
                stats: statsAsync.valueOrNull,
                reviews: reviewsAsync.valueOrNull,
              ),

              const SizedBox(height: 18),

              // 8. Upcoming Posts (Content Pipeline)
              const UpcomingPostsCard(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    ),
  ],
),
    );
  }
}
