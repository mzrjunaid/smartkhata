import 'package:flutter/material.dart';

import 'package:smartkhata/core/theme/app_theme.dart';

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
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.text(context).headingMedium),
          if (trailing != null)
            trailing!
          else if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.colors(context).primary,
                padding: EdgeInsets.symmetric(horizontal: 8),
                textStyle: AppTheme.text(context).labelBold,
              ),
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }
}
