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
import '../notifications/providers/user_notifications_provider.dart';
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

    final titles = <String>[
      'Business Dashboard',
      'Customer Review',
      'Services',
      'Create Post',
      'Insights',
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
      appBar: _index == 0
          ? null
          : AppBar(
              backgroundColor: const Color(0xFFFAF8FF),
              elevation: 0,
              centerTitle: false,
              titleSpacing: 0,
              leading: Builder(
                builder: (innerContext) => IconButton(
                  onPressed: () => Scaffold.of(innerContext).openDrawer(),
                  icon: const Icon(Icons.grid_view_rounded, color: AppColors.primaryContainer),
                ),
              ),
        title: Text(
          titles[_index],
          style: const TextStyle(
            color: AppColors.primaryContainer,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unreadCount = ref.watch(unreadNotificationsCountProvider);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                      onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _index,
          children: screens,
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
    final userCredits = creditsAsync.valueOrNull;
    final credits = userCredits?.availableCredits ?? 0;
    final isLow = credits <= 10;
    final isZero = credits <= 0;
    final isLoading = creditsAsync.isLoading;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isZero
              ? [const Color(0xFF991B1B), const Color(0xFF7F1D1D)]
              : isLow
                  ? [const Color(0xFFC2410C), const Color(0xFF9A3412)]
                  : [const Color(0xFF4F46E5), const Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isZero ? Colors.red : isLow ? Colors.orange : Colors.indigo).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isZero ? Icons.warning_amber_rounded : Icons.bolt_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLoading ? 'Loading...' : '$credits Credits',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  isZero
                      ? 'Automation Paused'
                      : isLow
                          ? 'Low Credit Balance'
                          : 'Available Balance',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            onPressed: () {
              ref.read(userCreditsProvider.notifier).fetchCredits();
            },
            tooltip: 'Refresh Credits',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          )
        ],
      ),
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
