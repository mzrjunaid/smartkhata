import 'package:flutter/material.dart';

import 'package:smartkhata/core/theme/app_theme.dart';

/// Single loan row displaying avatar, borrower name, amount, and status badge.
class LoanItemTile extends StatelessWidget {
  const LoanItemTile({
    super.key,
    required this.borrowerName,
    required this.amount,
    required this.status,
    this.onTap,
  });

  final String borrowerName;
  final String amount;

  /// One of: active, overdue, paid.
  final String status;
  final VoidCallback? onTap;

  Color _statusColor(BuildContext context) {
    switch (status) {
      case 'overdue':
        return AppTheme.colors(context).danger;
      case 'paid':
        return AppTheme.colors(context).success;
      default:
        return AppTheme.colors(context).accent;
    }
  }

  Color _statusBg(BuildContext context) {
    switch (status) {
      case 'overdue':
        return AppTheme.colors(context).dangerSurface;
      case 'paid':
        return AppTheme.colors(context).successSurface;
      default:
        return AppTheme.colors(context).accentSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = borrowerName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.radiusSm,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingMd,
        ),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.colors(context).primarySurface,
                borderRadius: AppTheme.radiusSm,
              ),
              child: Text(
                initials,
                style: AppTheme.text(
                  context,
                ).labelBold.copyWith(color: AppTheme.colors(context).primary),
              ),
            ),

            SizedBox(width: AppTheme.spacingMd),

            // ── Name & amount ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    borrowerName,
                    style: AppTheme.text(context).headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(amount, style: AppTheme.text(context).bodyMedium),
                ],
              ),
            ),

            // ── Status badge ────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBg(context),
                borderRadius: AppTheme.radiusSm,
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: AppTheme.text(context).bodySmall.copyWith(
                  color: _statusColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
