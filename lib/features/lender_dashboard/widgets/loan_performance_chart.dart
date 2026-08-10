import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/dashboard_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import 'section_header.dart';

/// A modern, sleek Line (Area) chart comparing monthly Disbursed vs Collected.
/// Uses `fl_chart` and self-manages its async state.
class LoanPerformanceChart extends ConsumerWidget {
  const LoanPerformanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(monthlyStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Loan Performance'),
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
          ),
          padding: EdgeInsets.all(AppTheme.spacingLg),
          decoration: AppTheme.cardDecoration(context),
          child: statsAsync.when(
            loading: () => _buildShimmer(context, isDark),
            error: (e, _) => SizedBox(
              height: 200,
              child: Center(
                child: Text('Error: $e', style: AppTheme.text(context).bodyMedium),
              ),
            ),
            data: (stats) {
              return Column(
                children: [
                  // ── Legend ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(context, AppTheme.colors(context).primary, 'Disbursed'),
                      SizedBox(width: AppTheme.spacingLg),
                      _legendDot(context, AppTheme.colors(context).accent, 'Collected'),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // ── Chart ─────────────────────────────────────────
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: _maxY(stats),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final label = spot.barIndex == 0 ? 'Collected' : 'Disbursed';
                                return LineTooltipItem(
                                  '$label\n₨ ${_compact(spot.y)}',
                                  AppTheme.text(context).bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= stats.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    stats[idx].month,
                                    style: AppTheme.text(context).bodySmall.copyWith(
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _maxY(stats) / 4,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                        ),
                        lineBarsData: [
                          // Collected Line
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < stats.length; i++)
                                FlSpot(i.toDouble(), stats[i].collected),
                            ],
                            isCurved: true,
                            color: AppTheme.colors(context).accent,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.colors(context).accent.withValues(alpha: 0.1),
                            ),
                          ),
                          // Disbursed Line
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < stats.length; i++)
                                FlSpot(i.toDouble(), stats[i].disbursed),
                            ],
                            isCurved: true,
                            color: AppTheme.colors(context).primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.colors(context).primary.withValues(alpha: 0.3),
                                  AppTheme.colors(context).primary.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.text(context).bodyMedium),
      ],
    );
  }

  double _maxY(List stats) {
    double max = 0;
    for (final s in stats) {
      if (s.disbursed > max) max = s.disbursed;
      if (s.collected > max) max = s.collected;
    }
    if (max == 0) return 100;
    return max * 1.2; // 20% headroom
  }

  String _compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  Widget _buildShimmer(BuildContext context, bool isDark) {
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade50;
    final blockColor = isDark ? Colors.grey.shade900 : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          Container(width: 200, height: 14, color: blockColor),
          const SizedBox(height: AppTheme.spacingLg),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: AppTheme.radiusMd,
            ),
          ),
        ],
      ),
    );
  }
}
