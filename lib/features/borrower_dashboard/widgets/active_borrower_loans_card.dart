import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../loan_users/data/loan_users_repository.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../lender_dashboard/widgets/loan_item_tile.dart';
import '../../lender_dashboard/widgets/section_header.dart';

class ActiveBorrowerLoansCard extends ConsumerWidget {
  const ActiveBorrowerLoansCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(borrowerConnectionsProvider);

    return connectionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (connections) {
        final activeLoanEntries = connections
            .expand(
              (c) => c.loans
                  .where(
                    (l) => l.status == 'active' || l.status == 'overdue',
                  )
                  .map(
                    (l) => (
                      loan: l,
                      lenderName: c.lenderName,
                      connectionId: c.connectionId,
                    ),
                  ),
            )
            .toList();

        if (activeLoanEntries.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  children: activeLoanEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Column(
                      children: [
                        LoanItemTile(
                          borrowerName: item.lenderName,
                          amount:
                              '${item.loan.currency} ${item.loan.totalAmount.toStringAsFixed(0)}',
                          status: item.loan.status ?? 'active',
                          onTap: () {
                            context.push('/borrower-profile/${item.connectionId}');
                          },
                        ),
                        if (index < activeLoanEntries.length - 1)
                          Divider(
                            height: 1, 
                            indent: 84,
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
