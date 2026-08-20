import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'providers/user_notifications_provider.dart';

class NotificationEndDrawer extends ConsumerWidget {
  const NotificationEndDrawer({super.key});

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.88 > 390
          ? 390
          : MediaQuery.of(context).size.width * 0.88,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      size: 20,
                      color: Color(0xFF4A07E8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: const Color(0xFF131B2E),
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Text(
                        '$unreadCount New',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF4338CA),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap an alert to dismiss',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(userNotificationsProvider.notifier).clearAllNotifications();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Clear all',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF4A07E8),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 16, color: Color(0xFFF1F5F9)),

            // Notifications Feed
            Expanded(
              child: notifsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryContainer),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.grey, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load notifications',
                        style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(userNotificationsProvider.notifier).fetchNotifications();
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_none_rounded, size: 36, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No Notifications',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "You're all caught up! No active alerts.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primaryContainer,
                    onRefresh: () async {
                      await ref.read(userNotificationsProvider.notifier).fetchNotifications();
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            ref.read(userNotificationsProvider.notifier).dismissNotification(item.id);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: const Color(0xFFEF4444),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                          ),
                          child: InkWell(
                            onTap: () {
                              // On click or tap, message goes away from the notification sidebar
                              ref.read(userNotificationsProvider.notifier).dismissNotification(item.id);
                            },
                            child: Container(
                              color: item.isRead ? Colors.white : const Color(0xFFF8FAFC),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: item.isRead
                                          ? const Color(0xFFF1F5F9)
                                          : const Color(0xFFF5F3FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                                      color: item.isRead ? const Color(0xFF64748B) : const Color(0xFF4A07E8),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatTime(item.createdAt),
                                              style: GoogleFonts.plusJakartaSans(
                                                color: const Color(0xFF94A3B8),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.body,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFF475569),
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      ref.read(userNotificationsProvider.notifier).dismissNotification(item.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Bottom Action Bar with prominent Close Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(
                    'Close',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF1E293B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
