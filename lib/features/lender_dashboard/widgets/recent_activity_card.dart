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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Upcoming Activity',
          onViewAll: () {
            // TODO: Navigate to full activity history screen.
          },
        ),
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
          ),
          decoration: BoxDecoration(
            color: AppTheme.colors(context).cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: activityAsync.when(
            loading: () => _buildShimmer(context),
            error: (e, _) => Padding(
              padding: EdgeInsets.all(AppTheme.spacingLg),
              child: Text('Error: $e', style: AppTheme.text(context).bodyMedium),
            ),
            data: (activities) {
              if (activities.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(AppTheme.spacingXl),
                  child: Center(
                    child: Text(
                      'No upcoming activity',
                      style: AppTheme.text(context).bodyMedium,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < activities.length; i++) ...[
                    ActivityTile(
                      activity: activities[i],
                      formattedAmount:
                          service.formatCurrency(activities[i].amount),
                      relativeDate: service.relativeTime(activities[i].date),
                    ),
                    if (i < activities.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                ],
              );
            },
          ),
        ),
      ],
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
