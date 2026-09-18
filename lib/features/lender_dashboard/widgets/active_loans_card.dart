import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../loan_users/data/loan_users_repository.dart';
import '../providers/dashboard_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import 'loan_item_tile.dart';

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

    return connectionsAsync.when(
      loading: () => _buildShimmer(context),
      error: (e, _) => const SizedBox.shrink(),
      data: (connections) {
        final activeUsers = connections.where((c) {
          if (c.claimStatus != 'claimed') return false;
          return c.loans.any(
            (l) => ['active', 'overdue', 'defaulted'].contains(l.status),
          );
        }).toList();

        if (activeUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayUsers = activeUsers.take(5).toList();

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.03),
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
                        'ACTIVE LOANS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.colors(context).textSecondary,
                        ),
                      ),
                      InkWell(
                        onTap: () => context.go('/loan-users'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                    for (int i = 0; i < displayUsers.length; i++) ...[
                      LoanItemTile(
                        borrowerName: displayUsers[i].borrowerName,
                        amount: service.formatCurrency(
                          displayUsers[i].loans
                              .where(
                                (l) => [
                                  'active',
                                  'overdue',
                                  'defaulted',
                                ].contains(l.status),
                              )
                              .fold(0.0, (sum, loan) => sum + loan.totalAmount),
                        ),
                        status:
                            displayUsers[i].loans.any(
                              (l) => l.status == 'overdue',
                            )
                            ? 'overdue'
                            : 'active',
                        onTap: () {
                          context.push(
                            '/borrower-profile/${displayUsers[i].id}',
                          );
                        },
                      ),
                      if (i < displayUsers.length - 1)
                        Divider(
                          height: 1,
                          indent: 84,
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
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
