import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/dashboard_theme.dart';

/// Horizontal row of quick-action chips for common lender operations.
class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: DashboardTheme.spacingLg,
        ),
        children: [
          _ActionChip(
            icon: Icons.add_circle_outline,
            label: 'New Loan',
            color: DashboardTheme.primary,
            backgroundColor: DashboardTheme.primarySurface,
            onTap: () => context.push('/new-loan'),
          ),
          const SizedBox(width: DashboardTheme.spacingSm),
          _ActionChip(
            icon: Icons.calendar_month_outlined,
            label: 'Repayments',
            color: Colors.blue,
            backgroundColor: Colors.blue.shade50,
            onTap: () => context.push('/repayments'),
          ),
          const SizedBox(width: DashboardTheme.spacingSm),
          _ActionChip(
            icon: Icons.payments_outlined,
            label: 'Record Payment',
            color: DashboardTheme.accent,
            backgroundColor: DashboardTheme.accentSurface,
            onTap: () {
              // TODO: Navigate to record payment screen.
            },
          ),
          const SizedBox(width: DashboardTheme.spacingSm),
          _ActionChip(
            icon: Icons.notifications_active_outlined,
            label: 'Send Reminder',
            color: DashboardTheme.warning,
            backgroundColor: DashboardTheme.warningSurface,
            onTap: () {
              // TODO: Navigate to send reminder screen.
            },
          ),
          const SizedBox(width: DashboardTheme.spacingSm),
          _ActionChip(
            icon: Icons.history_edu_rounded,
            label: 'Audit Logs',
            color: Colors.purple,
            backgroundColor: Colors.purple.shade50,
            onTap: () => context.push('/audit-logs'),
          ),
          const SizedBox(width: DashboardTheme.spacingSm),
          _ActionChip(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            color: DashboardTheme.textSecondary,
            backgroundColor: DashboardTheme.surface,
            onTap: () {
              // TODO: Navigate to reports screen.
            },
          ),
        ],
      ),
    );
  }
}

/// Private stateless chip used only inside [QuickActionsBar].
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: DashboardTheme.radiusSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: DashboardTheme.radiusSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: DashboardTheme.labelBold.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
