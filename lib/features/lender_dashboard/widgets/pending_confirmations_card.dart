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
                        'NEEDS CONFIRMATION',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.colors(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    for (int i = 0; i < activities.length; i++) ...[
                      InkWell(
                        onTap: () {
                          context.push('/repayments/repayment-review/${activities[i].id.replaceFirst('rep_', '')}');
                        },
                        child: ActivityTile(
                          activity: activities[i],
                          formattedAmount: service.formatCurrency(activities[i].amount),
                          relativeDate: service.relativeTime(activities[i].date),
                        ),
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
