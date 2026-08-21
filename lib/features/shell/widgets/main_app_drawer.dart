import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/user_credits_provider.dart';
import '../../autonomy/presentation/ai_control_screen.dart';
import '../../blueprint/presentation/blueprint_planner_screen.dart';
import '../../business_flow/business_profile_screen.dart';
import '../../business_flow/presentation/location_switcher_sheet.dart';
import '../../business_flow/providers/active_location_provider.dart';
import '../../posts/published_posts_screen.dart';
import '../../qa/presentation/qa_engine_screen.dart';
import '../../scheduler/queue_screen.dart';
import '../../settings/app_settings_screen.dart';
import '../../settings/automation_settings_screen.dart';

class MainAppDrawer extends ConsumerStatefulWidget {
  final int? selectedIndex;
  final ValueChanged<int>? onTabSelected;

  const MainAppDrawer({
    super.key,
    this.selectedIndex,
    this.onTabSelected,
  });

  @override
  ConsumerState<MainAppDrawer> createState() => _MainAppDrawerState();
}

class _MainAppDrawerState extends ConsumerState<MainAppDrawer> {
  bool _isCreditCardExpanded = false;

  void _handleTabSelect(int index) {
    Navigator.of(context).pop();
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(index);
    } else {
      // If we are on a pushed screen (like BusinessProfileScreen), pop back to main shell
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLocationState = ref.watch(activeLocationProvider);
    final activeLocation = activeLocationState.activeLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Drawer(
      backgroundColor: cardBgColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
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
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFF4F46E5),
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
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  activeLocation?.category ?? 'GMB Account',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.unfold_more_rounded,
                            color: textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 16, color: borderColor),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  DrawerNavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    selected: widget.selectedIndex == 0,
                    onTap: () => _handleTabSelect(0),
                  ),
                  DrawerNavItem(
                    icon: Icons.business_center_outlined,
                    label: 'Manage Services',
                    selected: widget.selectedIndex == 2,
                    onTap: () => _handleTabSelect(2),
                  ),
                  DrawerNavItem(
                    icon: Icons.stacked_line_chart_rounded,
                    label: 'Performance Stats',
                    selected: widget.selectedIndex == 4,
                    onTap: () => _handleTabSelect(4),
                  ),
                  DrawerNavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Customer Reviews',
                    selected: widget.selectedIndex == 1,
                    onTap: () => _handleTabSelect(1),
                  ),
                  DrawerNavItem(
                    icon: Icons.auto_awesome_motion_rounded,
                    label: 'Strategy Blueprint',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BlueprintPlannerScreen()),
                      );
                    },
                  ),
                  DrawerNavItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Google Q&A Engine',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QAEngineScreen()),
                      );
                    },
                  ),
                  DrawerNavItem(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Create Post',
                    selected: widget.selectedIndex == 3,
                    onTap: () => _handleTabSelect(3),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: borderColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'TOOLS',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  DrawerNavItem(
                    icon: Icons.schedule_rounded,
                    label: 'Post Queue',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QueueScreen()),
                      );
                    },
                  ),
                  DrawerNavItem(
                    icon: Icons.verified_rounded,
                    label: 'Published Posts',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublishedPostsScreen()),
                      );
                    },
                  ),
                  DrawerNavItem(
                    icon: Icons.shield_outlined,
                    label: 'AI Control & Approvals',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AIControlScreen()),
                      );
                    },
                  ),
                  DrawerNavItem(
                    icon: Icons.tune_rounded,
                    label: 'Automations',
                    badgeText: (ref.watch(userCreditsProvider).valueOrNull?.isZeroCredits ?? false)
                        ? 'Paused'
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AutomationSettingsScreen()),
                      );
                    },
                  ),
                  if (activeLocation != null)
                    DrawerNavItem(
                      icon: Icons.storefront_rounded,
                      label: 'Business Profile',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
                        );
                      },
                    ),
                  DrawerNavItem(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 16, color: borderColor),
            ),
            _buildCreditCard(context, ref.watch(userCreditsProvider)),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(BuildContext context, AsyncValue<UserCredits> creditsAsync) {
    final state = creditsAsync.valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final credits = state?.availableCredits ?? 0;
    final monthlyLimit = state?.monthlyLimit ?? 0;
    final resetDays = state?.resetDays ?? 0;
    final isZero = state?.isZeroCredits ?? false;
    final isLow = state?.isLowCredits ?? false;

    Color bgStart;
    Color bgEnd;
    Color borderC;
    Color badgeBg;
    Color badgeTextC;
    String badgeLabel;
    Color ctaColor;
    String ctaText;

    if (isZero) {
      bgStart = const Color(0xFFFFF1F2);
      bgEnd = const Color(0xFFFFE4E6);
      borderC = const Color(0xFFFDA4AF);
      badgeBg = const Color(0xFFE11D48);
      badgeTextC = Colors.white;
      badgeLabel = '0 CREDITS';
      ctaColor = const Color(0xFFBE123C);
      ctaText = 'Buy credits to resume';
    } else if (isLow) {
      bgStart = const Color(0xFFFFF7ED);
      bgEnd = const Color(0xFFFFEDD5);
      borderC = const Color(0xFFFDBA74);
      badgeBg = const Color(0xFFEA580C);
      badgeTextC = Colors.white;
      badgeLabel = 'LOW CREDITS';
      ctaColor = const Color(0xFFC2410C);
      ctaText = 'Add credits before pause';
    } else {
      bgStart = isDark ? const Color(0xFF1E1B4B) : const Color(0xFFF5F3FF);
      bgEnd = isDark ? const Color(0xFF312E81) : const Color(0xFFEDE9FE);
      borderC = isDark ? const Color(0xFF4338CA) : const Color(0xFFDDD6FE);
      badgeBg = const Color(0xFF4F46E5);
      badgeTextC = Colors.white;
      badgeLabel = 'ACTIVE';
      ctaColor = const Color(0xFF4F46E5);
      ctaText = 'View plan details';
    }

    final double progress = (monthlyLimit > 0)
        ? (credits / monthlyLimit).clamp(0.0, 1.0)
        : 1.0;

    final minimizedWidget = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgStart, bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderC, width: 1),
      ),
      child: InkWell(
        onTap: () => setState(() => _isCreditCardExpanded = true),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: badgeBg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.bolt_rounded, size: 16, color: badgeBg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '$credits',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        monthlyLimit > 0 ? ' / $monthlyLimit' : ' credits',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.7),
                      valueColor: AlwaysStoppedAnimation<Color>(badgeBg),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );

    final expandedWidget = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgStart, bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderC, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: badgeBg),
                  const SizedBox(width: 4),
                  Text(
                    'AI Post Credits',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeLabel,
                      style: GoogleFonts.plusJakartaSans(
                        color: badgeTextC,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => setState(() => _isCreditCardExpanded = false),
                    borderRadius: BorderRadius.circular(4),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(badgeBg),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF475569),
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

class DrawerNavItem extends StatelessWidget {
  const DrawerNavItem({
    super.key,
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
