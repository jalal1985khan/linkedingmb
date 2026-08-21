import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../customers/customers_screen.dart';
import '../dashboard/analytics_dashboard_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/reviews_screen.dart';
import '../notifications/notification_end_drawer.dart';
import '../posts/create_post_flow_screen.dart';
import 'widgets/main_app_drawer.dart';

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
      drawer: MainAppDrawer(
        selectedIndex: _index,
        onTabSelected: _selectTabFromDrawer,
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
    setState(() => _index = tabIndex);
  }
}
