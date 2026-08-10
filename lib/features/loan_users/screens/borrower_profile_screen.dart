import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lender_dashboard/theme/dashboard_theme.dart';
import '../../new_loan/models/connection_model.dart';
import '../../new_loan/models/loan_model.dart';
import '../data/loan_users_repository.dart';
import '../models/credit_score_model.dart';
import '../models/repayment_model.dart';

import '../../../core/widgets/dashboard_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BorrowerProfileScreen extends ConsumerWidget {
  const BorrowerProfileScreen({super.key, required this.connectionId});

  final String connectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(connectionDetailsProvider(connectionId));
    final repaymentsAsync = ref.watch(
      connectionRepaymentsProvider(connectionId),
    );

    return Scaffold(
      backgroundColor: DashboardTheme.surface,
      body: Column(
        children: [
          const DashboardAppBar(
            title: 'Borrower Profile',
            showBackButton: true,
          ),
          Expanded(
            child: connectionAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: DashboardTheme.primary),
              ),
              error: (err, stack) =>
                  Center(child: Text('Error loading profile: $err')),
              data: (connection) {
                final borrowerProfileId = connection.borrowerProfileId;
                final creditScoreAsync = borrowerProfileId != null
                    ? ref.watch(borrowerCreditScoreProvider(borrowerProfileId))
                    : const AsyncValue<CreditScoreModel?>.data(null);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(DashboardTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(connection, creditScoreAsync),
                      const SizedBox(height: DashboardTheme.spacingXl),

                      _buildLoansSection(
                        'Active Loans',
                        connection.loans
                            .where(
                              (l) =>
                                  l.status == 'active' || l.status == 'overdue',
                            )
                            .toList(),
                        repaymentsAsync.value ?? [],
                      ),
                      const SizedBox(height: DashboardTheme.spacingXl),

                      _buildLoansSection(
                        'Previous Loans',
                        connection.loans
                            .where(
                              (l) =>
                                  l.status == 'completed' || l.status == 'paid',
                            )
                            .toList(),
                        repaymentsAsync.value ?? [],
                      ),
                      const SizedBox(height: DashboardTheme.spacingXl),

                      _buildRepaymentsSection(context, repaymentsAsync),
                      const SizedBox(height: DashboardTheme.spacingXl),

                      _buildManagementSection(context, ref, connection),
                      const SizedBox(height: 100), // padding for scroll
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ConnectionModel connection,
    AsyncValue<CreditScoreModel?> creditScoreAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: DashboardTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: DashboardTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  connection.borrowerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: DashboardTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: DashboardTheme.spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.borrowerName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: DashboardTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CNIC: ${connection.borrowerCnic}',
                      style: DashboardTheme.bodyMedium,
                    ),
                    if (connection.borrowerPhone != null)
                      Text(
                        'Phone: ${connection.borrowerPhone}',
                        style: DashboardTheme.bodyMedium,
                      ),
                    if (connection.borrowerEmail != null)
                      Text(
                        'Email: ${connection.borrowerEmail}',
                        style: DashboardTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardTheme.spacingLg),
          const Divider(),
          const SizedBox(height: DashboardTheme.spacingMd),
          creditScoreAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Failed to load score'),
            data: (scoreModel) {
              if (scoreModel == null) {
                return const Text('No credit score available');
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreItem(
                    'Score',
                    scoreModel.score.toString(),
                    scoreModel.score >= 700
                        ? Colors.green
                        : (scoreModel.score >= 500
                              ? Colors.orange
                              : Colors.red),
                  ),
                  _buildScoreItem(
                    'Total Loans',
                    scoreModel.totalLoans.toString(),
                    DashboardTheme.primary,
                  ),
                  _buildScoreItem(
                    'On Time',
                    scoreModel.onTimeCount.toString(),
                    Colors.green,
                  ),
                  _buildScoreItem(
                    'Late/Default',
                    '${scoreModel.lateCount}/${scoreModel.defaultCount}',
                    Colors.red,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: DashboardTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoansSection(
    String title,
    List<LoanModel> loans,
    List<RepaymentModel> allRepayments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: DashboardTheme.spacingMd),
        if (loans.isEmpty)
          const Text(
            'No loans found.',
            style: TextStyle(color: DashboardTheme.textSecondary),
          )
        else
          ...loans.map((loan) {
            final loanRepayments = allRepayments
                .where((r) => r.loanId == loan.id)
                .toList();
            final totalPayment = loan.totalAmount > 0
                ? loan.totalAmount
                : loan.principal;
            final totalMonths = loanRepayments.length;
            final remainingMonths = loanRepayments
                .where((r) => r.status != 'confirmed')
                .length;
            final totalPaid = loanRepayments
                .where((r) => r.status == 'confirmed')
                .fold(0.0, (sum, r) => sum + r.amount);
            final progress = totalPayment > 0
                ? (totalPaid / totalPayment).clamp(0.0, 1.0)
                : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: DashboardTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(DashboardTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: DashboardTheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: DashboardTheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: DashboardTheme.spacingMd),
                            const Text(
                              'Personal Loan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: DashboardTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: loan.status == 'active'
                                ? Colors.blue.shade50
                                : (loan.status == 'completed' ||
                                          loan.status == 'paid'
                                      ? Colors.green.shade50
                                      : Colors.red.shade50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            loan.status?.toUpperCase() ?? 'UNKNOWN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: loan.status == 'active'
                                  ? Colors.blue
                                  : (loan.status == 'completed' ||
                                            loan.status == 'paid'
                                        ? Colors.green
                                        : Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DashboardTheme.spacingLg),
                    const Text(
                      'Total Expected Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: DashboardTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${loan.currency} ${totalPayment.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: DashboardTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: DashboardTheme.spacingLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Repayment Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: DashboardTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: DashboardTheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: DashboardTheme.primarySurface,
                        color: DashboardTheme.primary,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: DashboardTheme.spacingMd),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Paid: ${loan.currency} ${totalPaid.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: DashboardTheme.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Remaining: ${loan.currency} ${(totalPayment - totalPaid).toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: DashboardTheme.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DashboardTheme.spacingLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLoanDetailColumn(
                          'Principal',
                          '${loan.currency} ${loan.principal}',
                        ),
                        _buildLoanDetailColumn(
                          'Rate',
                          '${loan.interestRate}% (${loan.interestType})',
                        ),
                        if (totalMonths > 0)
                          _buildLoanDetailColumn(
                            'Period',
                            '$totalMonths Months\n($remainingMonths left)',
                          )
                        else if (loan.dueDate != null)
                          _buildLoanDetailColumn(
                            'Due Date',
                            DateFormat('MMM dd, yyyy').format(loan.dueDate!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLoanDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: DashboardTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DashboardTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRepaymentsSection(
    BuildContext context,
    AsyncValue<List<RepaymentModel>> repaymentsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repayment History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: DashboardTheme.spacingMd),
        repaymentsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text('Failed to load repayments: $err'),
          data: (repayments) {
            if (repayments.isEmpty) {
              return const Text(
                'No repayment history.',
                style: TextStyle(color: DashboardTheme.textSecondary),
              );
            }
            return Column(
              children: repayments.map((rep) {
                bool isLate = false;
                if ((rep.status == 'confirmed' || rep.status == 'paid') &&
                    rep.paidDate != null &&
                    rep.dueDate != null) {
                  isLate = rep.paidDate!.difference(rep.dueDate!).inDays > 5;
                }

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(
                    bottom: DashboardTheme.spacingSm,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      context.push('/repayments/repayment-review/${rep.id}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(DashboardTheme.spacingMd),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: isLate
                                ? Colors.red.shade50
                                : (rep.status == 'confirmed' ||
                                          rep.status == 'paid'
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50),
                            child: Icon(
                              isLate
                                  ? Icons.warning
                                  : (rep.status == 'confirmed' ||
                                            rep.status == 'paid'
                                        ? Icons.check
                                        : Icons.access_time),
                              color: isLate
                                  ? Colors.red
                                  : (rep.status == 'confirmed' ||
                                            rep.status == 'paid'
                                        ? Colors.green
                                        : Colors.orange),
                            ),
                          ),
                          const SizedBox(width: DashboardTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount: ${rep.amount}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (rep.dueDate != null)
                                  Text(
                                    'Due: ${DateFormat('MMM dd, yyyy').format(rep.dueDate!)} (${_getDaysRemaining(rep.dueDate!)})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: DashboardTheme.textSecondary,
                                    ),
                                  ),
                                if (rep.paidDate != null)
                                  Text(
                                    'Paid on: ${DateFormat('MMM dd, yyyy').format(rep.paidDate!)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: DashboardTheme.success,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isLate
                                  ? Colors.red.shade50
                                  : (rep.status == 'confirmed' ||
                                            rep.status == 'paid'
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isLate ? 'PAID LATE' : rep.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isLate
                                    ? Colors.red
                                    : (rep.status == 'confirmed' ||
                                              rep.status == 'paid'
                                          ? Colors.green
                                          : Colors.orange),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildManagementSection(
    BuildContext context,
    WidgetRef ref,
    ConnectionModel connection,
  ) {
    return Container(
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: BoxDecoration(
        color: DashboardTheme.cardBackground,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Management & Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DashboardTheme.textPrimary,
            ),
          ),
          const SizedBox(height: DashboardTheme.spacingMd),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a private note or review for this borrower...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: DashboardTheme.spacingMd),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // Mock save note
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note saved (Mocked)')),
                );
              },
              child: const Text('Save Note'),
            ),
          ),
          const Divider(height: 32),
          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardTheme.danger,
            ),
          ),
          const SizedBox(height: DashboardTheme.spacingSm),
          const Text(
            'Blocking this user will prevent them from requesting new loans and hide their active profile. You can unblock later.',
            style: TextStyle(fontSize: 13, color: DashboardTheme.textSecondary),
          ),
          const SizedBox(height: DashboardTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.block, color: DashboardTheme.danger),
              label: Text(
                connection.status == 'blocked'
                    ? 'Unblock Borrower'
                    : 'Block Borrower',
                style: const TextStyle(color: DashboardTheme.danger),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DashboardTheme.danger),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final newStatus = connection.status == 'blocked'
                    ? 'active'
                    : 'blocked';
                try {
                  await ref
                      .read(loanUsersRepositoryProvider)
                      .updateConnectionStatus(connection.id, newStatus);
                  ref.invalidate(connectionDetailsProvider(connection.id));
                  ref.invalidate(activeConnectionsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User $newStatus successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getDaysRemaining(DateTime dueDate) {
    final diff = dueDate.difference(DateTime.now()).inDays;

    if (diff > 0) {
      if (diff >= 30) {
        final months = diff ~/ 30;
        final days = diff % 30;
        if (days == 0) return '$months month${months > 1 ? 's' : ''} remaining';
        return '$months month${months > 1 ? 's' : ''}, $days day${days > 1 ? 's' : ''} remaining';
      }
      return '$diff days remaining';
    }

    if (diff == 0) return 'Due today';

    final absDiff = diff.abs();
    if (absDiff >= 30) {
      final months = absDiff ~/ 30;
      final days = absDiff % 30;
      if (days == 0) return '$months month${months > 1 ? 's' : ''} overdue';
      return '$months month${months > 1 ? 's' : ''}, $days day${days > 1 ? 's' : ''} overdue';
    }

    return '${diff.abs()} days overdue';
  }
}
