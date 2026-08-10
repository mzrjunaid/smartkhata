import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

import '../providers/dashboard_providers.dart';
import '../theme/dashboard_theme.dart';
import 'activity_tile.dart';
import 'section_header.dart';

class PendingConfirmationsCard extends ConsumerWidget {
  const PendingConfirmationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingConfirmationsProvider);
    final service = ref.watch(dashboardServiceProvider);

    return pendingAsync.when(
      loading: () => _buildShimmer(),
      error: (e, _) => const SizedBox.shrink(),
      data: (activities) {
        if (activities.isEmpty) {
          return const SizedBox.shrink(); // Don't show if there are no pending requests
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Needs Confirmation',
              onViewAll: null, // No view all needed for pending
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: DashboardTheme.spacingLg,
              ),
              decoration: DashboardTheme.cardDecoration.copyWith(
                border: Border.all(color: DashboardTheme.warning, width: 1.5),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < activities.length; i++) ...[
                    InkWell(
                      onTap: () {
                        context.push('/repayments/repayment-review/${activities[i].id.replaceFirst('rep_', '')}');
                      },
                      borderRadius: i == 0 
                          ? const BorderRadius.vertical(top: Radius.circular(12)) 
                          : i == activities.length - 1 
                              ? const BorderRadius.vertical(bottom: Radius.circular(12))
                              : BorderRadius.zero,
                      child: ActivityTile(
                        activity: activities[i],
                        formattedAmount: service.formatCurrency(activities[i].amount),
                        relativeDate: service.relativeTime(activities[i].date),
                      ),
                    ),
                    if (i < activities.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardTheme.spacingLg,
        vertical: DashboardTheme.spacingMd,
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: DashboardTheme.radiusMd,
          ),
        ),
      ),
    );
  }
}
