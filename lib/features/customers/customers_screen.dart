import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage and monitor your professional service offerings and subscription products.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Performance Snapshot
            Row(
              children: const [
                Icon(Icons.bar_chart_rounded, color: AppColors.primaryContainer),
                SizedBox(width: 8),
                Text(
                  'Performance Snapshot',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.25,
              children: [
                _buildStatCard('Total Bookings', '8,432', subLabel: 'Daily Avg: 280'),
                _buildStatCard('Revenue', '\$14.2k', pillText: '↑ 21%'),
                _buildStatCard('Unique Views', '1,284', pillText: '↑ 8%'),
                _buildStatCard('Conversion Rate', '3.8%', hasProgress: true),
              ],
            ),
            const SizedBox(height: 32),

            // Service Cards
            _buildServiceCard(
              title: 'Latte Art Workshop',
              imageUrl: 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?w=500&q=80',
              priceTag: '\$85 / Person',
              subtitle: '60 min • Individual or Groups',
              stat1Icon: Icons.calendar_today_rounded,
              stat1Text: '12 Booked',
              stat2Icon: Icons.star_rounded,
              stat2Text: '4.9 (124)',
            ),
            const SizedBox(height: 24),
            _buildServiceCard(
              title: 'Organic Beans Subscription',
              imageUrl: 'https://images.unsplash.com/photo-1559525839-b184a4d698c7?w=500&q=80',
              priceTag: '\$45 / Month',
              subtitle: 'Monthly • Recurring Revenue',
              stat1Icon: Icons.people_alt_rounded,
              stat1Text: '442 Active',
              stat2Icon: Icons.trending_up_rounded,
              stat2Text: '+12% growth',
              stat2Color: AppColors.primaryContainer,
            ),
            const SizedBox(height: 32),

            // Scale Your Catalog
            _buildScaleCatalogCard(),
            const SizedBox(height: 80), // bottom nav padding
          ],
        ),
      ),
    );

    if (!showScaffold) {
      return Scaffold(backgroundColor: AppColors.background, body: body);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: body,
    );
  }

  Widget _buildStatCard(String title, String value, {String? subLabel, String? pillText, bool hasProgress = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          if (subLabel != null)
            Text(subLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          if (pillText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F8EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(pillText, style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          if (hasProgress) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String imageUrl,
    required String priceTag,
    required String subtitle,
    required IconData stat1Icon,
    required String stat1Text,
    required IconData stat2Icon,
    required String stat2Text,
    Color? stat2Color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priceTag,
                    style: const TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F8EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(stat1Icon, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(stat1Text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    Icon(stat2Icon, size: 16, color: stat2Color ?? AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(stat2Text, style: TextStyle(color: stat2Color ?? AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Edit Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleCatalogCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDCD2FF), Color(0xFFEAE2FF)], // Light purple gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primaryContainer, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Scale Your Catalog',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new bundled service to\nincrease your average order value.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Generate Template', style: TextStyle(color: AppColors.primaryContainer, fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppColors.primaryContainer, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
