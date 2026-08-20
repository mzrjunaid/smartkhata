import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/profile_providers.dart';
import '../../loan_users/data/loan_users_repository.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../lender_dashboard/providers/dashboard_providers.dart';
import '../../../core/widgets/dashboard_app_bar.dart';
import '../../loan_users/models/repayment_model.dart';

class RepaymentReviewScreen extends ConsumerStatefulWidget {
  const RepaymentReviewScreen({super.key, required this.repaymentId});

  final String repaymentId;

  @override
  ConsumerState<RepaymentReviewScreen> createState() =>
      _RepaymentReviewScreenState();
}

class _RepaymentReviewScreenState extends ConsumerState<RepaymentReviewScreen> {
  final _noteController = TextEditingController();
  DateTime? _selectedDueDate;
  DateTime? _selectedPaidDate;
  String? _selectedMethod;
  String? _selectedFileName; // Mock file state
  bool _isInit = false;
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'cash',
    'bank_transfer',
    'jazzcash',
    'eaisypaisa',
    'other',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _initData(RepaymentModel repayment) {
    if (!_isInit) {
      _noteController.text = repayment.note ?? '';
      _selectedDueDate = repayment.dueDate;
      _selectedPaidDate = repayment.paidDate;
      _selectedMethod = repayment.method;

      if (_selectedMethod != null && !_paymentMethods.contains(_selectedMethod)) {
        _paymentMethods.add(_selectedMethod!);
      }
      _isInit = true;
    }
  }

  Future<void> _updateRepayment(String status, RepaymentModel repayment) async {
    setState(() => _isLoading = true);
    try {
      final profileId = await ref.read(currentProfileIdProvider.future);
      final updates = <String, dynamic>{
        'status': status,
        'method': _selectedMethod,
        'note': _noteController.text.trim(),
      };

      if (status == 'confirmed') {
        updates['confirmed_by'] = profileId;
        // Auto set paid date if confirming and none exists
        if (_selectedPaidDate == null) {
          updates['paid_date'] = DateTime.now().toIso8601String();
        } else {
          updates['paid_date'] = _selectedPaidDate?.toIso8601String();
        }
      } else if (status == 'rejected') {
        updates['paid_date'] = null;
      } else {
        // Just saving updates without changing status
        updates['due_date'] = _selectedDueDate?.toIso8601String();
        updates['paid_date'] = _selectedPaidDate?.toIso8601String();
      }

      await ref.read(loanUsersRepositoryProvider).updateRepayment(
            widget.repaymentId,
            updates,
          );

      ref.invalidate(repaymentDetailsProvider(widget.repaymentId));
      ref.invalidate(connectionRepaymentsProvider);
      ref.invalidate(monthlyStatsProvider);
      ref.invalidate(dashboardSummaryProvider);

      if (mounted) {
        String msg = 'Payment updated successfully';
        if (status == 'confirmed') msg = 'Payment Confirmed';
        if (status == 'rejected') msg = 'Payment Rejected';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: status == 'rejected' ? AppTheme.colors(context).danger : AppTheme.colors(context).success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.colors(context).danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repaymentAsync = ref.watch(repaymentDetailsProvider(widget.repaymentId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: repaymentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (repayment) {
          _initData(repayment);
          final isPending = repayment.status == 'pending_confirmation' || repayment.status == 'pending';

          return Column(
            children: [
              DashboardAppBar(
                title: 'Review Payment',
                subtitle: 'Verify or update repayment details',
                showBackButton: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Amount (Read Only)
                      _buildSectionTitle('Amount (PKR)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: repayment.amount.toStringAsFixed(0),
                        readOnly: true,
                        enabled: false,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                          prefixIcon: Icon(
                            Icons.payments_rounded,
                            color: AppTheme.colors(context).accent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Display
                      _buildSectionTitle('Current Status'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPending ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                              color: isPending ? AppTheme.colors(context).warning : AppTheme.colors(context).success,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              repayment.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isPending ? AppTheme.colors(context).warning : AppTheme.colors(context).success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Payment Method
                      _buildSectionTitle('Payment Method'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _paymentMethods.map((m) {
                          if (m == _selectedMethod) {
                            switch (m) {
                              case 'bank_transfer': return 'Bank Transfer';
                              case 'jazzcash': return 'JazzCash';
                              case 'eaisypaisa': return 'Easypaisa';
                              case 'cash': return 'Cash';
                              case 'other': return 'Other';
                              default: return m;
                            }
                          }
                          return null;
                        }).firstWhere((m) => m != null, orElse: () => _selectedMethod ?? 'Unknown'),
                        readOnly: true,
                        enabled: false,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.colors(context).textPrimary,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                          prefixIcon: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppTheme.colors(context).primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dates row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Due Date'),
                                const SizedBox(height: 8),
                                _buildDateSelector(
                                  context: context,
                                  isDark: isDark,
                                  date: _selectedDueDate,
                                  onSelect: (date) => setState(() => _selectedDueDate = date),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Paid Date'),
                                const SizedBox(height: 8),
                                _buildDateSelector(
                                  context: context,
                                  isDark: isDark,
                                  date: _selectedPaidDate,
                                  onSelect: (date) => setState(() => _selectedPaidDate = date),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Note
                      _buildSectionTitle('Borrower Note'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        readOnly: true,
                        enabled: false,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                          hintText: 'No note provided',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Attachment
                      _buildSectionTitle('Payment Receipt'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: null, // Read-only
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _selectedFileName != null
                                ? AppTheme.colors(context).primarySurface
                                : (isDark ? const Color(0xFF1E1E24) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedFileName != null
                                  ? AppTheme.colors(context).primary.withValues(alpha: 0.5)
                                  : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedFileName != null ? Icons.check_circle_rounded : Icons.insert_drive_file_rounded,
                                color: _selectedFileName != null 
                                    ? AppTheme.colors(context).primary 
                                    : AppTheme.colors(context).textSecondary,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedFileName != null ? 'Receipt Attached' : 'No Receipt Attached',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedFileName != null
                                            ? AppTheme.colors(context).primary
                                            : AppTheme.colors(context).textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedFileName ?? 'No file provided by borrower',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.colors(context).textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Actions
                      if (isPending) ...[
                        _buildPrimaryAction(
                          context: context,
                          label: 'Confirm Payment',
                          color: AppTheme.colors(context).success,
                          gradient: LinearGradient(
                            colors: [AppTheme.colors(context).success, const Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          isLoading: _isLoading,
                          onTap: () => _updateRepayment('confirmed', repayment),
                        ),
                        const SizedBox(height: 16),
                        _buildSecondaryAction(
                          context: context,
                          label: 'Reject & Request Resubmission',
                          color: AppTheme.colors(context).danger,
                          isLoading: _isLoading,
                          onTap: () => _updateRepayment('rejected', repayment),
                        ),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.colors(context).textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required BuildContext context,
    required bool isDark,
    required DateTime? date,
    required Function(DateTime) onSelect,
  }) {
    return InkWell(
      onTap: null, // Read-only
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E24) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: AppTheme.colors(context).primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Not Set',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors(context).textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAction({
    required BuildContext context,
    required String label,
    required Color color,
    required Gradient gradient,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction({
    required BuildContext context,
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
