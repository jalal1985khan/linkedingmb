import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/business_profile.dart';
import '../business_flow/business_flow_controller.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (!widget.showScaffold) {
      return Scaffold(backgroundColor: AppColors.background, body: body);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final dashboardState = ref.watch(dashboardDataProvider);
    final selectedBusiness = ref.watch(selectedBusinessProvider);

    return SafeArea(
      child: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Something went wrong: $error')),
        data: (dashboard) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardDataProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titles
                const Text(
                  'Business Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your business presence and\nperformance',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                if (selectedBusiness != null)
                  _buildBusinessProfileCard(context, selectedBusiness),
                  
                const SizedBox(height: 24),
                _buildAISmartPostCard(context),
                
                const SizedBox(height: 24),
                _buildPerformanceCard(context),
                
                const SizedBox(height: 24),
                _buildAutoReviewCard(context),
                
                const SizedBox(height: 32),
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRecentActivityList(),
                
                const SizedBox(height: 80), 
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessProfileCard(BuildContext context, BusinessProfile profile) {
    return AnimatedGlowingBorder(
      child: Container(
        padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 4),
                        Row(
                          children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 14)),
                        ),
                        const SizedBox(width: 6),
                        Text('250', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${profile.category} in ${profile.location.split(',').first}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo.png'), // placeholder
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Open',
                  style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 16),
                      SizedBox(width: 6),
                      Text('Manage Profile', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildAISmartPostCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amberAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'AI Assistant',
              style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI Smart Post',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Generate high-engagement social content for your business using trending aesthetics and customer insights.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Generate Draft',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Row(
                children: const [
                  Text('Details', style: TextStyle(color: AppColors.primaryContainer, fontSize: 14, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, color: AppColors.primaryContainer, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressRow('Total Views', '12.4K', 0.7, AppColors.primaryContainer),
          const SizedBox(height: 20),
          _buildProgressRow('Interactions', '842', 0.4, AppColors.secondary),
          const SizedBox(height: 24),
          Text(
            '+12% vs last week',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value, double percent, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            Text(value, style: const TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.surfaceContainer,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoReviewCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          const Text(
            'Auto-Review',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            '6 new 5-star reviews received today. AI has drafted responses based on your tone of voice.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Review & Approve',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'View All Reviews',
              style: TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildActivityItem(
            Icons.thumb_up_alt_outlined,
            AppColors.primaryContainer.withOpacity(0.15),
            AppColors.primaryContainer,
            'New review from Sarah J.',
            '"The lavender latte was incredible! Definitely my new spot."',
            '2m ago',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.surfaceContainer),
          ),
          _buildActivityItem(
            Icons.campaign_outlined,
            AppColors.queuedBlue.withOpacity(0.15),
            AppColors.secondary,
            'Scheduled: Weekend Brunch Promo',
            'Your AI post is scheduled for Saturday at 9:00 AM.',
            '1h ago',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.surfaceContainer),
          ),
          _buildActivityItem(
            Icons.restaurant_menu_outlined,
            Colors.red.shade50,
            Colors.redAccent,
            'Menu Update Published',
            'Seasonal Summer Blend added to the online menu.',
            '5h ago',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, Color bgColor, Color iconColor, String title, String subtitle, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AnimatedGlowingBorder extends StatefulWidget {
  final Widget child;
  const AnimatedGlowingBorder({super.key, required this.child});

  @override
  State<AnimatedGlowingBorder> createState() => _AnimatedGlowingBorderState();
}

class _AnimatedGlowingBorderState extends State<AnimatedGlowingBorder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26), // Inner border radius + padding
            gradient: SweepGradient(
              center: Alignment.center,
              transform: GradientRotation(_controller.value * 2 * 3.14159265359),
              colors: [
                Colors.amber.withOpacity(0.0),
                Colors.amberAccent,
                Colors.amber.withOpacity(0.0),
              ],
              stops: const [0.0, 0.1, 0.3],
            ),
          ),
          padding: const EdgeInsets.all(2.0), // Border thickness
          child: widget.child,
        );
      },
    );
  }
}
