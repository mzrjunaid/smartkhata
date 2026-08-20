import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/dashboard_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import 'activity_tile.dart';
import 'section_header.dart';

/// Timeline-style feed of the most recent loan transactions.
///
/// Self-contained: watches [recentActivityProvider] and renders loading,
/// error, or data states internally.
class RecentActivityCard extends ConsumerWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(recentActivityProvider);
    final service = ref.watch(dashboardServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return activityAsync.when(
      loading: () => _buildShimmer(context),
      error: (e, _) => Padding(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        child: Text('Error: $e', style: AppTheme.text(context).bodyMedium),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return const SizedBox.shrink(); // Could show empty state, or nothing
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UPCOMING ACTIVITY',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.colors(context).textSecondary,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          // TODO: Navigate to full activity history screen.
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.colors(context).primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    for (int i = 0; i < activities.length; i++) ...[
                      ActivityTile(
                        activity: activities[i],
                        formattedAmount:
                            service.formatCurrency(activities[i].amount),
                        relativeDate: service.relativeTime(activities[i].date),
                      ),
                      if (i < activities.length - 1)
                        Divider(
                          height: 1, 
                          indent: 68,
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Column(
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.radiusSm,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Container(width: 140, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                Container(width: 70, height: 14, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
