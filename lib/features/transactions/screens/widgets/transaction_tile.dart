import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../lender_dashboard/theme/dashboard_theme.dart';
import '../../models/transaction_model.dart';
import 'transaction_detail_dialog.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isMoneyIn = transaction.direction == TransactionDirection.moneyIn;
    final iconColor = isMoneyIn
        ? DashboardTheme.success
        : DashboardTheme.danger;
    final iconBg = isMoneyIn
        ? DashboardTheme.successSurface
        : DashboardTheme.dangerSurface;
    final icon = isMoneyIn
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final formattedAmount = currencyFormatter.format(transaction.amount);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              TransactionDetailDialog(transaction: transaction),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DashboardTheme.spacingLg,
          vertical: DashboardTheme.spacingMd,
        ),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(DashboardTheme.spacingSm),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: DashboardTheme.radiusSm,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),

            const SizedBox(width: DashboardTheme.spacingMd),

            // ── Details ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.counterpartyName,
                    style: DashboardTheme.headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        transaction.category,
                        style: DashboardTheme.bodyMedium,
                      ),
                      const SizedBox(width: 6),
                      _buildStatusBadge(),
                    ],
                  ),
                ],
              ),
            ),

            // ── Amount ─────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isMoneyIn ? '+$formattedAmount' : '-$formattedAmount',
                  style: DashboardTheme.headingSmall.copyWith(
                    color: isMoneyIn
                        ? DashboardTheme.success
                        : DashboardTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('h:mm a').format(transaction.date),
                  style: DashboardTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (transaction.status) {
      case 'pending':
        color = DashboardTheme.warning;
        break;
      case 'rejected':
      case 'missed':
        color = DashboardTheme.danger;
        break;
      case 'confirmed':
      case 'active':
      default:
        return const SizedBox.shrink(); // Don't show badge for confirmed to keep it clean
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        transaction.status.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
