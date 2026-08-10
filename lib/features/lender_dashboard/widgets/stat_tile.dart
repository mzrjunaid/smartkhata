import 'package:flutter/material.dart';

import '../theme/dashboard_theme.dart';

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
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Icon badge ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(DashboardTheme.spacingSm),
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? DashboardTheme.primarySurface,
              borderRadius: DashboardTheme.radiusSm,
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? DashboardTheme.primary,
            ),
          ),

          const SizedBox(height: DashboardTheme.spacingMd),

          // ── Label ─────────────────────────────────────────────────
          Text(label, style: DashboardTheme.bodyMedium),

          const SizedBox(height: DashboardTheme.spacingXs),

          // ── Value ─────────────────────────────────────────────────
          Text(
            value,
            style: DashboardTheme.valueDisplay,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // ── Trend indicator (optional) ────────────────────────────
          if (trend != null) ...[
            const SizedBox(height: DashboardTheme.spacingSm),
            Row(
              children: [
                Icon(
                  trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: trend! >= 0
                      ? DashboardTheme.success
                      : DashboardTheme.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  trendLabel ?? '${trend!.abs().toStringAsFixed(1)}%',
                  style: DashboardTheme.bodySmall.copyWith(
                    color: trend! >= 0
                        ? DashboardTheme.success
                        : DashboardTheme.danger,
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
