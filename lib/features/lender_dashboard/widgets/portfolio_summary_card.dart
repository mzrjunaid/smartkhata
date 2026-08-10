import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/dashboard_providers.dart';
import '../theme/dashboard_theme.dart';
import 'stat_tile.dart';

/// Hero card displaying 4 KPIs in a responsive 2×2 grid.
///
/// Self-contained: watches [dashboardSummaryProvider] internally and
/// handles loading / error states via shimmer and inline messages.
class PortfolioSummaryCard extends ConsumerWidget {
  const PortfolioSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final service = ref.watch(dashboardServiceProvider);

    return summaryAsync.when(
      loading: () => _buildShimmer(),
      error: (e, _) => _buildError(e.toString()),
      data: (summary) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: DashboardTheme.spacingLg,
              ),
              mainAxisSpacing: DashboardTheme.spacingMd,
              crossAxisSpacing: DashboardTheme.spacingMd,
              childAspectRatio: crossAxisCount == 4 ? 1.2 : 1.05,
              children: [
                StatTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Total Lent',
                  value: service.formatCompact(summary.totalLent),
                  iconColor: DashboardTheme.primary,
                  iconBackgroundColor: DashboardTheme.primarySurface,
                  trend: 12.5,
                ),
                StatTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Outstanding',
                  value: service.formatCompact(summary.outstandingBalance),
                  iconColor: DashboardTheme.warning,
                  iconBackgroundColor: DashboardTheme.warningSurface,
                ),
                StatTile(
                  icon: Icons.percent_rounded,
                  label: 'Monthly Interest',
                  value: service.formatCompact(summary.monthlyInterestEarned),
                  iconColor: DashboardTheme.accent,
                  iconBackgroundColor: DashboardTheme.accentSurface,
                  trend: 8.2,
                ),
                StatTile(
                  icon: Icons.speed_rounded,
                  label: 'Collection Rate',
                  value: '${summary.collectionRate.toStringAsFixed(1)}%',
                  iconColor: DashboardTheme.success,
                  iconBackgroundColor: DashboardTheme.successSurface,
                  trend: summary.collectionRate >= 60 ? 3.1 : -2.4,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DashboardTheme.spacingLg,
        ),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: DashboardTheme.spacingMd,
          crossAxisSpacing: DashboardTheme.spacingMd,
          childAspectRatio: 1.05,
          children: List.generate(
            4,
            (_) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: DashboardTheme.radiusMd,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DashboardTheme.spacingLg,
      ),
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: DashboardTheme.cardDecoration,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: DashboardTheme.danger),
          const SizedBox(width: DashboardTheme.spacingSm),
          Expanded(
            child: Text(
              'Failed to load summary: $message',
              style: DashboardTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
