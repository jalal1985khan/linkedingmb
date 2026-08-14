import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'providers/user_notifications_provider.dart';

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsSheet(),
    );
  }

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

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: const Color(0xFF1E1B4B),
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
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      ref.read(userNotificationsProvider.notifier).markAllAsRead();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Mark all as read',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Notifications List
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none_rounded, size: 36, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No Notifications Yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "We'll notify you about post updates & system events.",
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primaryContainer,
                  onRefresh: () async {
                    await ref.read(userNotificationsProvider.notifier).fetchNotifications();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return Container(
                        color: item.isRead ? Colors.white : const Color(0xFFF8FAFC),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? const Color(0xFFF1F5F9)
                                  : AppColors.primaryContainer.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                              color: item.isRead ? const Color(0xFF64748B) : AppColors.primaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                    fontSize: 14,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(item.createdAt),
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item.body,
                              style: GoogleFonts.plusJakartaSans(
                                color: item.isRead ? const Color(0xFF64748B) : const Color(0xFF334155),
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ),
                          trailing: !item.isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () {
                            if (!item.isRead) {
                              ref.read(userNotificationsProvider.notifier).markAsRead(item.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
