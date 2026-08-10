import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smartkhata/core/theme/app_theme.dart';
import '../../models/transaction_model.dart';
import 'transaction_detail_dialog.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isMoneyIn = transaction.direction == TransactionDirection.moneyIn;
    final iconColor = isMoneyIn
        ? AppTheme.colors(context).success
        : AppTheme.colors(context).danger;
    final iconBg = isMoneyIn
        ? AppTheme.colors(context).successSurface
        : AppTheme.colors(context).dangerSurface;
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
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingMd,
        ),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: AppTheme.radiusSm,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),

            SizedBox(width: AppTheme.spacingMd),

            // ── Details ───────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.counterpartyName,
                    style: AppTheme.text(context).headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        transaction.category,
                        style: AppTheme.text(context).bodyMedium,
                      ),
                      SizedBox(width: 6),
                      _buildStatusBadge(context),
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
                  style: AppTheme.text(context).headingSmall.copyWith(
                    color: isMoneyIn
                        ? AppTheme.colors(context).success
                        : AppTheme.colors(context).textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  DateFormat('h:mm a').format(transaction.date),
                  style: AppTheme.text(context).bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    switch (transaction.status) {
      case 'pending':
        color = AppTheme.colors(context).warning;
        break;
      case 'rejected':
      case 'missed':
        color = AppTheme.colors(context).danger;
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
