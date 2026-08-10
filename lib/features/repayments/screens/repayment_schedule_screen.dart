import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lender_dashboard/theme/dashboard_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';
import '../../loan_users/models/repayment_model.dart';
import '../../new_loan/models/connection_model.dart';
import '../../new_loan/models/loan_model.dart';

import '../../../core/widgets/dashboard_app_bar.dart';

class RepaymentScheduleScreen extends ConsumerWidget {
  const RepaymentScheduleScreen({super.key, required this.connectionId});

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
            title: 'Repayment Schedules',
            showBackButton: true,
          ),
          Expanded(
            child: connectionAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: DashboardTheme.primary),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: DashboardTheme.danger),
                ),
              ),
              data: (connection) {
                final activeLoans = connection.loans
                    .where((l) => l.status == 'active' || l.status == 'overdue')
                    .toList();

                return repaymentsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: DashboardTheme.primary,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error loading repayments: $err',
                      style: const TextStyle(color: DashboardTheme.danger),
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

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(connection, previous, upcoming),
                          const SizedBox(height: DashboardTheme.spacingXl),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Upcoming Schedule',
                                style: DashboardTheme.headingMedium,
                              ),
                              TextButton.icon(
                                onPressed: activeLoans.isEmpty
                                    ? null
                                    : () => _showAddScheduleDialog(
                                        context,
                                        ref,
                                        activeLoans,
                                      ),
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: DashboardTheme.spacingMd),
                          if (upcoming.isEmpty)
                            _buildEmptyState(
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

                          const SizedBox(height: DashboardTheme.spacingXxl),

                          const Text(
                            'Previous Repayments',
                            style: DashboardTheme.headingMedium,
                          ),
                          const SizedBox(height: DashboardTheme.spacingMd),
                          if (previous.isEmpty)
                            _buildEmptyState(
                              icon: Icons.history,
                              title: 'No Previous Repayments',
                              subtitle: 'No payments have been recorded yet.',
                            )
                          else
                            ...previous.map(
                              (rep) => _PreviousRepaymentCard(repayment: rep),
                            ),

                          const SizedBox(height: 100),
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

  Widget _buildHeader(
    ConnectionModel connection,
    List<RepaymentModel> previous,
    List<RepaymentModel> upcoming,
  ) {
    final double totalPaid = previous.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final double totalLoan = connection.loans.fold(
      0.0,
      (sum, l) => sum + (l.totalAmount > 0 ? l.totalAmount : l.principal),
    );
    final double totalUpcoming = totalLoan - totalPaid;
    final double progress = totalLoan > 0 ? totalPaid / totalLoan : 0.0;

    return Container(
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DashboardTheme.radiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: DashboardTheme.primarySurface,
                child: Text(
                  connection.borrowerName.isNotEmpty
                      ? connection.borrowerName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 24,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: DashboardTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'CNIC: ${connection.borrowerCnic}',
                      style: DashboardTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
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
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: DashboardTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DashboardTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: DashboardTheme.primarySurface,
              color: DashboardTheme.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: DashboardTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: PKR ${totalPaid.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: DashboardTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Remaining: PKR ${totalUpcoming.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: DashboardTheme.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: DashboardTheme.spacingXxl,
        horizontal: DashboardTheme.spacingLg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DashboardTheme.radiusLg,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: DashboardTheme.spacingMd),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardTheme.textPrimary,
            ),
          ),
          const SizedBox(height: DashboardTheme.spacingXs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: DashboardTheme.bodyMedium,
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
              title: const Text('Generate Monthly Schedule'),
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
                    const SizedBox(height: DashboardTheme.spacingMd),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Amount to Schedule',
                      ),
                    ),
                    const SizedBox(height: DashboardTheme.spacingMd),
                    TextField(
                      controller: monthsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Number of Months',
                      ),
                    ),
                    const SizedBox(height: DashboardTheme.spacingMd),
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
    return Container(
      margin: const EdgeInsets.only(bottom: DashboardTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DashboardTheme.radiusMd,
        border: Border.all(color: DashboardTheme.warningSurface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: DashboardTheme.warning.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DashboardTheme.spacingMd,
          vertical: DashboardTheme.spacingSm,
        ),
        leading: Container(
          padding: const EdgeInsets.all(DashboardTheme.spacingSm),
          decoration: BoxDecoration(
            color: DashboardTheme.warningSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.schedule, color: DashboardTheme.warning),
        ),
        title: Text(
          'PKR ${repayment.amount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Due: $dateStr',
            style: const TextStyle(
              color: DashboardTheme.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: DashboardTheme.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.edit_calendar,
                  color: DashboardTheme.primary,
                  size: 20,
                ),
                onPressed: () => _showEditDialog(context),
                tooltip: 'Adjust Schedule',
              ),
            ),
            const SizedBox(width: DashboardTheme.spacingSm),
            Container(
              decoration: BoxDecoration(
                color: DashboardTheme.dangerSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: DashboardTheme.danger,
                  size: 20,
                ),
                onPressed: () => _showDeleteDialog(context),
                tooltip: 'Remove Schedule',
              ),
            ),
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
              title: const Text('Adjust Schedule'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: DashboardTheme.spacingMd),
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
          title: const Text('Remove Schedule'),
          content: const Text(
            'Are you sure you want to remove this scheduled payment?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardTheme.danger,
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
      margin: const EdgeInsets.only(bottom: DashboardTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DashboardTheme.radiusMd,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DashboardTheme.spacingMd,
          vertical: DashboardTheme.spacingSm,
        ),
        leading: Container(
          padding: const EdgeInsets.all(DashboardTheme.spacingSm),
          decoration: BoxDecoration(
            color: DashboardTheme.successSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.check_circle, color: DashboardTheme.success),
        ),
        title: Text(
          'PKR ${repayment.amount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Paid on: $dateStr', style: DashboardTheme.bodyMedium),
        ),
      ),
    );
  }
}
