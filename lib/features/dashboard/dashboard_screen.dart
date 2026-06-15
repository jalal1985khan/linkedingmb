import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import '../../data/models/scheduled_post.dart';
import '../auth/auth_controller.dart';
import '../business_flow/business_profile_screen.dart';
import '../business_flow/business_flow_controller.dart';
import '../posts/create_post_flow_screen.dart';
import '../posts/post_editor_screen.dart';
import '../scheduler/scheduler_screen.dart';
import '../settings/automation_settings_screen.dart';
import 'dashboard_controller.dart';
import 'widgets/post_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({
    super.key,
    this.showScaffold = true,
  });

  final bool showScaffold;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int selectedFilter = 0;
  static const filters = ['All', 'AI Generated', 'Manual', 'Latest (2 days)'];

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu_rounded),
        ),
        title: const Text('Smart Post'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(dashboardDataProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AutomationSettingsScreen()),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final dashboardState = ref.watch(dashboardDataProvider);
    final selectedBusiness = ref.watch(selectedBusinessProvider);

    return dashboardState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Something went wrong: $error'),
      ),
      data: (dashboard) {
        final filteredPosts = dashboard.posts.where((post) {
          switch (selectedFilter) {
            case 1:
              return post.isAiGenerated;
            case 2:
              return !post.isAiGenerated;
            case 3:
              return DateTime.now().difference(post.scheduledAt).inDays <= 2;
            default:
              return true;
          }
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            if (selectedBusiness != null) ...[
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                selectedBusiness.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 36),
              ),
              const SizedBox(height: 10),
              const _BusinessSnapshotCard(),
              const SizedBox(height: 12),
              _BusinessIdentityDetails(profile: selectedBusiness),
              const SizedBox(height: 12),
              _QuickManagementMenu(
                onEditProfile: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
                ),
                onReadReviews: () => _showSnackBar('Reviews integration next phase'),
                onPhotos: () => _showSnackBar('Photos management coming next'),
                onPosts: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostFlowScreen()),
                ),
                onEditProducts: () => _showSnackBar('Products sync coming next'),
                onEditServices: () => _showSnackBar('Services sync coming next'),
                onBookings: () => _showSnackBar('Bookings integration coming next'),
                onQr: () => _showSnackBar('Google profile QR coming next'),
              ),
              const SizedBox(height: 12),
              const _ProfileCompletionCard(),
              const SizedBox(height: 14),
            ],
            _AutoGenerateCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreatePostFlowScreen()),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.timelapse_rounded,
                    title: '${dashboard.queuedCount} Queued',
                    color: AppColors.queuedBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.auto_awesome_rounded,
                    title: '${dashboard.aiGeneratedCount} AI Generated',
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Text(
                  'Scheduled Posts',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                ),
                const Spacer(),
                Text(
                  '${filteredPosts.length} posts',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(filters.length, (index) {
                final selected = selectedFilter == index;
                return ChoiceChip(
                  label: Text(filters[index]),
                  selected: selected,
                  onSelected: (_) => setState(() => selectedFilter = index),
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                );
              }),
            ),
            const SizedBox(height: 18),
            for (final post in filteredPosts)
              PostCard(
                post: post,
                onOpen: () => _openEditor(post.id),
                actions: _actionsForPost(post.status),
                onActionSelected: (action) => _handlePostAction(
                  postId: post.id,
                  action: action,
                ),
              ),
          ],
        );
      },
    );
  }

  List<PostActionItem> _actionsForPost(PostStatus status) {
    switch (status) {
      case PostStatus.failed:
        return const [
          PostActionItem(id: 'edit', label: 'Edit draft'),
          PostActionItem(id: 'retry', label: 'Retry'),
          PostActionItem(id: 'delete', label: 'Delete'),
        ];
      case PostStatus.published:
        return const [
          PostActionItem(id: 'duplicate', label: 'Duplicate'),
          PostActionItem(id: 'delete', label: 'Delete'),
        ];
      default:
        return const [
          PostActionItem(id: 'edit', label: 'Edit draft'),
          PostActionItem(id: 'schedule', label: 'Schedule'),
          PostActionItem(id: 'publish', label: 'Publish now'),
          PostActionItem(id: 'duplicate', label: 'Duplicate'),
          PostActionItem(id: 'delete', label: 'Delete'),
        ];
    }
  }

  Future<void> _handlePostAction({
    required String postId,
    required String action,
  }) async {
    try {
      final repository = ref.read(postRepositoryProvider);
      switch (action) {
        case 'edit':
          _openEditor(postId);
          return;
        case 'schedule':
          if (!mounted) {
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SchedulerScreen(postId: postId)),
          );
          return;
        case 'publish':
          await repository.publishNow(postId);
          _showSnackBar('Post published');
          break;
        case 'duplicate':
          await repository.duplicatePost(postId);
          _showSnackBar('Post duplicated');
          break;
        case 'delete':
          await repository.deletePost(postId);
          _showSnackBar('Post deleted');
          break;
        case 'retry':
          await repository.retryFailedPost(postId);
          _showSnackBar('Retry queued');
          break;
      }
      ref.invalidate(dashboardDataProvider);
    } catch (error) {
      _showSnackBar('Action failed: $error');
    }
  }

  Future<void> _openEditor(String postId) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostEditorScreen(postId: postId)),
    );
    ref.invalidate(dashboardDataProvider);
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AutoGenerateCard extends StatelessWidget {
  const _AutoGenerateCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto Generate Posts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AI collects business context and creates Google posts',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _BusinessSnapshotCard extends StatelessWidget {
  const _BusinessSnapshotCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Image.asset(
          'assets/images/gbp_reference/gbp_hero.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _BusinessIdentityDetails extends StatelessWidget {
  const _BusinessIdentityDetails({required this.profile});

  final BusinessProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fetched Business Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _DetailRow(label: 'Address', value: profile.address),
          _DetailRow(label: 'Phone', value: profile.phone),
          _DetailRow(label: 'Hours', value: profile.hoursSummary),
          _DetailRow(label: 'Category', value: profile.category),
          _DetailRow(label: 'Website', value: profile.website),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickManagementMenu extends StatelessWidget {
  const _QuickManagementMenu({
    required this.onEditProfile,
    required this.onReadReviews,
    required this.onPhotos,
    required this.onPosts,
    required this.onQr,
    required this.onEditProducts,
    required this.onEditServices,
    required this.onBookings,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onReadReviews;
  final VoidCallback onPhotos;
  final VoidCallback onPosts;
  final VoidCallback onQr;
  final VoidCallback onEditProducts;
  final VoidCallback onEditServices;
  final VoidCallback onBookings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        childAspectRatio: 0.95,
        children: [
          _QuickMenuItem(icon: Icons.edit_outlined, label: 'Edit profile', onTap: onEditProfile),
          _QuickMenuItem(icon: Icons.star_border_rounded, label: 'Read reviews', onTap: onReadReviews),
          _QuickMenuItem(icon: Icons.image_outlined, label: 'Photos', onTap: onPhotos),
          _QuickMenuItem(icon: Icons.post_add_rounded, label: 'Posts', onTap: onPosts),
          _QuickMenuItem(icon: Icons.qr_code_2_rounded, label: 'Get Google QR', onTap: onQr),
          _QuickMenuItem(icon: Icons.shopping_bag_outlined, label: 'Edit products', onTap: onEditProducts),
          _QuickMenuItem(icon: Icons.list_alt_rounded, label: 'Edit services', onTap: onEditServices),
          _QuickMenuItem(icon: Icons.calendar_month_outlined, label: 'Bookings', onTap: onBookings),
        ],
      ),
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        'assets/images/gbp_reference/gbp_profile_completion.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
