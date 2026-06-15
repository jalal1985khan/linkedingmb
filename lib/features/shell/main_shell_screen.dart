import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../business_flow/business_flow_controller.dart';
import '../business_flow/business_profile_screen.dart';
import '../dashboard/dashboard_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../posts/create_post_flow_screen.dart';
import '../scheduler/queue_screen.dart';
import '../settings/automation_settings_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final selectedBusiness = ref.watch(selectedBusinessProvider);

    final screens = <Widget>[
      const DashboardScreen(showScaffold: false),
      const CreatePostFlowScreen(showScaffold: false),
      const QueueScreen(showScaffold: false),
      const AutomationSettingsScreen(showScaffold: false),
    ];

    final titles = <String>[
      'Smart Post',
      'Create Post',
      'Queue',
      'Settings',
    ];

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GMB AI',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedBusiness?.name ?? 'No business selected',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (selectedBusiness != null)
                      Text(
                        '${selectedBusiness.category} • ${selectedBusiness.location}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade700),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _DrawerNavItem(
                icon: Icons.home_rounded,
                label: 'Dashboard',
                selected: _index == 0,
                onTap: () => _selectTabFromDrawer(0),
              ),
              _DrawerNavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'Create Post',
                selected: _index == 1,
                onTap: () => _selectTabFromDrawer(1),
              ),
              _DrawerNavItem(
                icon: Icons.schedule_rounded,
                label: 'Queue',
                selected: _index == 2,
                onTap: () => _selectTabFromDrawer(2),
              ),
              _DrawerNavItem(
                icon: Icons.tune_rounded,
                label: 'Automation Settings',
                selected: _index == 3,
                onTap: () => _selectTabFromDrawer(3),
              ),
              if (selectedBusiness != null)
                _DrawerNavItem(
                  icon: Icons.storefront_rounded,
                  label: 'Edit Business Profile',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
                    );
                  },
                ),
              const Spacer(),
              const Divider(height: 1),
              _DrawerNavItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (innerContext) => IconButton(
            onPressed: () => Scaffold.of(innerContext).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        title: Text(titles[_index]),
        actions: [
          if (_index == 0 || _index == 2)
            IconButton(
              onPressed: () => ref.invalidate(dashboardDataProvider),
              icon: const Icon(Icons.refresh_rounded),
            ),
          if (_index == 0)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
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
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Create',
              ),
              NavigationDestination(
                icon: Icon(Icons.schedule_outlined),
                selectedIcon: Icon(Icons.schedule_rounded),
                label: 'Queue',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune_rounded),
                label: 'Settings',
              ),
            ],
          ),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onTap: onTap,
    );
  }
}
