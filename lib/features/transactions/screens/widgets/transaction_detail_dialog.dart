import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../lender_dashboard/theme/dashboard_theme.dart';
import '../../models/transaction_model.dart';

class TransactionDetailDialog extends StatelessWidget {
  const TransactionDetailDialog({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isMoneyIn = transaction.direction == TransactionDirection.moneyIn;
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Container(
      decoration: const BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMoneyIn ? DashboardTheme.successSurface : DashboardTheme.dangerSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMoneyIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 32,
              color: isMoneyIn ? DashboardTheme.success : DashboardTheme.danger,
            ),
          ),
          const SizedBox(height: 16),
          
          // Amount
          Text(
            currencyFormatter.format(transaction.amount),
            style: DashboardTheme.headingLarge.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            transaction.category,
            style: DashboardTheme.bodyMedium,
          ),
          
          const SizedBox(height: 32),
          
          // Details List
          _buildDetailRow('Status', transaction.status.toUpperCase(), 
            valueColor: transaction.status == 'pending' ? DashboardTheme.warning : null),
          _buildDivider(),
          _buildDetailRow('Date', DateFormat('MMMM d, yyyy').format(transaction.date)),
          _buildDivider(),
          _buildDetailRow('Time', DateFormat('h:mm a').format(transaction.date)),
          _buildDivider(),
          _buildDetailRow(isMoneyIn ? 'From' : 'To', transaction.counterpartyName),
          
          if (transaction.dueDate != null) ...[
            _buildDivider(),
            _buildDetailRow('Due Date', DateFormat('MMMM d, yyyy').format(transaction.dueDate!)),
          ],
          
          if (transaction.paidDate != null) ...[
            _buildDivider(),
            _buildDetailRow('Paid Date', DateFormat('MMMM d, yyyy').format(transaction.paidDate!)),
          ],
          
          if (transaction.confirmedBy != null && transaction.confirmedBy!.isNotEmpty) ...[
            _buildDivider(),
            _buildDetailRow('Confirmed By', transaction.confirmedBy!),
          ],
          
          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            _buildDivider(),
            _buildDetailRow('Notes', transaction.notes!),
          ],
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: DashboardTheme.bodyMedium),
          Text(
            value,
            style: DashboardTheme.headingSmall.copyWith(color: valueColor ?? DashboardTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade200);
  }
}
