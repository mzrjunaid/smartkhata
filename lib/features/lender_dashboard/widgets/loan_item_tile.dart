import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

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

  Color get _statusColor {
    switch (status) {
      case 'overdue':
        return DashboardTheme.danger;
      case 'paid':
        return DashboardTheme.success;
      default:
        return DashboardTheme.accent;
    }
  }

  Color get _statusBg {
    switch (status) {
      case 'overdue':
        return DashboardTheme.dangerSurface;
      case 'paid':
        return DashboardTheme.successSurface;
      default:
        return DashboardTheme.accentSurface;
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
      borderRadius: DashboardTheme.radiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DashboardTheme.spacingLg,
          vertical: DashboardTheme.spacingMd,
        ),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────
            CircleAvatar(
              radius: 20,
              backgroundColor: DashboardTheme.primarySurface,
              child: Text(
                initials,
                style: DashboardTheme.labelBold.copyWith(
                  color: DashboardTheme.primary,
                ),
              ),
            ),

            const SizedBox(width: DashboardTheme.spacingMd),

            // ── Name & amount ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    borrowerName,
                    style: DashboardTheme.headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(amount, style: DashboardTheme.bodyMedium),
                ],
              ),
            ),

            // ── Status badge ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius: DashboardTheme.radiusSm,
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: DashboardTheme.bodySmall.copyWith(
                  color: _statusColor,
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
