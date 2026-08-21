import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

import '../auth/providers/user_credits_provider.dart';
import '../autonomy/presentation/ai_control_screen.dart';
import '../blueprint/presentation/blueprint_planner_screen.dart';
import '../business_flow/business_profile_screen.dart';
import '../business_flow/presentation/location_switcher_sheet.dart';
import '../business_flow/providers/active_location_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/reviews_screen.dart';
import '../customers/customers_screen.dart';
import '../dashboard/analytics_dashboard_screen.dart';
import '../notifications/notification_end_drawer.dart';
import '../posts/create_post_flow_screen.dart';
import '../posts/published_posts_screen.dart';
import '../qa/presentation/qa_engine_screen.dart';
import '../scheduler/queue_screen.dart';
import '../settings/app_settings_screen.dart';
import '../settings/automation_settings_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _index = 0;
  bool _isCreditCardExpanded = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final activeLocationState = ref.watch(activeLocationProvider);
    final activeLocation = activeLocationState.activeLocation;

    final screens = <Widget>[
      const DashboardScreen(showScaffold: false),
      const ReviewsScreen(showScaffold: false),
      const CustomersScreen(showScaffold: false),
      const CreatePostFlowScreen(showScaffold: false),
      const AnalyticsDashboardScreen(showScaffold: false),
    ];

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const NotificationEndDrawer(),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const LocationSwitcherSheet(),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Color(0xFF6366F1),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeLocation?.name ?? 'Select Business',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: const Color(0xFF1E1B4B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    activeLocation?.category ?? 'GMB Account',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.unfold_more_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 24, color: AppColors.surfaceContainer),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _DrawerNavItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Dashboard',
                      selected: _index == 0,
                      onTap: () => _selectTabFromDrawer(0),
                    ),
                    _DrawerNavItem(
                      icon: Icons.business_center_outlined,
                      label: 'Manage Services',
                      selected: _index == 2,
                      onTap: () => _selectTabFromDrawer(2),
                    ),
                    _DrawerNavItem(
                      icon: Icons.stacked_line_chart_rounded,
                      label: 'Performance Stats',
                      selected: _index == 4,
                      onTap: () => _selectTabFromDrawer(4),
                    ),
                    _DrawerNavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Customer Reviews',
                      selected: _index == 1,
                      onTap: () => _selectTabFromDrawer(1),
                    ),
                    _DrawerNavItem(
                      icon: Icons.auto_awesome_motion_rounded,
                      label: 'Strategy Blueprint',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BlueprintPlannerScreen()));
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Google Q&A Engine',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QAEngineScreen()));
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Create Post',
                      selected: _index == 3,
                      onTap: () => _selectTabFromDrawer(3),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: AppColors.surfaceContainer),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.only(left: 12, bottom: 8),
                      child: Text('TOOLS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    ),
                    
                    _DrawerNavItem(
                      icon: Icons.schedule_rounded,
                      label: 'Post Queue',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QueueScreen()));
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.verified_rounded,
                      label: 'Published Posts',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PublishedPostsScreen()));
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.shield_outlined,
                      label: 'AI Control & Approvals',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AIControlScreen()));
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.tune_rounded,
                      label: 'Automations',
                      badgeText: (ref.watch(userCreditsProvider).valueOrNull?.isZeroCredits ?? false) ? 'Paused' : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AutomationSettingsScreen()));
                      },
                    ),
                    if (activeLocation != null)
                      _DrawerNavItem(
                        icon: Icons.storefront_rounded,
                        label: 'Business Profile',
                        onTap: () async {
                          Navigator.of(context).pop();
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
                          );
                        },
                      ),
                    _DrawerNavItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 16, color: AppColors.surfaceContainer),
              ),
              _buildCreditCard(context, ref.watch(userCreditsProvider)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppColors.backgroundGradientDark
              : AppColors.backgroundGradientLight,
        ),
        child: SafeArea(
          top: false,
          child: IndexedStack(
            index: _index,
            children: screens,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, 'Home', Icons.home_rounded, Icons.home_outlined),
                _buildNavItem(2, 'Services', Icons.business_center_rounded, Icons.business_center_outlined),
                // Center Floating Create Button
                GestureDetector(
                  onTap: () {
                    setState(() => _index = 3);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF633BFF), Color(0xFF4A07E8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF633BFF).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                _buildNavItem(1, 'Reviews', Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded),
                _buildNavItem(4, 'Insights', Icons.bar_chart_rounded, Icons.bar_chart_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData selectedIcon, IconData unselectedIcon) {
    final isSelected = _index == index;
    final color = isSelected ? AppColors.primaryContainer : Colors.grey.shade500;
    
    return GestureDetector(
      onTap: () {
        if (index == 5) {
          _scaffoldKey.currentState?.openDrawer();
        } else {
          setState(() => _index = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              Positioned(
                top: 0,
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectTabFromDrawer(int tabIndex) {
    Navigator.of(context).pop();
    setState(() => _index = tabIndex);
  }
  Widget _buildCreditCard(BuildContext context, AsyncValue<UserCredits> creditsAsync) {
    if (creditsAsync.isLoading && !creditsAsync.hasValue) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF633BFF)),
          ),
        ),
      );
    }

    final userCredits = creditsAsync.valueOrNull;
    final credits = userCredits?.availableCredits ?? 0;
    final monthlyLimit = userCredits?.monthlyLimit ?? 0;
    final resetDays = userCredits?.resetDays ?? 0;
    final isZero = credits <= 0;
    final isLow = credits > 0 && credits <= 15;
    final progress = monthlyLimit > 0 ? (credits / monthlyLimit).clamp(0.0, 1.0) : (credits > 0 ? 1.0 : 0.0);

    // State-based Color Palette
    final Color bgColor = isZero
        ? const Color(0xFFFFF5F5)
        : isLow
            ? const Color(0xFFFFF8F0)
            : const Color(0xFFFAF8FF);

    final Color borderColor = isZero
        ? const Color(0xFFFECDD3)
        : isLow
            ? const Color(0xFFFED7AA)
            : const Color(0xFFEDE9FE);

    final Color headerTextColor = isZero
        ? const Color(0xFFB91C1C)
        : isLow
            ? const Color(0xFFC2410C)
            : const Color(0xFF4338CA);

    final Color headerIconColor = isZero
        ? const Color(0xFFDC2626)
        : isLow
            ? const Color(0xFFEA580C)
            : const Color(0xFF633BFF);

    final String headerTitle = isZero
        ? 'Credits exhausted'
        : isLow
            ? 'Running low'
            : 'AI Credits';

    final IconData headerIcon = isZero
        ? Icons.warning_amber_rounded
        : isLow
            ? Icons.bolt_rounded
            : Icons.auto_awesome_rounded;

    final Color helpCircleBorder = isZero
        ? const Color(0xFFFDA4AF)
        : isLow
            ? const Color(0xFFFDBA74)
            : const Color(0xFFCBD5E1);

    final Color helpCircleText = isZero
        ? const Color(0xFF9F1239)
        : isLow
            ? const Color(0xFF9A3412)
            : const Color(0xFF94A3B8);

    final Color numberColor = isZero
        ? const Color(0xFFB91C1C)
        : isLow
            ? const Color(0xFFC2410C)
            : const Color(0xFF3730A3);

    final Color subtitleColor = isZero
        ? const Color(0xFF4C0519)
        : isLow
            ? const Color(0xFF431407)
            : const Color(0xFF334155);

    final Color badgeIconColor = isZero
        ? const Color(0xFFE11D48)
        : isLow
            ? const Color(0xFFEA580C)
            : const Color(0xFF633BFF);

    final List<Color> badgeGradient = isZero
        ? [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)]
        : isLow
            ? [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)]
            : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)];

    final Color badgeShadowColor = isZero
        ? const Color(0xFFDC2626).withValues(alpha: 0.15)
        : isLow
            ? const Color(0xFFEA580C).withValues(alpha: 0.15)
            : const Color(0xFF7C3AED).withValues(alpha: 0.15);

    final Color progressFillColor = isZero
        ? Colors.transparent
        : isLow
            ? const Color(0xFFEA580C)
            : const Color(0xFF4338CA);

    final String ctaText = isLow ? 'Add Credits' : 'Get Credits';
    final Color ctaColor = isZero
        ? const Color(0xFFDC2626)
        : isLow
            ? const Color(0xFFEA580C)
            : const Color(0xFF4338CA);

    // 1. Minimized View (Compact Pill Bar from design)
    final minimizedWidget = InkWell(
      onTap: () => setState(() => _isCreditCardExpanded = true),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: (isZero
                      ? const Color(0xFFDC2626)
                      : isLow
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF633BFF))
                  .withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular badge with Sparkle icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: badgeGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: badgeShadowColor.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                headerIcon,
                size: 20,
                color: badgeIconColor,
              ),
            ),
            const SizedBox(width: 12),

            // AI Credits & 68 /100
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    headerTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$credits',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: numberColor,
                        ),
                      ),
                      if (monthlyLimit > 0)
                        Text(
                          ' /$monthlyLimit',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress bar & days left
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: progressFillColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resetDays > 0 ? '$resetDays days left' : (isZero ? 'Paused' : 'Active'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: headerTextColor,
            ),
          ],
        ),
      ),
    );

    // 2. Expanded Detailed View
    final expandedWidget = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: (isZero
                    ? const Color(0xFFDC2626)
                    : isLow
                        ? const Color(0xFFEA580C)
                        : const Color(0xFF633BFF))
                .withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header Row (Icon + Title + ? Help icon + Collapse Chevron)
          InkWell(
            onTap: () => setState(() => _isCreditCardExpanded = false),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(headerIcon, size: 16, color: headerIconColor),
                    const SizedBox(width: 6),
                    Text(
                      headerTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: headerTextColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Tooltip(
                      message: 'AI Credits are used to generate automated posts, blueprints, and review responses.',
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: helpCircleBorder, width: 1.2),
                        ),
                        child: Text(
                          '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: helpCircleText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 20,
                      color: headerTextColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Large Number & 3D Lightning Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$credits',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: numberColor,
                      letterSpacing: -1,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'credits remaining',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: badgeGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: badgeShadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: badgeIconColor,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressFillColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 4. Details / Usage Text
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
              children: [
                TextSpan(
                  text: '$credits',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: isZero
                        ? const Color(0xFF4C0519)
                        : isLow
                            ? const Color(0xFF431407)
                            : const Color(0xFF1E293B),
                  ),
                ),
                if (monthlyLimit > 0)
                  TextSpan(text: ' / $monthlyLimit monthly credits')
                else
                  const TextSpan(text: ' available credits'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 5. Secondary Status / Reset / Warning Row
          if (isZero)
            Text(
              'AI generation is currently paused.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
              ),
            )
          else if (isLow)
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 13,
                  color: Color(0xFFC2410C),
                ),
                const SizedBox(width: 4),
                Text(
                  'AI automations may pause soon.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFC2410C),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                    children: [
                      if (resetDays > 0) ...[
                        const TextSpan(text: 'Resets in '),
                        TextSpan(
                          text: '$resetDays days',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4338CA),
                          ),
                        ),
                      ] else ...[
                        const TextSpan(text: 'Resets with monthly billing'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // 6. Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isZero
                ? const Color(0xFFFECDD3).withValues(alpha: 0.6)
                : isLow
                    ? const Color(0xFFFED7AA).withValues(alpha: 0.6)
                    : const Color(0xFFEDE9FE),
          ),
          const SizedBox(height: 10),

          // 7. Bottom CTA Action
          InkWell(
            onTap: () {
              ref.read(userCreditsProvider.notifier).fetchCredits();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Refreshing credits... Current balance: $credits credits.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.toll_outlined,
                    size: 16,
                    color: ctaColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ctaText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ctaColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: ctaColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return AnimatedCrossFade(
      firstChild: minimizedWidget,
      secondChild: expandedWidget,
      crossFadeState: _isCreditCardExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 220),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.isDestructive = false,
    this.badgeText,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool isDestructive;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive 
        ? Colors.red.shade400 
        : selected 
            ? AppColors.primaryContainer 
            : Colors.grey.shade700;
            
    final bgColor = selected 
        ? AppColors.primaryContainer.withValues(alpha: 0.1) 
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: badgeText != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  badgeText!,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.red.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        dense: true,
      ),
    );
  }
}
