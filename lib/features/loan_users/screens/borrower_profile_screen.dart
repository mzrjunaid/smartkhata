import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartkhata/core/theme/app_theme.dart';
import '../../new_loan/models/connection_model.dart';
import '../../new_loan/models/loan_model.dart';
import '../data/loan_users_repository.dart';
import '../models/credit_score_model.dart';
import '../models/repayment_model.dart';

import '../../../core/widgets/dashboard_app_bar.dart';
import '../../../core/providers/role_provider.dart';
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
    final role = ref.watch(roleProvider);
    final isLenderView = role == AppRole.lender;

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      body: Column(
        children: [
          DashboardAppBar(
            title: isLenderView ? 'Borrower Profile' : 'Lender Profile',
            showBackButton: true,
          ),
          Expanded(
            child: connectionAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppTheme.colors(context).primary),
              ),
              error: (err, stack) =>
                  Center(child: Text('Error loading profile: $err')),
              data: (connection) {
                final borrowerProfileId = connection.borrowerProfileId;
                final creditScoreAsync = borrowerProfileId != null
                    ? ref.watch(borrowerCreditScoreProvider(borrowerProfileId))
                    : const AsyncValue<CreditScoreModel?>.data(null);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, connection, creditScoreAsync, isLenderView),
                      const SizedBox(height: AppTheme.spacingXl),

                      _buildInvitedLoansSection(
                        context,
                        ref,
                        'Pending Loans',
                        connection.loans
                            .where(
                              (l) => l.status == 'draft' || l.status == 'pending_disbursement',
                            )
                            .toList(),
                      ),

                      _buildLoansSection(context, 
                        'Active Loans',
                        connection.loans
                            .where(
                              (l) =>
                                  l.status == 'active' || l.status == 'overdue',
                            )
                            .toList(),
                        repaymentsAsync.value ?? [],
                      ),
                      const SizedBox(height: AppTheme.spacingXl),

                      _buildLoansSection(context, 
                        'Previous Loans',
                        connection.loans
                            .where(
                              (l) =>
                                  l.status == 'completed' || l.status == 'paid',
                            )
                            .toList(),
                        repaymentsAsync.value ?? [],
                      ),
                      const SizedBox(height: AppTheme.spacingXl),

                      _buildRepaymentsSection(context, repaymentsAsync),
                      const SizedBox(height: AppTheme.spacingXl),

                      if (isLenderView) _buildManagementSection(context, ref, connection),
                      const SizedBox(height: 120), // padding for scroll
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

  Widget _buildHeader(BuildContext context, 
    ConnectionModel connection,
    AsyncValue<CreditScoreModel?> creditScoreAsync,
    bool isLenderView,
  ) {
    final String displayName = isLenderView 
        ? connection.borrowerName 
        : (connection.lenderName ?? 'Lender Data (Coming Soon)');
        
    final String? cnic = isLenderView ? connection.borrowerCnic : null;
    final String? phone = isLenderView ? connection.borrowerPhone : connection.lenderPhone;
    final String? email = isLenderView ? connection.borrowerEmail : connection.lenderEmail;

    final String initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    final theme = AppTheme.colors(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.primary.withValues(alpha: 0.2),
                      theme.primary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (cnic != null && cnic.isNotEmpty)
                      _buildContactRow(context, Icons.badge_outlined, cnic),
                    if (phone != null && phone.isNotEmpty)
                      _buildContactRow(context, Icons.phone_outlined, phone),
                    if (email != null && email.isNotEmpty)
                      _buildContactRow(context, Icons.email_outlined, email),
                    if (!isLenderView && (phone == null || phone.isEmpty) && (email == null || email.isEmpty))
                      Text(
                        'No contact info available',
                        style: AppTheme.text(context).bodySmall.copyWith(
                          color: theme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isLenderView) ...[
            const SizedBox(height: AppTheme.spacingXl),
            const Divider(),
            const SizedBox(height: AppTheme.spacingLg),
            creditScoreAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  'Failed to load score',
                  style: TextStyle(color: theme.danger),
                ),
              ),
              data: (scoreModel) {
                if (scoreModel == null) {
                  return Center(
                    child: Text(
                      'No credit score available',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScoreItem(context, 
                      'Score',
                      scoreModel.score.toString(),
                      scoreModel.score >= 700
                          ? theme.success
                          : (scoreModel.score >= 500
                                ? theme.warning
                                : theme.danger),
                    ),
                    _buildScoreItem(context, 
                      'Total Loans',
                      scoreModel.totalLoans.toString(),
                      theme.primary,
                    ),
                    _buildScoreItem(context, 
                      'On Time',
                      scoreModel.onTimeCount.toString(),
                      theme.success,
                    ),
                    _buildScoreItem(context, 
                      'Late/Default',
                      '${scoreModel.lateCount}/${scoreModel.defaultCount}',
                      theme.danger,
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.colors(context).textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTheme.text(context).bodyMedium.copyWith(
                color: AppTheme.colors(context).textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(BuildContext context, String label, String value, Color color) {
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
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.colors(context).textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInvitedLoansSection(BuildContext context, WidgetRef ref, String title, List<LoanModel> loans) {
    if (loans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.colors(context).textPrimary,
          ),
        ),
        SizedBox(height: AppTheme.spacingMd),
        ...loans.map((loan) {
          final now = DateTime.now();
          final created = loan.createdAt ?? now;
          final expiry = created.add(const Duration(hours: 72));
          final remaining = expiry.difference(now);
          final isExpired = remaining.isNegative;
          
          final progress = isExpired 
              ? 1.0 
              : (72 - remaining.inHours) / 72.0;
              
          final remainingText = isExpired 
              ? 'Expired' 
              : '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m remaining';

          return Container(
            margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
            decoration: AppTheme.cardDecoration(context),
            padding: EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.colors(context).warningSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.schedule_send,
                            color: AppTheme.colors(context).warning,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingMd),
                        Text(
                          loan.status == 'pending_disbursement' ? 'Pending Disbursement' : 'Pending Invitation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.colors(context).textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired ? AppTheme.colors(context).dangerSurface : AppTheme.colors(context).warningSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isExpired ? 'EXPIRED' : (loan.status?.toUpperCase() ?? 'PENDING'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isExpired ? AppTheme.colors(context).danger : AppTheme.colors(context).warning,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingLg),
                Text(
                  'Proposed Amount',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.colors(context).textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${loan.currency} ${loan.principal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.colors(context).textPrimary,
                  ),
                ),
                SizedBox(height: AppTheme.spacingLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expiry Progress (72h limit)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.colors(context).textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      remainingText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isExpired ? AppTheme.colors(context).danger : AppTheme.colors(context).warning,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppTheme.colors(context).warningSurface,
                    color: isExpired ? AppTheme.colors(context).danger : AppTheme.colors(context).warning,
                    minHeight: 6,
                  ),
                ),
                if (loan.status == 'pending_disbursement') ...[
                  SizedBox(height: AppTheme.spacingLg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              await ref.read(loanUsersRepositoryProvider).updateLoanStatus(loan.id, 'cancelled');
                              ref.invalidate(connectionDetailsProvider(connectionId));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.colors(context).danger,
                            side: BorderSide(color: AppTheme.colors(context).danger),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await ref.read(loanUsersRepositoryProvider).updateLoanStatus(loan.id, 'active');
                              ref.invalidate(connectionDetailsProvider(connectionId));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.colors(context).success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Activate'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  Widget _buildLoansSection(BuildContext context, 
    String title,
    List<LoanModel> loans,
    List<RepaymentModel> allRepayments,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.colors(context).textPrimary,
          ),
        ),
        SizedBox(height: AppTheme.spacingMd),
        if (loans.isEmpty)
          Text(
            'No loans found.',
            style: TextStyle(color: AppTheme.colors(context).textSecondary),
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
              margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
              decoration: AppTheme.cardDecoration(context),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    context.push('/repayments/$connectionId');
                  },
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.colors(context).primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: AppTheme.colors(context).primary,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: AppTheme.spacingMd),
                                Text(
                                  'Personal Loan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.colors(context).textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: loan.status == 'active'
                                    ? AppTheme.colors(context).accentSurface
                                    : (loan.status == 'completed' ||
                                              loan.status == 'paid'
                                          ? AppTheme.colors(context).successSurface
                                          : AppTheme.colors(context).dangerSurface),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                loan.status?.toUpperCase() ?? 'UNKNOWN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: loan.status == 'active'
                                      ? AppTheme.colors(context).accent
                                      : (loan.status == 'completed' ||
                                                loan.status == 'paid'
                                            ? AppTheme.colors(context).success
                                            : AppTheme.colors(context).danger),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingLg),
                        Text(
                          'Total Expected Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.colors(context).textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${loan.currency} ${totalPayment.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.colors(context).textPrimary,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingLg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Repayment Progress',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.colors(context).textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.colors(context).primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.colors(context).primarySurface,
                            color: AppTheme.colors(context).primary,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paid: ${loan.currency} ${totalPaid.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppTheme.colors(context).success,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Remaining: ${loan.currency} ${(totalPayment - totalPaid).toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppTheme.colors(context).warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLoanDetailColumn(context, 
                              'Principal',
                              '${loan.currency} ${loan.principal}',
                            ),
                            _buildLoanDetailColumn(context, 
                              'Rate',
                              '${loan.interestRate}% (${loan.interestType})',
                            ),
                            if (totalMonths > 0)
                              _buildLoanDetailColumn(context, 
                                'Period',
                                '$totalMonths Months\n($remainingMonths left)',
                              )
                            else if (loan.dueDate != null)
                              _buildLoanDetailColumn(context, 
                                'Due Date',
                                DateFormat('MMM dd, yyyy').format(loan.dueDate!),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLoanDetailColumn(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.colors(context).textSecondary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.colors(context).textPrimary,
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
        Text(
          'Repayment History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.colors(context).textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        repaymentsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text('Failed to load repayments: $err'),
          data: (repayments) {
            if (repayments.isEmpty) {
              return Text(
                'No repayment history.',
                style: TextStyle(color: AppTheme.colors(context).textSecondary),
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
                  color: AppTheme.colors(context).cardBackground,
                  margin: const EdgeInsets.only(
                    bottom: AppTheme.spacingSm,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      context.push('/repayments/repayment-review/${rep.id}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: isLate
                                ? AppTheme.colors(context).dangerSurface
                                : (rep.status == 'confirmed' ||
                                          rep.status == 'paid'
                                      ? AppTheme.colors(context).successSurface
                                      : AppTheme.colors(context).warningSurface),
                            child: Icon(
                              isLate
                                  ? Icons.warning
                                  : (rep.status == 'confirmed' ||
                                            rep.status == 'paid'
                                        ? Icons.check
                                        : Icons.access_time),
                              color: isLate
                                  ? AppTheme.colors(context).danger
                                  : (rep.status == 'confirmed' ||
                                            rep.status == 'paid'
                                        ? AppTheme.colors(context).success
                                        : AppTheme.colors(context).warning),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount: ${rep.amount}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.colors(context).textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (rep.dueDate != null)
                                  Text(
                                    'Due: ${DateFormat('MMM dd, yyyy').format(rep.dueDate!)} (${_getDaysRemaining(rep.dueDate!)})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.colors(context).textSecondary,
                                    ),
                                  ),
                                if (rep.paidDate != null)
                                  Text(
                                    'Paid on: ${DateFormat('MMM dd, yyyy').format(rep.paidDate!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.colors(context).success,
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
                                  ? AppTheme.colors(context).dangerSurface
                                  : (rep.status == 'confirmed' ||
                                            rep.status == 'paid'
                                        ? AppTheme.colors(context).successSurface
                                        : AppTheme.colors(context).warningSurface),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isLate ? 'PAID LATE' : rep.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isLate
                                    ? AppTheme.colors(context).danger
                                    : (rep.status == 'confirmed' ||
                                              rep.status == 'paid'
                                          ? AppTheme.colors(context).success
                                          : AppTheme.colors(context).warning),
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
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Management & Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.colors(context).textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a private note or review for this borrower...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // Mock save note
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note saved (Mocked)')),
                );
              },
              child: Text('Save Note'),
            ),
          ),
          Divider(height: 32),
          Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.colors(context).danger,
            ),
          ),
          SizedBox(height: AppTheme.spacingSm),
          Text(
            'Blocking this user will prevent them from requesting new loans and hide their active profile. You can unblock later.',
            style: TextStyle(fontSize: 13, color: AppTheme.colors(context).textSecondary),
          ),
          SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.block, color: AppTheme.colors(context).danger),
              label: Text(
                connection.status == 'blocked'
                    ? 'Unblock Borrower'
                    : 'Block Borrower',
                style: TextStyle(color: AppTheme.colors(context).danger),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.colors(context).danger),
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
