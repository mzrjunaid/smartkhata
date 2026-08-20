import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smartkhata/core/theme/app_theme.dart';
import '../../models/transaction_model.dart';

class TransactionDetailDialog extends StatelessWidget {
  const TransactionDetailDialog({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isMoneyIn = transaction.direction == TransactionDirection.moneyIn;
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors(context).surface,
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
              color: AppTheme.colors(context).textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 24),
          
          // Header icon
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMoneyIn ? AppTheme.colors(context).successSurface : AppTheme.colors(context).dangerSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMoneyIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 32,
              color: isMoneyIn ? AppTheme.colors(context).success : AppTheme.colors(context).danger,
            ),
          ),
          SizedBox(height: 16),
          
          // Amount
          Text(
            currencyFormatter.format(transaction.amount),
            style: AppTheme.text(context).headingLarge.copyWith(fontSize: 32),
          ),
          SizedBox(height: 8),
          Text(
            transaction.category,
            style: AppTheme.text(context).bodyMedium,
          ),
          
          SizedBox(height: 32),
          
          // Details List
          _buildDetailRow(context, 'Status', transaction.status.toUpperCase().replaceAll('_', ' '), 
            valueColor: (transaction.status == 'pending' || transaction.status == 'pending_confirmation') ? AppTheme.colors(context).warning : null),
          _buildDivider(context),
          _buildDetailRow(context, 'Date', DateFormat('MMMM d, yyyy').format(transaction.date)),
          _buildDivider(context),
          _buildDetailRow(context, 'Time', DateFormat('h:mm a').format(transaction.date)),
          _buildDivider(context),
          _buildDetailRow(context, isMoneyIn ? 'From' : 'To', transaction.counterpartyName),
          
          if (transaction.dueDate != null) ...[
            _buildDivider(context),
            _buildDetailRow(context, 'Due Date', DateFormat('MMMM d, yyyy').format(transaction.dueDate!)),
          ],
          
          if (transaction.paidDate != null) ...[
            _buildDivider(context),
            _buildDetailRow(context, 'Paid Date', DateFormat('MMMM d, yyyy').format(transaction.paidDate!)),
          ],
          
          if (transaction.confirmedBy != null && transaction.confirmedBy!.isNotEmpty) ...[
            _buildDivider(context),
            _buildDetailRow(context, 'Confirmed By', transaction.confirmedBy!),
          ],
          
          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            _buildDivider(context),
            _buildDetailRow(context, 'Notes', transaction.notes!),
          ],
          
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors(context).primary,
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

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.text(context).bodyMedium),
          Text(
            value,
            style: AppTheme.text(context).headingSmall.copyWith(color: valueColor ?? AppTheme.colors(context).textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(height: 1, color: AppTheme.colors(context).textTertiary.withValues(alpha: 0.3));
  }
}
