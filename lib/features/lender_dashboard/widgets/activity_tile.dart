import 'package:flutter/material.dart';

import '../models/loan_activity.dart';
import '../theme/dashboard_theme.dart';

/// Single activity row with a colored leading icon, title, subtitle,
/// trailing amount, and relative date.
class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.activity,
    required this.formattedAmount,
    required this.relativeDate,
  });

  final LoanActivity activity;
  final String formattedAmount;
  final String relativeDate;

  IconData get _icon {
    switch (activity.type) {
      case ActivityType.repaymentConfirmed:
        return Icons.check_circle_outline;
      case ActivityType.repaymentPending:
        return Icons.pending_actions;
      case ActivityType.repaymentRejected:
        return Icons.cancel_outlined;
      case ActivityType.repaymentMissed:
        return Icons.error_outline;
      case ActivityType.disbursed:
        return Icons.arrow_upward_rounded;
      case ActivityType.overdue:
        return Icons.warning_amber_rounded;
    }
  }

  Color get _iconColor {
    switch (activity.type) {
      case ActivityType.repaymentConfirmed:
        return DashboardTheme.success;
      case ActivityType.repaymentPending:
        return DashboardTheme.warning;
      case ActivityType.repaymentRejected:
      case ActivityType.repaymentMissed:
      case ActivityType.overdue:
        return DashboardTheme.danger;
      case ActivityType.disbursed:
        return DashboardTheme.accent;
    }
  }

  Color get _iconBg {
    switch (activity.type) {
      case ActivityType.repaymentConfirmed:
        return DashboardTheme.successSurface;
      case ActivityType.repaymentPending:
        return DashboardTheme.warningSurface;
      case ActivityType.repaymentRejected:
      case ActivityType.repaymentMissed:
      case ActivityType.overdue:
        return DashboardTheme.dangerSurface;
      case ActivityType.disbursed:
        return DashboardTheme.accentSurface;
    }
  }

  String get _typeLabel {
    switch (activity.type) {
      case ActivityType.repaymentConfirmed:
        return 'Repayment received';
      case ActivityType.repaymentPending:
        return 'Repayment pending';
      case ActivityType.repaymentRejected:
        return 'Repayment rejected';
      case ActivityType.repaymentMissed:
        return 'Repayment missed';
      case ActivityType.disbursed:
        return 'Loan disbursed';
      case ActivityType.overdue:
        return 'Payment overdue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardTheme.spacingLg,
        vertical: DashboardTheme.spacingMd,
      ),
      child: Row(
        children: [
          // ── Colored icon ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(DashboardTheme.spacingSm),
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: DashboardTheme.radiusSm,
            ),
            child: Icon(_icon, size: 20, color: _iconColor),
          ),

          const SizedBox(width: DashboardTheme.spacingMd),

          // ── Details ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.borrowerName,
                  style: DashboardTheme.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(_typeLabel, style: DashboardTheme.bodyMedium),
              ],
            ),
          ),

          // ── Amount & time ─────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (activity.type == ActivityType.repaymentConfirmed || activity.type == ActivityType.repaymentPending)
                    ? '+$formattedAmount'
                    : formattedAmount,
                style: DashboardTheme.headingSmall.copyWith(
                  color: activity.type == ActivityType.repaymentConfirmed
                      ? DashboardTheme.success
                      : (activity.type == ActivityType.repaymentPending
                          ? DashboardTheme.warning
                          : DashboardTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(relativeDate, style: DashboardTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
