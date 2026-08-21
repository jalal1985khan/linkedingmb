import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/business_profile.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/active_location_provider.dart';

class LocationSwitcherSheet extends ConsumerStatefulWidget {
  const LocationSwitcherSheet({super.key});

  @override
  ConsumerState<LocationSwitcherSheet> createState() =>
      _LocationSwitcherSheetState();
}

class _LocationSwitcherSheetState
    extends ConsumerState<LocationSwitcherSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(activeLocationProvider);
    final activeLoc = locationState.activeLocation;
    final allLocations = locationState.availableLocations;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final filtered = allLocations.where((loc) {
      final q = _searchQuery.toLowerCase();
      return loc.name.toLowerCase().contains(q) ||
          loc.category.toLowerCase().contains(q) ||
          loc.location.toLowerCase().contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: EdgeInsets.only(
        top: 18,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sheet Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFF4F46E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch Business Location',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select a profile to manage posts, reviews & analytics',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field
          if (allLocations.length > 3) ...[
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search locations...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: textSecondary,
                  size: 20,
                ),
                filled: true,
                fillColor: inputBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Location List
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: filtered.map((loc) {
                  final isSelected = loc.id == activeLoc?.id;
                  return _buildLocationItem(
                    context: context,
                    ref: ref,
                    location: loc,
                    isSelected: isSelected,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem({
    required BuildContext context,
    required WidgetRef ref,
    required BusinessProfile location,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    double displayRating = location.rating;
    if (displayRating <= 0.0) {
      final statsAsync = ref.watch(dashboardStatsProvider(location.id));
      if (statsAsync.value != null && statsAsync.value!.averageRating > 0.0) {
        displayRating = statsAsync.value!.averageRating;
      } else {
        final reviewsAsync = ref.watch(dashboardReviewsProvider(location.id));
        if (reviewsAsync.value != null && reviewsAsync.value!.isNotEmpty) {
          final validReviews = reviewsAsync.value!.where((r) => r.starRating > 0).toList();
          if (validReviews.isNotEmpty) {
            final double sum = validReviews.fold<double>(0.0, (acc, r) => acc + r.starRating);
            displayRating = sum / validReviews.length;
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.5) : const Color(0xFFEEF2FF))
            : cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : borderColor,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            ref.read(activeLocationProvider.notifier).selectLocation(location);
            ref.invalidate(dashboardStatsProvider(location.id));
            ref.invalidate(postActivityProvider(location.id));
            ref.invalidate(dashboardReviewsProvider(location.id));
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Store Icon Container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Location Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              location.category,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (displayRating > 0.0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF78350F).withValues(alpha: 0.4)
                                    : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 12,
                                      color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706)),
                                  const SizedBox(width: 2),
                                  Text(
                                    displayRating.toStringAsFixed(1),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
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
                ),

                // Active Checkmark Indicator
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
