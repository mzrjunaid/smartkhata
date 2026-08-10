import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../loan_users/data/loan_users_repository.dart';
import '../providers/dashboard_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import 'loan_item_tile.dart';
import 'section_header.dart';

/// Card showing a compact list of active loans (max 5) with a "View All" link.
///
/// Watches [dashboardSummaryProvider] to build the list with mock active-loan
/// data. Self-manages loading and error states.
class ActiveLoansCard extends ConsumerWidget {
  const ActiveLoansCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(activeConnectionsProvider);
    final service = ref.watch(dashboardServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Active Loans',
          onViewAll: () {
            context.go('/loan-users');
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
          child: connectionsAsync.when(
            loading: () => _buildShimmer(context),
            error: (e, _) => Padding(
              padding: EdgeInsets.all(AppTheme.spacingLg),
              child: Text('Error: $e', style: AppTheme.text(context).bodyMedium),
            ),
            data: (connections) {
              final activeUsers = connections.where((c) => c.claimStatus == 'claimed').toList();
              if (activeUsers.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  child: Text('No active loan users yet.', style: AppTheme.text(context).bodyMedium),
                );
              }
              final displayUsers = activeUsers.take(5).toList();
              
              return Column(
                children: [
                  for (int i = 0; i < displayUsers.length; i++) ...[
                    LoanItemTile(
                      borrowerName: displayUsers[i].borrowerName,
                      amount: service.formatCurrency(
                        displayUsers[i].loans.fold(0.0, (sum, loan) => sum + loan.principal)
                      ),
                      status: displayUsers[i].status,
                      onTap: () {
                        context.push('/borrower-profile/${displayUsers[i].id}');
                      },
                    ),
                    if (i < displayUsers.length - 1)
                      const Divider(height: 1, indent: 68),
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
          3,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Container(width: 80, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                Container(width: 60, height: 24, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
