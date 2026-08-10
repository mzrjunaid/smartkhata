import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

import '../providers/dashboard_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import 'activity_tile.dart';
import 'section_header.dart';

class PendingConfirmationsCard extends ConsumerWidget {
  const PendingConfirmationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingConfirmationsProvider);
    final service = ref.watch(dashboardServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return pendingAsync.when(
      loading: () => _buildShimmer(context),
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
              margin: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
              ),
              decoration: BoxDecoration(
                color: AppTheme.colors(context).cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.colors(context).warning.withValues(alpha: 0.5),
                  width: 1.5,
                ),
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

  Widget _buildShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.radiusMd,
          ),
        ),
      ),
    );
  }
}
