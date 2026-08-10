import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:smartkhata/core/theme/app_theme.dart';
import '../../providers/transactions_providers.dart';

class TransactionSummaryCard extends ConsumerWidget {
  const TransactionSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(transactionSummaryProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(context, 
            label: 'Total In',
            amount: summary['in'] ?? 0.0,
            color: AppTheme.colors(context).success,
            icon: Icons.arrow_downward_rounded,
            formatter: currencyFormatter,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.colors(context).textTertiary.withValues(alpha: 0.2),
          ),
          _buildStat(context, 
            label: 'Total Out',
            amount: summary['out'] ?? 0.0,
            color: AppTheme.colors(context).danger,
            icon: Icons.arrow_upward_rounded,
            formatter: currencyFormatter,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required NumberFormat formatter,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            SizedBox(width: 4),
            Text(label, style: AppTheme.text(context).bodySmall),
          ],
        ),
        SizedBox(height: 8),
        Text(
          formatter.format(amount),
          style: AppTheme.text(context).headingMedium.copyWith(color: color),
        ),
      ],
    );
  }
}
