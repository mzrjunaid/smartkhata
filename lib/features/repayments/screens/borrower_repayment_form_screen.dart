import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';
import '../../loan_users/models/repayment_model.dart';
import '../../lender_dashboard/providers/dashboard_providers.dart';
import '../../../core/widgets/dashboard_app_bar.dart';

class BorrowerRepaymentFormScreen extends ConsumerStatefulWidget {
  const BorrowerRepaymentFormScreen({super.key, this.repaymentId, this.loanId});

  final String? repaymentId;
  final String? loanId;

  @override
  ConsumerState<BorrowerRepaymentFormScreen> createState() =>
      _BorrowerRepaymentFormScreenState();
}

class _BorrowerRepaymentFormScreenState
    extends ConsumerState<BorrowerRepaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedMethod = 'bank_transfer';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isInit = false;
  String? _selectedFileName;

  final List<String> _methods = [
    'bank_transfer',
    'eaisypaisa',
    'jazzcash',
    'cash',
    'other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit(RepaymentModel? existingRepayment) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(loanUsersRepositoryProvider);
      final amount = double.parse(_amountController.text);

      if (widget.repaymentId != null) {
        // Update existing scheduled repayment
        await repo.updateRepayment(widget.repaymentId!, {
          'status': 'pending_confirmation',
          'amount': amount,
          'method': _selectedMethod,
          'note': _noteController.text,
          'paid_date': _selectedDate.toIso8601String(),
        });
        ref.invalidate(repaymentDetailsProvider(widget.repaymentId!));
      } else if (widget.loanId != null) {
        // Create new ad-hoc repayment
        await repo.submitAdHocRepayment(
          widget.loanId!,
          amount,
          _selectedMethod,
          _noteController.text,
          _selectedDate,
        );
      }

      ref.invalidate(connectionRepaymentsProvider);
      ref.invalidate(monthlyStatsProvider);
      ref.invalidate(dashboardSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment submitted successfully!'),
            backgroundColor: AppTheme.colors(context).success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.colors(context).danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.repaymentId != null) {
      final repaymentAsync = ref.watch(
        repaymentDetailsProvider(widget.repaymentId!),
      );
      return repaymentAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (repayment) {
          if (!_isInit) {
            _amountController.text = repayment.amount.toStringAsFixed(0);
            if (repayment.method != null && _methods.contains(repayment.method)) {
              _selectedMethod = repayment.method!;
            }
            if (repayment.note != null) {
              _noteController.text = repayment.note!;
            }
            if (repayment.paidDate != null) {
              _selectedDate = repayment.paidDate!;
            }
            _isInit = true;
          }
          return _buildForm(context, repayment);
        },
      );
    } else {
      return _buildForm(context, null);
    }
  }

  Widget _buildForm(BuildContext context, RepaymentModel? existingRepayment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReadOnly = existingRepayment?.status == 'pending_confirmation';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          DashboardAppBar(
            title: existingRepayment != null ? 'Pay Installment' : 'Make Payment',
            subtitle: 'Securely submit your payment',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (existingRepayment != null &&
                  existingRepayment.dueDate != null) ...[
                _buildDueDateCard(context, existingRepayment.dueDate!),
                const SizedBox(height: 32),
              ],

              _buildSectionTitle('Amount (PKR)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                readOnly: isReadOnly,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                  hintText: '0.00',
                  prefixIcon: Icon(
                    Icons.payments_rounded,
                    color: AppTheme.colors(context).accent,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.colors(context).accent,
                      width: 2,
                    ),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(val) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(val) <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Payment Method'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                items: _methods.map((method) {
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
                  return DropdownMenuItem(value: method, child: Text(displayMethod));
                }).toList(),
                onChanged: isReadOnly ? null : (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMethod = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Date Paid'),
              const SizedBox(height: 8),
              InkWell(
                onTap: isReadOnly ? null : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: AppTheme.colors(context).primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat.yMMMMd().format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.colors(context).textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.edit_calendar_rounded, color: AppTheme.colors(context).textSecondary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Reference / Note (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                readOnly: isReadOnly,
                maxLines: 3,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
                  hintText: 'Add a note about this payment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Payment Receipt (Optional)'),
              const SizedBox(height: 8),
              InkWell(
                onTap: isReadOnly ? null : () {
                  setState(() {
                    _selectedFileName =
                        'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
                  });
                },
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
                        _selectedFileName != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
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
                              _selectedFileName != null ? 'Receipt Attached' : 'Upload Receipt',
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
                              _selectedFileName ?? 'Tap to select an image or PDF',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.colors(context).textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedFileName != null && !isReadOnly)
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: AppTheme.colors(context).danger),
                          onPressed: () {
                            setState(() {
                              _selectedFileName = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              if (!isReadOnly)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.colors(context).primary,
                        AppTheme.colors(context).accent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.colors(context).primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : () => _submit(existingRepayment),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'Submit Payment',
                                  style: TextStyle(
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
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Waiting for confirmation',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    ),
  ],
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

  Widget _buildDueDateCard(BuildContext context, DateTime dueDate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.blue.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scheduled Due Date',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMMd().format(dueDate.toLocal()),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
