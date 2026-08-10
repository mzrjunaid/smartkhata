import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../lender_dashboard/theme/dashboard_theme.dart';
import '../../providers/transactions_providers.dart';

class TransactionSummaryCard extends ConsumerWidget {
  const TransactionSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(transactionSummaryProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: DashboardTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            label: 'Total In',
            amount: summary['in'] ?? 0.0,
            color: DashboardTheme.success,
            icon: Icons.arrow_downward_rounded,
            formatter: currencyFormatter,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          _buildStat(
            label: 'Total Out',
            amount: summary['out'] ?? 0.0,
            color: DashboardTheme.danger,
            icon: Icons.arrow_upward_rounded,
            formatter: currencyFormatter,
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
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
            const SizedBox(width: 4),
            Text(label, style: DashboardTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          formatter.format(amount),
          style: DashboardTheme.headingMedium.copyWith(color: color),
        ),
      ],
    );
  }
}
