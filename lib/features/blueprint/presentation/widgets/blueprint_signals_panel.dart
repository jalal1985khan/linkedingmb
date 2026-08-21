import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/repositories/gmb_blueprint_repository.dart';
import '../../../business_flow/providers/active_location_provider.dart';

final blueprintTriggersProvider = FutureProvider.family<List<GMBTriggerSignal>, String>((ref, locationId) async {
  if (locationId.isEmpty) return [];
  final repo = ref.watch(gmbBlueprintRepositoryProvider);
  return repo.getTriggers(locationId);
});

final blueprintLearningProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, locationId) async {
  if (locationId.isEmpty) return {};
  final repo = ref.watch(gmbBlueprintRepositoryProvider);
  return repo.getLearning(locationId);
});

class BlueprintSignalsPanel extends ConsumerWidget {
  const BlueprintSignalsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLoc = ref.watch(activeLocationProvider).activeLocation;
    final locationId = activeLoc?.id ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final triggersAsync = ref.watch(blueprintTriggersProvider(locationId));
    final learningAsync = ref.watch(blueprintLearningProvider(locationId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // 1. Posting Triggers Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cloud_queue_rounded, color: Color(0xFF4F46E5), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What your next posts will react to',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Live weather, holidays & search spikes shaping post concepts',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                triggersAsync.when(
                  data: (signals) {
                    if (signals.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.wb_sunny_outlined, size: 16, color: textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Standard seasonal trend & category baseline active',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: signals.map((s) {
                        final icon = _getSignalIcon(s.kind);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: const Color(0xFF4F46E5)),
                              const SizedBox(width: 6),
                              Text(
                                s.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 20,
                    child: Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (err, stack) => Text(
                    'Standard regional signal active',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Intelligence & Learned Insights Card
          learningAsync.when(
            data: (data) {
              final learned = data['learned'] as Map<String, dynamic>?;
              final suggestedHours = (data['suggested_hours'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ?? [];

              if (learned == null && suggestedHours.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.psychology_alt_rounded, color: Color(0xFF16A34A), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Learning & Performance Insights',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'Measured format engagement and optimal posting times',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (suggestedHours.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Best Posting Hours: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              suggestedHours.join(', '),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4F46E5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  IconData _getSignalIcon(String kind) {
    switch (kind.toLowerCase()) {
      case 'rain':
        return Icons.water_drop_rounded;
      case 'heat':
      case 'summer':
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'cold':
      case 'winter':
        return Icons.ac_unit_rounded;
      case 'public_holiday':
      case 'holiday':
        return Icons.celebration_rounded;
      case 'search_term':
      case 'keyword_spike':
        return Icons.trending_up_rounded;
      default:
        return Icons.local_florist_rounded;
    }
  }
}
