import 'package:flutter/material.dart';

import 'package:smartkhata/core/theme/app_theme.dart';

/// Reusable single-metric tile showing an icon, label, formatted value,
/// and an optional trend indicator (↑ / ↓ with color).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.iconBackgroundColor,
    this.trend,
    this.trendLabel,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  /// Positive = up-trend (green), negative = down-trend (red), null = hidden.
  final double? trend;
  final String? trendLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Icon badge ────────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? AppTheme.colors(context).primarySurface,
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? AppTheme.colors(context).primary,
            ),
          ),

          SizedBox(height: AppTheme.spacingMd),

          // ── Label ─────────────────────────────────────────────────
          Text(label, style: AppTheme.text(context).bodyMedium),

          SizedBox(height: AppTheme.spacingXs),

          // ── Value ─────────────────────────────────────────────────
          Text(
            value,
            style: AppTheme.text(context).valueDisplay,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // ── Trend indicator (optional) ────────────────────────────
          if (trend != null) ...[
            SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Icon(
                  trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: trend! >= 0
                      ? AppTheme.colors(context).success
                      : AppTheme.colors(context).danger,
                ),
                const SizedBox(width: 4),
                Text(
                  trendLabel ?? '${trend!.abs().toStringAsFixed(1)}%',
                  style: AppTheme.text(context).bodySmall.copyWith(
                    color: trend! >= 0
                        ? AppTheme.colors(context).success
                        : AppTheme.colors(context).danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
