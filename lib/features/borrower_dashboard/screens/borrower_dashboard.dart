import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';
import '../../loan_users/models/borrower_connection_model.dart';
import '../../loan_users/models/repayment_model.dart';
import '../../lender_dashboard/widgets/loan_item_tile.dart';

/// Dashboard shown when the user is viewing the app as a **borrower**.
class BorrowerDashboard extends ConsumerWidget {
  const BorrowerDashboard({super.key, this.hasBothRoles = false});
  final bool hasBothRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(borrowerConnectionsProvider);

    return RefreshIndicator(
      color: AppTheme.colors(context).accent,
      onRefresh: () async => ref.invalidate(borrowerConnectionsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: hasBothRoles ? 160 : 135),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            connectionsAsync.when(
              loading: () => Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.colors(context).accent,
                  ),
                ),
              ),
              error: (err, _) => Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: AppTheme.colors(context).danger),
                ),
              ),
              data: (connections) {
                if (connections.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Aggregate data
                final allLoans = connections.expand((c) => c.loans).toList();
                final activeLoans = allLoans
                    .where((l) => l.status == 'active' || l.status == 'overdue')
                    .toList();
                final totalBorrowed = allLoans.fold<double>(
                  0,
                  (s, l) => s + l.principal,
                );

                return Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Summary card ──
                      _buildSummaryCard(
                        context,
                        connections.length,
                        activeLoans.length,
                        totalBorrowed,
                      ),
                      SizedBox(height: AppTheme.spacingXl),

                      // ── My Lenders ──
                      Text(
                        'My Lenders',
                        style: AppTheme.text(context).headingMedium,
                      ),
                      SizedBox(height: AppTheme.spacingMd),
                      ...connections.map((c) => _LenderCard(connection: c)),

                      // ── Active Loans ──
                      if (activeLoans.isNotEmpty) ...[
                        SizedBox(height: AppTheme.spacingXl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Loans',
                              style: AppTheme.text(context).headingMedium,
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'View All',
                                style: AppTheme.text(context).bodyMedium
                                    .copyWith(
                                      color: AppTheme.colors(context).primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMd),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.colors(context).cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              ...(() {
                                final activeLoanEntries = connections
                                    .expand(
                                      (c) => c.loans
                                          .where(
                                            (l) =>
                                                l.status == 'active' ||
                                                l.status == 'overdue',
                                          )
                                          .map(
                                            (l) => (
                                              loan: l,
                                              lenderName: c.lenderName,
                                            ),
                                          ),
                                    )
                                    .toList();

                                return activeLoanEntries.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return Column(
                                    children: [
                                      LoanItemTile(
                                        borrowerName: item
                                            .lenderName, // Using lender's name for borrower view
                                        amount:
                                            '${item.loan.currency} ${item.loan.principal.toStringAsFixed(0)}',
                                        status: item.loan.status ?? 'active',
                                        onTap: () {
                                          // TODO: Navigate to loan details
                                        },
                                      ),
                                      if (index < activeLoanEntries.length - 1)
                                        const Divider(height: 1, indent: 68),
                                    ],
                                  );
                                }).toList();
                              })(),
                            ],
                          ),
                        ),
                      ],

                      // ── Upcoming repayments per connection ──
                      SizedBox(height: AppTheme.spacingXl),
                      Text(
                        'Upcoming Repayments',
                        style: AppTheme.text(context).headingMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      ...connections.map(
                        (c) => _UpcomingRepaymentsSection(
                          connectionId: c.connectionId,
                          lenderName: c.lenderName,
                        ),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: AppTheme.spacingLg),
            Text('No Borrowings', style: AppTheme.text(context).headingMedium),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              'You don\'t have any active loans as a borrower.',
              style: AppTheme.text(context).bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    int lenderCount,
    int activeLoansCount,
    double totalBorrowed,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.colors(context).accent, Color(0xFF00695C)],
        ),
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Borrower Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(
                context,
                'Lenders',
                lenderCount.toString(),
                Icons.people_outline,
              ),
              _summaryItem(
                context,
                'Active Loans',
                activeLoansCount.toString(),
                Icons.receipt_long,
              ),
              _summaryItem(
                context,
                'Total Borrowed',
                'PKR ${_formatAmount(totalBorrowed)}',
                Icons.account_balance_wallet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
      ],
    );
  }

  static String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

// ── Lender Card ─────────────────────────────────────────────────────────

class _LenderCard extends StatelessWidget {
  const _LenderCard({required this.connection});
  final BorrowerConnectionModel connection;

  @override
  Widget build(BuildContext context) {
    final loanCount = connection.loans.length;
    final initial = connection.lenderName.isNotEmpty
        ? connection.lenderName[0].toUpperCase()
        : 'L';

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.colors(context).accentSurface,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.colors(context).accent,
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connection.lenderName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colors(context).textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$loanCount loan${loanCount != 1 ? 's' : ''}',
                  style: AppTheme.text(context).bodyMedium,
                ),
              ],
            ),
          ),
          if (connection.lenderPhone != null)
            Icon(Icons.phone_outlined, size: 20, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

// ── Upcoming Repayments Section (per connection) ────────────────────────

class _UpcomingRepaymentsSection extends ConsumerWidget {
  const _UpcomingRepaymentsSection({
    required this.connectionId,
    required this.lenderName,
  });
  final String connectionId;
  final String lenderName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repaymentsAsync = ref.watch(
      connectionRepaymentsProvider(connectionId),
    );

    return repaymentsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (repayments) {
        final upcoming =
            repayments
                .where((r) => r.status == 'pending' && r.dueDate != null)
                .toList()
              ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

        if (upcoming.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Text(
                'From $lenderName',
                style: AppTheme.text(context).labelBold,
              ),
            ),
            ...upcoming.take(3).map((r) => _UpcomingTile(repayment: r)),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        );
      },
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.repayment});
  final RepaymentModel repayment;

  @override
  Widget build(BuildContext context) {
    final dateStr = repayment.dueDate?.toLocal().toString().split(' ')[0] ?? '';
    final daysLeft = repayment.dueDate != null
        ? repayment.dueDate!.difference(DateTime.now()).inDays
        : 0;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(
          color: daysLeft < 7
              ? AppTheme.colors(context).warningSurface
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: daysLeft < 7
                  ? AppTheme.colors(context).warningSurface
                  : AppTheme.colors(context).accentSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.schedule,
              size: 20,
              color: daysLeft < 7
                  ? AppTheme.colors(context).warning
                  : AppTheme.colors(context).accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PKR ${repayment.amount.toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('Due: $dateStr', style: AppTheme.text(context).bodySmall),
              ],
            ),
          ),
          Text(
            daysLeft >= 0 ? '${daysLeft}d' : '${-daysLeft}d late',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: daysLeft < 0
                  ? AppTheme.colors(context).danger
                  : (daysLeft < 7
                        ? AppTheme.colors(context).warning
                        : AppTheme.colors(context).textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
