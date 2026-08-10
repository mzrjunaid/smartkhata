import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/dashboard_providers.dart';
import '../theme/dashboard_theme.dart';
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
          margin: const EdgeInsets.symmetric(
            horizontal: DashboardTheme.spacingLg,
          ),
          decoration: DashboardTheme.cardDecoration,
          child: activityAsync.when(
            loading: () => _buildShimmer(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(DashboardTheme.spacingLg),
              child: Text('Error: $e', style: DashboardTheme.bodyMedium),
            ),
            data: (activities) {
              if (activities.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(DashboardTheme.spacingXl),
                  child: Center(
                    child: Text(
                      'No upcoming activity',
                      style: DashboardTheme.bodyMedium,
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

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Column(
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DashboardTheme.spacingLg,
              vertical: DashboardTheme.spacingMd,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: DashboardTheme.radiusSm,
                  ),
                ),
                const SizedBox(width: DashboardTheme.spacingMd),
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
