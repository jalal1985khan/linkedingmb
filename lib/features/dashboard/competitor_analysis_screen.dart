import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/gmbapi_repository.dart';

final competitorScanProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) {
    return ref.read(gmbapiRepositoryProvider).getCompetitorScan();
  },
);

class CompetitorAnalysisScreen extends ConsumerWidget {
  const CompetitorAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Competitor Analysis'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ref
          .watch(competitorScanProvider)
          .when(
            data: (data) {
              final results = data['results'] as List<dynamic>? ?? [];
              final status = data['status'] ?? 'Unknown';

              if (results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No competitor data found (Status: $status)',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'Competitor scans might take some time to process or may not be available for this location yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final comp = results[index];
                  return _CompetitorCard(competitor: comp);
                },
              );
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing competitors...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            error: (e, st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Error loading competitor data: $e',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
    );
  }
}

class _CompetitorCard extends StatelessWidget {
  final Map<String, dynamic> competitor;

  const _CompetitorCard({required this.competitor});

  @override
  Widget build(BuildContext context) {
    final title = competitor['title'] ?? 'Unknown Competitor';
    final address = competitor['address'] ?? 'No address provided';
    final rating = competitor['rating'];
    final reviews = competitor['reviews_count'];
    final phone = competitor['phone'];
    final website = competitor['website'];
    final rank = competitor['rank'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(
                icon: Icons.star,
                color: Colors.amber,
                label: 'Rating',
                value: rating != null ? rating.toString() : 'N/A',
              ),
              _MetricItem(
                icon: Icons.rate_review,
                color: Colors.blue,
                label: 'Reviews',
                value: reviews != null ? reviews.toString() : '0',
              ),
            ],
          ),
          if (phone != null || website != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                if (phone != null) ...[
                  const Icon(
                    Icons.phone,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    phone.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (website != null) ...[
                  const Icon(
                    Icons.language,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Website Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
