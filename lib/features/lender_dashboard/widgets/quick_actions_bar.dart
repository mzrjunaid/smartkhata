import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartkhata/core/theme/app_theme.dart';

/// A modern row of 4 primary quick-action buttons for common lender operations.
class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionButton(
            icon: Icons.add_rounded,
            label: 'New Loan',
            color: AppTheme.colors(context).primary,
            backgroundColor: AppTheme.colors(context).primarySurface,
            onTap: () => context.push('/new-loan'),
          ),
          _ActionButton(
            icon: Icons.calendar_month_rounded,
            label: 'Schedule',
            color: AppTheme.colors(context).accent,
            backgroundColor: AppTheme.colors(context).accentSurface,
            onTap: () => context.push('/repayments'),
          ),
          _ActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            color: AppTheme.colors(context).info,
            backgroundColor: AppTheme.colors(context).infoSurface,
            onTap: () {
              // TODO: Navigate to reports screen.
            },
          ),
          _ActionButton(
            icon: Icons.notifications_active_rounded,
            label: 'Remind',
            color: AppTheme.colors(context).warning,
            backgroundColor: AppTheme.colors(context).warningSurface,
            onTap: () {
              // TODO: Navigate to send reminder screen.
            },
          ),
        ],
      ),
    );
  }
}

/// Private stateless button used only inside [QuickActionsBar].
class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.text(context).labelBold.copyWith(
                fontSize: 12,
                color: AppTheme.colors(context).textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
