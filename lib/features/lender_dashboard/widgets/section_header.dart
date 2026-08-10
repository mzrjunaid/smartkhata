import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

/// Reusable section header with a title and an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onViewAll,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DashboardTheme.spacingLg,
        vertical: DashboardTheme.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: DashboardTheme.headingMedium),
          if (trailing != null)
            trailing!
          else if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: DashboardTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: DashboardTheme.labelBold,
              ),
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }
}
