import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/profile_providers.dart';
import '../../loan_users/data/loan_users_repository.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../lender_dashboard/providers/dashboard_providers.dart';

class RepaymentReviewScreen extends ConsumerWidget {
  const RepaymentReviewScreen({super.key, required this.repaymentId});

  final String repaymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repaymentAsync = ref.watch(repaymentDetailsProvider(repaymentId));

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text('Review Payment'),
        backgroundColor: AppTheme.colors(context).primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final repayment = repaymentAsync.value;
              if (repayment != null) {
                _showEditDialog(context, ref, repayment);
              }
            },
          ),
        ],
      ),
      body: repaymentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (repayment) {
          final isPending = repayment.status == 'pending';

          return SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  decoration: AppTheme.cardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(context, 
                        'Status',
                        repayment.status.toUpperCase(),
                        color: isPending
                            ? AppTheme.colors(context).warning
                            : AppTheme.colors(context).success,
                      ),
                      const Divider(),
                      _buildInfoRow(context, 'Amount', 'Rs. ${repayment.amount}'),
                      Divider(),
                      _buildInfoRow(context, 
                        'Due Date',
                        repayment.dueDate != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(repayment.dueDate!)
                            : 'N/A',
                      ),
                      Divider(),
                      _buildInfoRow(context, 
                        'Paid Date',
                        repayment.paidDate != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(repayment.paidDate!)
                            : 'N/A',
                        warning: repayment.paidDate == null ? 'Missing' : null,
                      ),
                      Divider(),
                      _buildInfoRow(context, 
                        'Payment Method',
                        repayment.method ?? 'Not provided',
                        warning: repayment.method == null ? 'Missing' : null,
                      ),
                      Divider(),
                      _buildInfoRow(context, 
                        'Borrower Note',
                        repayment.note ?? 'None',
                        warning: repayment.note == null ? 'Skipped' : null,
                      ),
                      Divider(),
                      Text('Attachment', style: AppTheme.text(context).labelBold),
                      const SizedBox(height: AppTheme.spacingSm),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: AppTheme.radiusMd,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(
                          child: Text(
                            'No Attachment Provided',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXxl),
                if (isPending) ...[
                  ElevatedButton(
                    onPressed: () async {
                      final profileId = await ref.read(
                        currentProfileIdProvider.future,
                      );
                      final updates = <String, dynamic>{
                        'status': 'confirmed',
                        'confirmed_by': profileId,
                      };
                      if (repayment.paidDate == null) {
                        updates['paid_date'] = DateTime.now().toIso8601String();
                      }
                      await ref
                          .read(loanUsersRepositoryProvider)
                          .updateRepayment(repaymentId, updates);
                      ref.invalidate(repaymentDetailsProvider(repaymentId));
                      ref.invalidate(connectionRepaymentsProvider);
                      ref.invalidate(monthlyStatsProvider);
                      ref.invalidate(dashboardSummaryProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment Confirmed')),
                        );
                        context.pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colors(context).success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Confirm Payment'),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(loanUsersRepositoryProvider)
                          .updateRepayment(repaymentId, {
                            'status': 'rejected',
                            'paid_date': null,
                          });
                      ref.invalidate(repaymentDetailsProvider(repaymentId));
                      ref.invalidate(connectionRepaymentsProvider);
                      ref.invalidate(monthlyStatsProvider);
                      ref.invalidate(dashboardSummaryProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment Rejected')),
                        );
                        context.pop();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.colors(context).danger,
                      side: BorderSide(color: AppTheme.colors(context).danger),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Reject & Request Resubmission'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, 
    String label,
    String value, {
    Color? color,
    String? warning,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTheme.text(context).labelBold),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: color != null
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: color ?? AppTheme.colors(context).textPrimary,
                  ),
                ),
                if (warning != null)
                  Text(
                    warning,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic repayment,
  ) async {
    final noteController = TextEditingController(text: repayment.note);
    DateTime? selectedDueDate = repayment.dueDate;
    DateTime? selectedPaidDate = repayment.paidDate;
    String? selectedMethod = repayment.method;

    final List<String> paymentMethods = [
      'cash',
      'bank_transfer',
      'jazzcash',
      'eaisypaisa',
      'other',
    ];

    if (selectedMethod != null && !paymentMethods.contains(selectedMethod)) {
      paymentMethods.add(selectedMethod);
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Payment Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Amount is not editable as requested
                    TextField(
                      controller: TextEditingController(
                        text: repayment.amount.toString(),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (Read Only)',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                      ),
                      items: paymentMethods.map((method) {
                        String displayMethod = method;
                        switch (method) {
                          case 'bank_transfer':
                            displayMethod = 'Bank Transfer';
                            break;
                          case 'jazzcash':
                            displayMethod = 'JazzCash';
                            break;
                          case 'eaisypaisa':
                            displayMethod = 'Easypaisa';
                            break;
                          case 'cash':
                            displayMethod = 'Cash';
                            break;
                          case 'other':
                            displayMethod = 'Other';
                            break;
                        }

                        return DropdownMenuItem(
                          value: method,
                          child: Text(displayMethod),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedMethod = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Borrower Note',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Due Date',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        selectedDueDate != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(selectedDueDate!)
                            : 'Not Set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => selectedDueDate = date);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Paid Date',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        selectedPaidDate != null
                            ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(selectedPaidDate!)
                            : 'Not Set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedPaidDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => selectedPaidDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updates = <String, dynamic>{};

                    if (selectedMethod != repayment.method) {
                      updates['method'] = selectedMethod;
                    }
                    if (noteController.text.trim() != repayment.note) {
                      updates['note'] = noteController.text.trim();
                    }
                    if (selectedDueDate != repayment.dueDate) {
                      updates['due_date'] = selectedDueDate?.toIso8601String();
                    }
                    if (selectedPaidDate != repayment.paidDate) {
                      updates['paid_date'] = selectedPaidDate
                          ?.toIso8601String();
                    }

                    if (updates.isNotEmpty) {
                      await ref
                          .read(loanUsersRepositoryProvider)
                          .updateRepayment(repayment.id, updates);
                      ref.invalidate(repaymentDetailsProvider(repayment.id));
                      ref.invalidate(connectionRepaymentsProvider);
                      ref.invalidate(monthlyStatsProvider);
                      ref.invalidate(dashboardSummaryProvider);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
