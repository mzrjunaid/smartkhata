import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/dashboard_providers.dart';
import '../theme/dashboard_theme.dart';
import 'section_header.dart';

/// Bar chart comparing monthly Disbursed vs Collected for the last 6 months.
///
/// Uses `fl_chart` and self-manages its async state via [monthlyStatsProvider].
class LoanPerformanceChart extends ConsumerWidget {
  const LoanPerformanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(monthlyStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Loan Performance'),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: DashboardTheme.spacingLg,
          ),
          padding: const EdgeInsets.all(DashboardTheme.spacingLg),
          decoration: DashboardTheme.cardDecoration,
          child: statsAsync.when(
            loading: () => _buildShimmer(),
            error: (e, _) => SizedBox(
              height: 200,
              child: Center(
                child: Text('Error: $e', style: DashboardTheme.bodyMedium),
              ),
            ),
            data: (stats) {
              return Column(
                children: [
                  // ── Legend ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(DashboardTheme.primary, 'Disbursed'),
                      const SizedBox(width: DashboardTheme.spacingLg),
                      _legendDot(DashboardTheme.accent, 'Collected'),
                    ],
                  ),

                  const SizedBox(height: DashboardTheme.spacingLg),

                  // ── Chart ─────────────────────────────────────────
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _maxY(stats),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final label =
                                  rodIndex == 0 ? 'Disbursed' : 'Collected';
                              return BarTooltipItem(
                                '$label\n₨ ${_compact(rod.toY)}',
                                DashboardTheme.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
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
                                    style: DashboardTheme.bodySmall,
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  _compact(value),
                                  style: DashboardTheme.bodySmall,
                                );
                              },
                            ),
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
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          ),
                        ),
                        barGroups: [
                          for (int i = 0; i < stats.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: stats[i].disbursed,
                                  color: DashboardTheme.primary,
                                  width: 12,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: stats[i].collected,
                                  color: DashboardTheme.accent,
                                  width: 12,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
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

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: DashboardTheme.bodyMedium),
      ],
    );
  }

  double _maxY(List stats) {
    double max = 0;
    for (final s in stats) {
      if (s.disbursed > max) max = s.disbursed;
      if (s.collected > max) max = s.collected;
    }
    return max * 1.2; // 20% headroom
  }

  String _compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Column(
        children: [
          Container(width: 200, height: 14, color: Colors.white),
          const SizedBox(height: DashboardTheme.spacingLg),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: DashboardTheme.radiusMd,
            ),
          ),
        ],
      ),
    );
  }
}
