import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

import '../auth/auth_controller.dart';
import '../business_flow/business_flow_controller.dart';
import '../business_flow/business_profile_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/reviews_screen.dart';
import '../customers/customers_screen.dart';
import '../dashboard/analytics_dashboard_screen.dart';
import '../posts/create_post_flow_screen.dart';
import '../scheduler/queue_screen.dart';
import '../settings/automation_settings_screen.dart';
import '../settings/dark_settings_screen.dart';

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
    final selectedBusiness = ref.watch(selectedBusinessProvider);

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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundImage: AssetImage('assets/images/logo.png'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedBusiness?.name ?? 'No business selected',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'Professional Plan',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 32, color: AppColors.surfaceContainer),
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
                      icon: Icons.tune_rounded,
                      label: 'Automations',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AutomationSettingsScreen()));
                      },
                    ),
                    if (selectedBusiness != null)
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
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 32, color: AppColors.surfaceContainer),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SYSTEM STATUS', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text('AI Active', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.black87, size: 20),
                          onPressed: () {
                            Navigator.of(context).pop();
                            ref.read(authControllerProvider.notifier).signOut();
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      appBar: AppBar(
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
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _index = 3), // Post Media tab
        backgroundColor: AppColors.primaryContainer,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.post_add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                _buildNavItem(1, 'Reviews', Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded),
                _buildNavItem(4, 'Stats', Icons.stacked_line_chart_rounded, Icons.stacked_line_chart_rounded),
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
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive 
        ? Colors.red.shade400 
        : selected 
            ? AppColors.primaryContainer 
            : Colors.grey.shade700;
            
    final bgColor = selected 
        ? AppColors.primaryContainer.withOpacity(0.1) 
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
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        dense: true,
      ),
    );
  }
}
