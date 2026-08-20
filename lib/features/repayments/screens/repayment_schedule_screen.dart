import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';
import '../../loan_users/models/repayment_model.dart';
import '../../new_loan/models/connection_model.dart';
import '../../new_loan/models/loan_model.dart';

import '../../../core/widgets/dashboard_app_bar.dart';
import '../../../core/providers/role_provider.dart';

class RepaymentScheduleScreen extends ConsumerWidget {
  const RepaymentScheduleScreen({super.key, required this.connectionId});

  final String connectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(connectionDetailsProvider(connectionId));
    final repaymentsAsync = ref.watch(
      connectionRepaymentsProvider(connectionId),
    );
    final role = ref.watch(roleProvider);
    final isLender = role == AppRole.lender;

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      body: Column(
        children: [
          DashboardAppBar(
            title: 'Repayment Schedules',
            showBackButton: true,
          ),
          Expanded(
            child: connectionAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppTheme.colors(context).primary),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: AppTheme.colors(context).danger),
                ),
              ),
              data: (connection) {
                final activeLoans = connection.loans
                    .where((l) => l.status == 'active' || l.status == 'overdue')
                    .toList();

                return repaymentsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.colors(context).primary,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error loading repayments: $err',
                      style: TextStyle(color: AppTheme.colors(context).danger),
                    ),
                  ),
                  data: (repayments) {
                    final previous = repayments
                        .where((r) => r.status == 'confirmed')
                        .toList();
                    final upcoming = repayments
                        .where(
                          (r) => r.status == 'pending' && r.dueDate != null,
                        )
                        .toList();
                    final pendingConfirmations = repayments
                        .where((r) => r.status == 'pending_confirmation')
                        .toList();

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(context, connection, previous, upcoming),
                          SizedBox(height: AppTheme.spacingXl),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Upcoming Schedule',
                                style: AppTheme.text(context).headingMedium,
                              ),
                              if (isLender)
                                TextButton.icon(
                                  onPressed: activeLoans.isEmpty
                                      ? null
                                      : () => _showAddScheduleDialog(
                                          context,
                                          ref,
                                          activeLoans,
                                        ),
                                  icon: Icon(Icons.add),
                                  label: Text('Add'),
                                ),
                            ],
                          ),
                          SizedBox(height: AppTheme.spacingMd),
                          if (upcoming.isEmpty)
                            _buildEmptyState(context, 
                              icon: Icons.event_available,
                              title: 'No Upcoming Payments',
                              subtitle:
                                  'There are no scheduled payments pending.',
                            )
                          else
                            ...upcoming.map(
                              (rep) => _UpcomingRepaymentCard(
                                repayment: rep,
                                ref: ref,
                                connectionId: connectionId,
                              ),
                            ),

                          SizedBox(height: AppTheme.spacingXxl),

                          if (pendingConfirmations.isNotEmpty) ...[
                            Text(
                              'Pending Confirmations',
                              style: AppTheme.text(context).headingMedium,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            ...pendingConfirmations.map(
                              (rep) => _PendingConfirmationCard(repayment: rep),
                            ),
                            SizedBox(height: AppTheme.spacingXxl),
                          ],

                          Text(
                            'Previous Repayments',
                            style: AppTheme.text(context).headingMedium,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          if (previous.isEmpty)
                            _buildEmptyState(context, 
                              icon: Icons.history,
                              title: 'No Previous Repayments',
                              subtitle: 'No payments have been recorded yet.',
                            )
                          else
                            ...previous.map(
                              (rep) => _PreviousRepaymentCard(repayment: rep),
                            ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    );
                  },
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
    List<RepaymentModel> previous,
    List<RepaymentModel> upcoming,
  ) {
    final double totalPaid = previous.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final validLoans = connection.loans.where((l) => 
        l.status != 'draft' && 
        l.status != 'pending_disbursement' && 
        l.status != 'cancelled');

    final double totalLoan = validLoans.fold(
      0.0,
      (sum, l) => sum + (l.totalAmount > 0 ? l.totalAmount : l.principal),
    );
    final double totalUpcoming = totalLoan - totalPaid;
    final double progress = totalLoan > 0 ? totalPaid / totalLoan : 0.0;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.colors(context).primarySurface,
                child: Text(
                  connection.borrowerName.isNotEmpty
                      ? connection.borrowerName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.colors(context).primary,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.borrowerName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.colors(context).textPrimary,
                      ),
                    ),
                    Text(
                      'CNIC: ${connection.borrowerCnic}',
                      style: AppTheme.text(context).bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
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
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.colors(context).primary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.colors(context).primarySurface,
              color: AppTheme.colors(context).primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: PKR ${totalPaid.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppTheme.colors(context).success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Remaining: PKR ${totalUpcoming.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppTheme.colors(context).warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTheme.spacingXxl,
        horizontal: AppTheme.spacingLg,
      ),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: AppTheme.radiusLg,
        border: Border.all(color: AppTheme.colors(context).textTertiary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.colors(context).textTertiary),
          SizedBox(height: AppTheme.spacingMd),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.colors(context).textPrimary,
            ),
          ),
          SizedBox(height: AppTheme.spacingXs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.text(context).bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    List<LoanModel> activeLoans,
  ) {
    LoanModel selectedLoan = activeLoans.first;
    DateTime? selectedDate = selectedLoan.disbursedAt ?? DateTime.now();
    final initialAmount = selectedLoan.totalAmount > 0
        ? selectedLoan.totalAmount
        : selectedLoan.principal;
    final amountController = TextEditingController(
      text: initialAmount.toString(),
    );
    final monthsController = TextEditingController(
      text: "12",
    ); // Default to 12 months

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.colors(context).cardBackground,
              title: Text('Generate Monthly Schedule', style: TextStyle(color: AppTheme.colors(context).textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<LoanModel>(
                      initialValue: selectedLoan,
                      decoration: const InputDecoration(
                        labelText: 'Select Loan',
                      ),
                      items: activeLoans.map((loan) {
                        final displayAmount = loan.totalAmount > 0
                            ? loan.totalAmount
                            : loan.principal;
                        return DropdownMenuItem(
                          value: loan,
                          child: Text('${loan.currency} $displayAmount'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedLoan = val;
                            final amt = val.totalAmount > 0
                                ? val.totalAmount
                                : val.principal;
                            amountController.text = amt.toString();
                            selectedDate = val.disbursedAt ?? DateTime.now();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Amount to Schedule',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    TextField(
                      controller: monthsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Number of Months',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start Date'),
                      subtitle: Text(
                        selectedDate?.toLocal().toString().split(' ')[0] ??
                            'Select Date',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 3650),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDate == null ||
                        amountController.text.isEmpty ||
                        monthsController.text.isEmpty) {
                      return;
                    }
                    final amt = double.tryParse(amountController.text) ?? 0;
                    final months = int.tryParse(monthsController.text) ?? 0;
                    if (amt <= 0 || months <= 0) {
                      return;
                    }

                    try {
                      await ref
                          .read(loanUsersRepositoryProvider)
                          .generateMonthlySchedule(
                            selectedLoan.id,
                            amt,
                            selectedDate!,
                            months,
                          );
                      ref.invalidate(
                        connectionRepaymentsProvider(connectionId),
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _UpcomingRepaymentCard extends StatelessWidget {
  const _UpcomingRepaymentCard({
    required this.repayment,
    required this.ref,
    required this.connectionId,
  });

  final RepaymentModel repayment;
  final WidgetRef ref;
  final String connectionId;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        repayment.dueDate?.toLocal().toString().split(' ')[0] ?? 'Unknown Date';
    final role = ref.watch(roleProvider);
    final isLender = role == AppRole.lender;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.colors(context).warningSurface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colors(context).warning.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppTheme.colors(context).warningSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.schedule, color: AppTheme.colors(context).warning),
        ),
        title: Text(
          'PKR ${repayment.amount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.colors(context).textPrimary),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Due: $dateStr',
            style: TextStyle(
              color: AppTheme.colors(context).warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.colors(context).primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.edit_calendar,
                  color: AppTheme.colors(context).primary,
                  size: 20,
                ),
                onPressed: () => _showEditDialog(context),
                tooltip: 'Adjust Schedule',
              ),
            ),
            if (isLender) ...[
              SizedBox(width: AppTheme.spacingSm),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.colors(context).dangerSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppTheme.colors(context).danger,
                    size: 20,
                  ),
                  onPressed: () => _showDeleteDialog(context),
                  tooltip: 'Remove Schedule',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    DateTime? selectedDate = repayment.dueDate;
    final amountController = TextEditingController(
      text: repayment.amount.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.colors(context).cardBackground,
              title: Text('Adjust Schedule', style: TextStyle(color: AppTheme.colors(context).textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due Date'),
                    subtitle: Text(
                      selectedDate?.toLocal().toString().split(' ')[0] ??
                          'Select Date',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDate == null || amountController.text.isEmpty) {
                      return;
                    }
                    final amt = double.tryParse(amountController.text) ?? 0;
                    if (amt <= 0) {
                      return;
                    }

                    try {
                      await ref
                          .read(loanUsersRepositoryProvider)
                          .updateRepaymentSchedule(
                            repayment.id,
                            selectedDate!,
                            amt,
                          );
                      ref.invalidate(
                        connectionRepaymentsProvider(connectionId),
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.colors(context).cardBackground,
          title: Text('Remove Schedule', style: TextStyle(color: AppTheme.colors(context).textPrimary)),
          content: Text(
            'Are you sure you want to remove this scheduled payment?',
            style: TextStyle(color: AppTheme.colors(context).textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors(context).danger,
              ),
              onPressed: () async {
                try {
                  await ref
                      .read(loanUsersRepositoryProvider)
                      .deleteRepayment(repayment.id);
                  ref.invalidate(connectionRepaymentsProvider(connectionId));
                  if (context.mounted) {
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PreviousRepaymentCard extends StatelessWidget {
  const _PreviousRepaymentCard({required this.repayment});

  final RepaymentModel repayment;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        repayment.paidDate?.toLocal().toString().split(' ')[0] ??
        'Unknown Date';
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.colors(context).textTertiary.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppTheme.colors(context).successSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.check_circle, color: AppTheme.colors(context).success),
        ),
        title: Text(
          'PKR ${repayment.amount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.colors(context).textPrimary),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Paid on: $dateStr', style: AppTheme.text(context).bodyMedium),
        ),
      ),
    );
  }
}

class _PendingConfirmationCard extends StatelessWidget {
  const _PendingConfirmationCard({required this.repayment});

  final RepaymentModel repayment;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        repayment.paidDate?.toLocal().toString().split(' ')[0] ??
        repayment.dueDate?.toLocal().toString().split(' ')[0] ??
        'Unknown Date';
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.colors(context).warningSurface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colors(context).warning.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppTheme.colors(context).warningSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.hourglass_empty, color: AppTheme.colors(context).warning),
        ),
        title: Text(
          'PKR ${repayment.amount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.colors(context).textPrimary),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'Submitted: $dateStr',
            style: TextStyle(
              color: AppTheme.colors(context).warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
