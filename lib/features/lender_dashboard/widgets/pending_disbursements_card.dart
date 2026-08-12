import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../loan_users/data/loan_users_repository.dart';
import '../providers/dashboard_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import 'loan_item_tile.dart';
import 'section_header.dart';
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
    
    return connectionsAsync.when(
      loading: () => _buildShimmer(context),
      error: (e, _) => const SizedBox.shrink(),
      data: (connections) {
        final pendingItems = <_PendingItem>[];
        for (final c in connections) {
          final pendingLoans = c.loans.where((l) => l.status == 'pending_disbursement');
          for (final l in pendingLoans) {
            pendingItems.add(_PendingItem(l, c));
          }
        }

        if (pendingItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Pending Disbursement',
              onViewAll: null,
            ),
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
              ),
              decoration: BoxDecoration(
                color: AppTheme.colors(context).cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.colors(context).accent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < pendingItems.length; i++) ...[
                    LoanItemTile(
                      borrowerName: pendingItems[i].connection.borrowerName,
                      amount: service.formatCurrency(pendingItems[i].loan.principal),
                      status: 'pending',
                      onTap: () {
                        context.push('/borrower-profile/${pendingItems[i].connection.id}');
                      },
                    ),
                    if (i < pendingItems.length - 1)
                      const Divider(height: 1, indent: 68),
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
