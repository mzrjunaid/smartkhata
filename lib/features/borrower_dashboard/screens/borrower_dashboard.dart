import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/dashboard_app_bar.dart';
import '../../lender_dashboard/theme/dashboard_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';
import '../../loan_users/models/borrower_connection_model.dart';
import '../../loan_users/models/repayment_model.dart';
import '../../new_loan/models/loan_model.dart';

/// Dashboard shown when the user is viewing the app as a **borrower**.
class BorrowerDashboard extends ConsumerWidget {
  const BorrowerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(borrowerConnectionsProvider);

    return Scaffold(
      backgroundColor: DashboardTheme.surface,
      body: RefreshIndicator(
        color: DashboardTheme.accent,
        onRefresh: () async => ref.invalidate(borrowerConnectionsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardAppBar(),
              connectionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: DashboardTheme.accent,
                    ),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(DashboardTheme.spacingLg),
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: DashboardTheme.danger),
                  ),
                ),
                data: (connections) {
                  if (connections.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Aggregate data
                  final allLoans = connections.expand((c) => c.loans).toList();
                  final activeLoans = allLoans
                      .where(
                        (l) => l.status == 'active' || l.status == 'overdue',
                      )
                      .toList();
                  final totalBorrowed = allLoans.fold<double>(
                    0,
                    (s, l) => s + l.principal,
                  );

                  return Padding(
                    padding: const EdgeInsets.all(DashboardTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Summary card ──
                        _buildSummaryCard(
                          connections.length,
                          activeLoans.length,
                          totalBorrowed,
                        ),
                        const SizedBox(height: DashboardTheme.spacingXl),

                        // ── My Lenders ──
                        const Text(
                          'My Lenders',
                          style: DashboardTheme.headingMedium,
                        ),
                        const SizedBox(height: DashboardTheme.spacingMd),
                        ...connections.map((c) => _LenderCard(connection: c)),

                        // ── Active Loans ──
                        if (activeLoans.isNotEmpty) ...[
                          const SizedBox(height: DashboardTheme.spacingXl),
                          const Text(
                            'Active Loans',
                            style: DashboardTheme.headingMedium,
                          ),
                          const SizedBox(height: DashboardTheme.spacingMd),
                          ...connections.expand(
                            (c) => c.loans
                                .where(
                                  (l) =>
                                      l.status == 'active' ||
                                      l.status == 'overdue',
                                )
                                .map(
                                  (l) => _BorrowerLoanCard(
                                    loan: l,
                                    lenderName: c.lenderName,
                                  ),
                                ),
                          ),
                        ],

                        // ── Upcoming repayments per connection ──
                        const SizedBox(height: DashboardTheme.spacingXl),
                        const Text(
                          'Upcoming Repayments',
                          style: DashboardTheme.headingMedium,
                        ),
                        const SizedBox(height: DashboardTheme.spacingMd),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: DashboardTheme.spacingLg),
            const Text('No Borrowings', style: DashboardTheme.headingMedium),
            const SizedBox(height: DashboardTheme.spacingSm),
            const Text(
              'You don\'t have any active loans as a borrower.',
              style: DashboardTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    int lenderCount,
    int activeLoansCount,
    double totalBorrowed,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DashboardTheme.accent, Color(0xFF00695C)],
        ),
        borderRadius: DashboardTheme.radiusLg,
        boxShadow: DashboardTheme.elevatedShadow,
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
          const SizedBox(height: DashboardTheme.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(
                'Lenders',
                lenderCount.toString(),
                Icons.people_outline,
              ),
              _summaryItem(
                'Active Loans',
                activeLoansCount.toString(),
                Icons.receipt_long,
              ),
              _summaryItem(
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

  Widget _summaryItem(String label, String value, IconData icon) {
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
      margin: const EdgeInsets.only(bottom: DashboardTheme.spacingMd),
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: DashboardTheme.cardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: DashboardTheme.accentSurface,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: DashboardTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: DashboardTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connection.lenderName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$loanCount loan${loanCount != 1 ? 's' : ''}',
                  style: DashboardTheme.bodyMedium,
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

// ── Borrower Loan Card ──────────────────────────────────────────────────

class _BorrowerLoanCard extends StatelessWidget {
  const _BorrowerLoanCard({required this.loan, required this.lenderName});
  final LoanModel loan;
  final String lenderName;

  @override
  Widget build(BuildContext context) {
    final isOverdue = loan.status == 'overdue';
    final daysLeft = loan.dueDate != null
        ? loan.dueDate!.difference(DateTime.now()).inDays
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: DashboardTheme.spacingMd),
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DashboardTheme.radiusMd,
        border: Border.all(
          color: isOverdue
              ? DashboardTheme.danger.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loan.currency} ${loan.principal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: DashboardTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? DashboardTheme.dangerSurface
                      : DashboardTheme.accentSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOverdue ? 'OVERDUE' : 'ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOverdue
                        ? DashboardTheme.danger
                        : DashboardTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardTheme.spacingSm),
          Text('Lender: $lenderName', style: DashboardTheme.bodyMedium),
          if (loan.interestRate > 0)
            Text(
              'Interest: ${loan.interestRate}% (${loan.interestType})',
              style: DashboardTheme.bodySmall,
            ),
          if (loan.dueDate != null) ...[
            const SizedBox(height: DashboardTheme.spacingSm),
            Text(
              daysLeft >= 0
                  ? '$daysLeft days remaining'
                  : 'Overdue by ${-daysLeft} days',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: daysLeft < 0
                    ? DashboardTheme.danger
                    : (daysLeft < 30
                          ? DashboardTheme.warning
                          : DashboardTheme.accent),
              ),
            ),
          ],
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
              padding: const EdgeInsets.only(bottom: DashboardTheme.spacingSm),
              child: Text('From $lenderName', style: DashboardTheme.labelBold),
            ),
            ...upcoming.take(3).map((r) => _UpcomingTile(repayment: r)),
            const SizedBox(height: DashboardTheme.spacingMd),
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
      margin: const EdgeInsets.only(bottom: DashboardTheme.spacingSm),
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardTheme.spacingMd,
        vertical: DashboardTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DashboardTheme.radiusMd,
        border: Border.all(
          color: daysLeft < 7
              ? DashboardTheme.warningSurface
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: daysLeft < 7
                  ? DashboardTheme.warningSurface
                  : DashboardTheme.accentSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.schedule,
              size: 20,
              color: daysLeft < 7
                  ? DashboardTheme.warning
                  : DashboardTheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PKR ${repayment.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('Due: $dateStr', style: DashboardTheme.bodySmall),
              ],
            ),
          ),
          Text(
            daysLeft >= 0 ? '${daysLeft}d' : '${-daysLeft}d late',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: daysLeft < 0
                  ? DashboardTheme.danger
                  : (daysLeft < 7
                        ? DashboardTheme.warning
                        : DashboardTheme.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
