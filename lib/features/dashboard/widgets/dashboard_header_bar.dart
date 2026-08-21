import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../notifications/providers/user_notifications_provider.dart';

class DashboardHeaderBar extends ConsumerWidget {
  final String title;
  final String subtitle;
  final bool showSparkle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenNotifications;

  const DashboardHeaderBar({
    super.key,
    this.title = 'Dashboard',
    this.subtitle = 'Grow your business with SocialHive AI',
    this.showSparkle = true,
    this.showBackButton = false,
    this.onBack,
    this.onOpenDrawer,
    this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF131B2E);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      children: [
        // Left Icon: Back Button or 4-Square Grid Icon
        InkWell(
          onTap: showBackButton
              ? (onBack ?? () => Navigator.of(context).maybePop())
              : (onOpenDrawer ?? () => Scaffold.of(context).openDrawer()),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              width: 22,
              height: 22,
              child: showBackButton
                  ? Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: textPrimary,
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(
                        4,
                        (index) => Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A07E8),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showSparkle) ...[
                    const SizedBox(width: 4),
                    const Text('✨', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Notification Bell Icon with Badge
        InkWell(
          onTap: onOpenNotifications ?? () => Scaffold.of(context).openEndDrawer(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: textPrimary,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
