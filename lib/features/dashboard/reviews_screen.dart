import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/gmbapi_repository.dart';

final locationReviewsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.read(gmbapiRepositoryProvider).getLocationReviews();
    });

int parseReviewRating(Map r) {
  int starRating = 0;
  if (r['rating'] != null) {
    if (r['rating'] is int) {
      starRating = r['rating'] as int;
    } else if (r['rating'] is String) {
      starRating = int.tryParse(r['rating']) ?? 0;
    }
  } else if (r['star_rating'] != null) {
    if (r['star_rating'] is int) {
      starRating = r['star_rating'] as int;
    } else if (r['star_rating'] is String) {
      starRating = int.tryParse(r['star_rating']) ?? 0;
    }
  } else if (r['starRating'] != null) {
    final ratingMap = {'ONE': 1, 'TWO': 2, 'THREE': 3, 'FOUR': 4, 'FIVE': 5};
    starRating = ratingMap[r['starRating']] ?? 0;
  }
  return starRating;
}

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  int _selectedFilter = 0; // 0: All, 1: Unreplied, 2: Negative

  @override
  Widget build(BuildContext context) {
    final body = Container(
      color: const Color(0xFFFAF8FF),
      child: SafeArea(
        bottom: false,
        child: ref.watch(locationReviewsProvider).when(
          data: (data) {
            dynamic rawData = data['data'];
            if (rawData == null && data['payload'] != null && data['payload']['data'] != null) {
              rawData = data['payload']['data'];
            }
            List<dynamic> allReviews = [];
            if (rawData is List) {
              allReviews = rawData;
            } else if (rawData is Map && rawData['data'] is List) {
              allReviews = rawData['data'];
            } else if (data['reviews'] is List) {
              allReviews = data['reviews'];
            }
            final pendingReviews = allReviews.where((r) {
              if (r is! Map) return false;
              return r['reply'] == null && r['reviewReply'] == null;
            }).toList();
            // Using a simple logic for negative reviews: rating <= 2
            final negativeReviews = allReviews.where((r) {
              if (r is! Map) return false;
              int star = parseReviewRating(r);
              return star > 0 && star <= 2;
            }).toList();

            int positiveCount = 0;
            int neutralCount = 0;
            int negativeCount = 0;
            double totalStars = 0;
            int totalReviewsWithStars = 0;

            for (var r in allReviews) {
              if (r is Map) {
                int star = parseReviewRating(r);
                if (star > 0) {
                  totalStars += star;
                  totalReviewsWithStars++;
                  if (star >= 4) {
                    positiveCount++;
                  } else if (star == 3) {
                    neutralCount++;
                  } else {
                    negativeCount++;
                  }
                }
              }
            }

            double averageRating = totalReviewsWithStars > 0 ? (totalStars / totalReviewsWithStars) : 0.0;
            double positivePercent = totalReviewsWithStars > 0 ? (positiveCount / totalReviewsWithStars) : 0.0;
            double neutralPercent = totalReviewsWithStars > 0 ? (neutralCount / totalReviewsWithStars) : 0.0;
            double negativePercent = totalReviewsWithStars > 0 ? (negativeCount / totalReviewsWithStars) : 0.0;

            double trendPercentage = 0.0;
            if (allReviews.length > 1) {
              int half = allReviews.length ~/ 2;
              var recent = allReviews.take(half);
              var older = allReviews.skip(half);
              
              double recentStars = 0;
              int recentCount = 0;
              for (var r in recent) {
                if (r is Map) {
                  int star = parseReviewRating(r);
                  if (star > 0) {
                    recentStars += star;
                    recentCount++;
                  }
                }
              }
              
              double olderStars = 0;
              int olderCount = 0;
              for (var r in older) {
                if (r is Map) {
                  int star = parseReviewRating(r);
                  if (star > 0) {
                    olderStars += star;
                    olderCount++;
                  }
                }
              }
              
              double recentAvg = recentCount > 0 ? (recentStars / recentCount) : 0;
              double olderAvg = olderCount > 0 ? (olderStars / olderCount) : 0;
              
              if (olderAvg > 0 && recentAvg > 0) {
                trendPercentage = ((recentAvg - olderAvg) / olderAvg) * 100;
              } else if (olderAvg == 0 && recentAvg > 0) {
                trendPercentage = 100.0;
              }
            }

            List<dynamic> displayReviews = [];
            if (_selectedFilter == 0) displayReviews = allReviews;
            if (_selectedFilter == 1) displayReviews = pendingReviews;
            if (_selectedFilter == 2) displayReviews = negativeReviews;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(locationReviewsProvider);
                try {
                  await ref.read(locationReviewsProvider.future);
                } catch (_) {}
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Reviews',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF131B2E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(height: 8),
                          const Text(
                            'Monitor and manage your business reputation\nacross all platforms.',
                            style: TextStyle(
                              color: Color(0xFF484556),
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSatisfactionCard(
                            averageRating,
                            totalReviewsWithStars,
                            positivePercent,
                            neutralPercent,
                            negativePercent,
                            trendPercentage,
                          ),
                          const SizedBox(height: 24),
                          _buildAIAssistantCard(pendingReviews.length),
                          const SizedBox(height: 24),
                          _buildFilters(allReviews.length, pendingReviews.length),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = displayReviews[index];
                          final Map<String, dynamic> safeReview = item is Map ? Map<String, dynamic>.from(item) : {};
                          return _ReviewCard(review: safeReview);
                        },
                        childCount: displayReviews.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
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
      ),
    );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: body,
    );
  }

  Widget _buildSatisfactionCard(double averageRating, int totalReviews, double posPct, double neuPct, double negPct, double trendPct) {
    bool isPositiveTrend = trendPct >= 0;
    Color trendColor = isPositiveTrend ? AppColors.primaryContainer : Colors.redAccent;
    IconData trendIcon = isPositiveTrend ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    String trendSign = isPositiveTrend ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL SATISFACTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF484556),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryContainer,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < averageRating.round() ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Based on $totalReviews reviews',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF797588),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(trendIcon, color: trendColor, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      '$trendSign${trendPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatBar('Positive', posPct, '${(posPct * 100).round()}%', const Color(0xFF00677F)),
          const SizedBox(height: 12),
          _buildStatBar('Neutral', neuPct, '${(neuPct * 100).round()}%', const Color(0xFFC9C3D9)),
          const SizedBox(height: 12),
          _buildStatBar('Negative', negPct, '${(negPct * 100).round()}%', const Color(0xFFE88A8A)),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, double percent, String percentText, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF131B2E),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: const Color(0xFFEef0ff),
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text(
            percentText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF131B2E),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildAIAssistantCard(int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.cyanAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active • Monitoring Feedback',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'I\'m currently scanning $pendingCount new reviews for potential response drafts and sentiment analysis.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Configure Automation',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(int allCount, int pendingCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildFilterChip('All Reviews', _selectedFilter == 0, () => setState(() => _selectedFilter = 0)),
          _buildFilterChip('Unreplied ($pendingCount)', _selectedFilter == 1, () => setState(() => _selectedFilter = 1)),
          _buildFilterChip('Negative', _selectedFilter == 2, () => setState(() => _selectedFilter = 2)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E7FF).withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF131B2E),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    String reviewerName = 'Anonymous';
    if (review['reviewerName'] != null && review['reviewerName'].toString().isNotEmpty) {
      reviewerName = review['reviewerName'].toString();
    } else if (review['reviewer_name'] != null) {
      reviewerName = review['reviewer_name'].toString();
    } else if (review['reviewer'] is Map && review['reviewer']['displayName'] != null) {
      reviewerName = review['reviewer']['displayName'].toString();
    }

    String? profilePhotoUrl;
    if (review['profilePhotoUrl'] != null && review['profilePhotoUrl'].toString().isNotEmpty) {
      profilePhotoUrl = review['profilePhotoUrl'].toString();
    }

    int starRating = 0;
    if (review['rating'] != null) {
      if (review['rating'] is int) {
        starRating = review['rating'] as int;
      } else if (review['rating'] is String) {
        starRating = int.tryParse(review['rating']) ?? 0;
      }
    } else if (review['star_rating'] != null) {
      if (review['star_rating'] is int) {
        starRating = review['star_rating'] as int;
      } else if (review['star_rating'] is String) {
        starRating = int.tryParse(review['star_rating']) ?? 0;
      }
    } else if (review['starRating'] != null) {
      final ratingMap = {'ONE': 1, 'TWO': 2, 'THREE': 3, 'FOUR': 4, 'FIVE': 5};
      starRating = ratingMap[review['starRating']] ?? 0;
    }

    String comment = "Left a rating without a comment.";
    if (review['comment_en'] != null && review['comment_en'].toString().trim().isNotEmpty) {
      comment = review['comment_en'].toString().trim();
    } else if (review['comment'] != null && review['comment'].toString().trim().isNotEmpty) {
      comment = review['comment'].toString().trim();
    }

    String? reply;
    if (review['reply_comment'] != null && review['reply_comment'].toString().trim().isNotEmpty) {
      reply = review['reply_comment'].toString().trim();
    } else if (review['reply'] != null) {
      if (review['reply'] is Map && review['reply']['comment'] != null) {
        reply = review['reply']['comment'].toString();
      } else if (review['reply'] is String && review['reply'].toString().trim().isNotEmpty && review['reply'].toString() != '1' && review['reply'].toString() != '0') {
        reply = review['reply'].toString();
      }
    } else if (review['reviewReply'] != null && review['reviewReply'] is Map && review['reviewReply']['comment'] != null) {
      reply = review['reviewReply']['comment'].toString();
    }

    final reviewId = review['name'] ?? review['reviewId'] ?? review['id'] ?? review['review_id'] ?? review['_id'];
    final isReplied = reply != null && reply.isNotEmpty;

    String timeAgo = '2h ago'; // default fallback
    final timeStr = review['createTime'] ?? review['updateTime'] ?? review['created_at'] ?? review['updated_at'] ?? review['timestamp'];
    if (timeStr != null) {
      try {
        final time = DateTime.parse(timeStr.toString());
        final difference = DateTime.now().difference(time);
        if (difference.inDays >= 365) {
          final years = (difference.inDays / 365).floor();
          timeAgo = '$years year${years == 1 ? '' : 's'} ago';
        } else if (difference.inDays >= 30) {
          final months = (difference.inDays / 30).floor();
          timeAgo = '$months month${months == 1 ? '' : 's'} ago';
        } else if (difference.inDays > 0) {
          timeAgo = '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
        } else if (difference.inHours > 0) {
          timeAgo = '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
        } else if (difference.inMinutes > 0) {
          timeAgo = '${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'} ago';
        } else {
          timeAgo = 'Just now';
        }
      } catch (e) {
        debugPrint('Error parsing time: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryContainer.withOpacity(0.1),
                backgroundImage: profilePhotoUrl != null ? NetworkImage(profilePhotoUrl) : null,
                child: profilePhotoUrl == null ? Text(
                  reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: AppColors.primaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF131B2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < starRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                timeAgo,
                style: const TextStyle(
                  color: Color(0xFF797588),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            comment,
            style: const TextStyle(
              color: Color(0xFF484556),
              height: 1.5,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          if (!isReplied)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReplyDialog(context, ref, reviewId?.toString() ?? '', comment, isAi: true, reviewerName: reviewerName, rating: starRating),
                      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Reply with AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showReplyDialog(context, ref, reviewId?.toString() ?? '', comment, isAi: false),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF484556))),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(Icons.flag_outlined, color: Colors.red)),
                ),
              ],
            )
          else
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E7FF).withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryContainer, size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Replied by AI',
                                    style: TextStyle(
                                      color: AppColors.primaryContainer,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E7FF).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.chat_bubble_outline_rounded,
                            color: const Color(0xFF484556),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isExpanded && reply != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E7FF), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.subdirectory_arrow_right_rounded, color: AppColors.primaryContainer, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Owner response',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryContainer,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reply,
                          style: const TextStyle(
                            color: Color(0xFF484556),
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, WidgetRef ref, String reviewId, String originalComment, {bool isAi = false, int rating = 5, String reviewerName = 'Anonymous'}) {
    if (reviewId.isEmpty) {
      debugPrint("Warning: reviewId is empty, reply might fail.");
    }
    
    final textController = TextEditingController();
    bool isGeneratingAi = isAi;
    bool aiGenerationFailed = false;

    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            if (isGeneratingAi) {
              // Fire the async request once
              isGeneratingAi = false;
              final ratings = ['ONE', 'TWO', 'THREE', 'FOUR', 'FIVE'];
              final starStr = rating > 0 && rating <= 5 ? ratings[rating - 1] : 'FIVE';
              
              ref.read(gmbapiRepositoryProvider).enhanceReviewReply(
                reviewerName: reviewerName,
                starRating: starStr,
                reviewComment: originalComment,
              ).then((generatedText) {
                if (context.mounted) {
                  setState(() {
                    textController.text = generatedText;
                  });
                }
              }).catchError((e) {
                if (context.mounted) {
                  setState(() {
                    aiGenerationFailed = true;
                  });
                }
              });
              isGeneratingAi = true; // Set back to true to show loading indicator
            }
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  if (isAi)
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryContainer)
                  else
                    const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryContainer),
                  const SizedBox(width: 8),
                  Text(isAi ? 'AI Generated Reply' : 'Manual Reply'),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: isGeneratingAi && textController.text.isEmpty && !aiGenerationFailed
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.primaryContainer),
                            SizedBox(height: 16),
                            Text("AI is reading the review...", style: TextStyle(color: Color(0xFF797588))),
                          ],
                        ),
                      )
                    : TextField(
                        controller: textController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: aiGenerationFailed ? 'AI generation failed. Type your reply here...' : 'Type your reply here...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2)),
                        ),
                      ),
              ),
            actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF484556))),
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
                                const SnackBar(content: Text('Reply posted successfully!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to post reply: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Post Reply', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
