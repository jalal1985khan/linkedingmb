import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../business_flow/business_flow_controller.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gmbapiDashboardProvider);

    final body = SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gmbapiDashboardProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Insights',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your business growth and engagement metrics across all services in real-time.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            
            // Segmented Control
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildSegment('Weekly', true)),
                  Expanded(child: _buildSegment('Monthly', false)),
                  Expanded(child: _buildSegment('Yearly', false)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Total Impressions Card
            _buildImpressionsCard(),
            const SizedBox(height: 16),
            
            // Metric Cards
            _buildMetricCard(
              icon: Icons.phone_rounded,
              iconColor: AppColors.primaryContainer,
              iconBg: AppColors.primaryContainer.withOpacity(0.1),
              value: '1,240',
              label: 'Call Clicks',
              change: '+4%',
              changeColor: AppColors.secondary,
              changeBg: const Color(0xFFD4FAFA),
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              icon: Icons.directions_rounded,
              iconColor: AppColors.secondary,
              iconBg: const Color(0xFFD4FAFA),
              value: '856',
              label: 'Direction Requests',
              change: '+18%',
              changeColor: AppColors.secondary,
              changeBg: const Color(0xFFD4FAFA),
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF900B53), // Deep pinkish
              iconBg: const Color(0xFFFCE4EC),
              value: '3,912',
              label: 'Website Visits',
              change: '-2%',
              changeColor: const Color(0xFFBA1A1A),
              changeBg: const Color(0xFFFFDAD6),
            ),
            const SizedBox(height: 24),
            
            // Competitor Rank Card
            _buildCompetitorRankCard(),
            const SizedBox(height: 80), // Padding for bottom nav
          ],
        ),
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

  Widget _buildSegment(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primaryContainer : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildImpressionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL IMPRESSIONS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '42,892',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4FAFA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.trending_up, color: AppColors.secondary, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '+12.5% vs last week',
                      style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.circle, color: AppColors.primaryContainer, size: 10),
              SizedBox(width: 8),
              Text(
                'Real-time engagement tracking',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Chart
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildChartBar(0.4, false),
                _buildChartBar(0.6, false),
                _buildChartBar(0.5, false),
                _buildChartBar(1.0, true), // Active
                _buildChartBar(0.8, false),
                _buildChartBar(0.5, false),
                _buildChartBar(0.4, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(double heightFactor, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 120 * heightFactor,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryContainer : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Mon',
          style: TextStyle(
            color: isActive ? AppColors.primaryContainer : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
    required String change,
    required Color changeColor,
    required Color changeBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: changeBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              change,
              style: TextStyle(color: changeColor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorRankCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF22273B), // Dark background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Competitor Rank',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Based on local search visibility',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '#2',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Competitor 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Urban Brew Coffee', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('98% Match', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.primaryContainer],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Competitor 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('City Roast & Co.', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('82% Match', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.82,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'View Full Analysis',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
