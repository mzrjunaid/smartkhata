import 'package:flutter/material.dart';

import '../models/loan_activity.dart';
import 'package:smartkhata/core/theme/app_theme.dart';

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

  Color _iconColor(BuildContext context) {
    switch (activity.type) {
      case ActivityType.repaymentConfirmed:
        return AppTheme.colors(context).success;
      case ActivityType.repaymentPending:
        return AppTheme.colors(context).warning;
      case ActivityType.repaymentRejected:
      case ActivityType.repaymentMissed:
      case ActivityType.overdue:
        return AppTheme.colors(context).danger;
      case ActivityType.disbursed:
        return AppTheme.colors(context).accent;
    }
  }

  Color _iconBg(BuildContext context) {
    switch (activity.type) {
      case ActivityType.repaymentConfirmed:
        return AppTheme.colors(context).successSurface;
      case ActivityType.repaymentPending:
        return AppTheme.colors(context).warningSurface;
      case ActivityType.repaymentRejected:
      case ActivityType.repaymentMissed:
      case ActivityType.overdue:
        return AppTheme.colors(context).dangerSurface;
      case ActivityType.disbursed:
        return AppTheme.colors(context).accentSurface;
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
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        children: [
          // ── Colored icon ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: _iconBg(context),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(_icon, size: 20, color: _iconColor(context)),
          ),

          SizedBox(width: AppTheme.spacingMd),

          // ── Details ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.borrowerName,
                  style: AppTheme.text(context).headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(_typeLabel, style: AppTheme.text(context).bodyMedium),
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
                style: AppTheme.text(context).headingSmall.copyWith(
                  color: activity.type == ActivityType.repaymentConfirmed
                      ? AppTheme.colors(context).success
                      : (activity.type == ActivityType.repaymentPending
                          ? AppTheme.colors(context).warning
                          : AppTheme.colors(context).textPrimary),
                ),
              ),
              SizedBox(height: 2),
              Text(relativeDate, style: AppTheme.text(context).bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
