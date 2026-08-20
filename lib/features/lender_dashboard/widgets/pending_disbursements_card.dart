import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../loan_users/data/loan_users_repository.dart';
import '../providers/dashboard_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import 'loan_item_tile.dart';
import '../../new_loan/models/loan_model.dart';
import '../../new_loan/models/connection_model.dart';

class _PendingItem {
  final LoanModel loan;
  final ConnectionModel connection;

  _PendingItem(this.loan, this.connection);
}

class PendingDisbursementsCard extends ConsumerWidget {
  const PendingDisbursementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(activeConnectionsProvider);
    final service = ref.watch(dashboardServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return connectionsAsync.when(
      loading: () => _buildShimmer(context),
      error: (e, _) => const SizedBox.shrink(),
      data: (connections) {
        final pendingItems = <_PendingItem>[];
        for (final c in connections) {
          final pendingLoans = c.loans.where(
            (l) => l.status == 'pending_disbursement',
          );
          for (final l in pendingLoans) {
            pendingItems.add(_PendingItem(l, c));
          }
        }

        if (pendingItems.isEmpty) {
          return const SizedBox.shrink();
        }

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
                        'PENDING DISBURSEMENT',
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
                    for (int i = 0; i < pendingItems.length; i++) ...[
                      LoanItemTile(
                        borrowerName: pendingItems[i].connection.borrowerName,
                        amount: service.formatCurrency(
                          pendingItems[i].loan.principal,
                        ),
                        status: 'pending',
                        onTap: () {
                          context.push(
                            '/borrower-profile/${pendingItems[i].connection.id}',
                          );
                        },
                      ),
                      if (i < pendingItems.length - 1)
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
