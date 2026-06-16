import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/gmbapi_repository.dart';

final locationReviewsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.read(gmbapiRepositoryProvider).getLocationReviews();
    });

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ref
          .watch(locationReviewsProvider)
          .when(
            data: (data) {
              final reviews = data['data'] as List<dynamic>? ?? [];
              if (reviews.isEmpty) {
                return const Center(
                  child: Text('No reviews found for this location.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _ReviewCard(review: review);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Error loading reviews: $e',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewerName = review['reviewer_name'] ?? 'Anonymous';
    final starRating = review['star_rating'] ?? 0;
    final comment = review['comment'];
    final reply = review['reply']?['comment'];
    final reviewId = review['name']; // GMB review name/id

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < starRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment != null && comment.toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment.toString(),
              style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          if (reply != null && reply.toString().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Reply',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reply.toString(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (reviewId != null) ...[
            OutlinedButton.icon(
              onPressed: () =>
                  _showReplyDialog(context, ref, reviewId.toString()),
              icon: const Icon(Icons.reply),
              label: const Text('Reply to Review'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, WidgetRef ref, String reviewId) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reply to Review'),
              content: TextField(
                controller: textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Type your reply here...',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final replyText = textController.text.trim();
                          if (replyText.isEmpty) return;

                          setState(() => isSubmitting = true);
                          try {
                            await ref
                                .read(gmbapiRepositoryProvider)
                                .replyToReview(reviewId, replyText);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ref.invalidate(locationReviewsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reply posted successfully!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to post reply: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Post Reply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
