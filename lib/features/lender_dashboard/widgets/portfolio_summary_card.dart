import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../models/dashboard_summary.dart';
import '../providers/dashboard_providers.dart';
import '../services/dashboard_service.dart';
import 'package:smartkhata/core/theme/app_theme.dart';

/// Displays a modern, banking-style glossy Hero Card for main balances,
/// followed by a row of secondary KPIs.
class PortfolioSummaryCard extends ConsumerWidget {
  const PortfolioSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final service = ref.watch(dashboardServiceProvider);

    return summaryAsync.when(
      loading: () => _buildShimmer(context),
      error: (e, _) => _buildError(context, e.toString()),
      data: (summary) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroBalanceCard(
                totalLent: summary.totalLent,
                outstanding: summary.outstandingBalance,
                formattedTotal: service.formatCurrencyExact(summary.totalLent),
                formattedOutstanding: service.formatCurrencyExact(
                  summary.outstandingBalance,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              _SecondaryStatsCard(summary: summary, service: service),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.radiusMd,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingLg),
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.radiusMd,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.colors(context).danger),
          SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              'Failed to load summary: $message',
              style: AppTheme.text(context).bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.totalLent,
    required this.outstanding,
    required this.formattedTotal,
    required this.formattedOutstanding,
  });

  final double totalLent;
  final double outstanding;
  final String formattedTotal;
  final String formattedOutstanding;

  @override
  Widget build(BuildContext context) {
    final progress = totalLent > 0
        ? (totalLent - outstanding) / totalLent
        : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // A premium dark glossy gradient.
    final gradientColors = [const Color(0xFF141E30), const Color(0xFF243B55)];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Lent',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedTotal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outstanding',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedOutstanding,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded(
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         'Repaid',
              //         style: TextStyle(
              //           color: Colors.white.withValues(alpha: 0.6),
              //           fontSize: 12,
              //         ),
              //       ),
              //       const SizedBox(height: 4),
              //       Text(
              //         '${(progress * 100).toStringAsFixed(1)}%',
              //         style: const TextStyle(
              //           color: Colors.white,
              //           fontSize: 16,
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.greenAccent,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryStatsCard extends StatelessWidget {
  const _SecondaryStatsCard({required this.summary, required this.service});

  final DashboardSummary summary;
  final DashboardService service;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white10
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              label: 'Interest',
              value: service.formatCompact(summary.monthlyInterestEarned),
              icon: Icons.percent_rounded,
              color: AppTheme.colors(context).accent,
            ),
          ),
          Container(width: 1, height: 40, color: dividerColor),
          Expanded(
            child: _MiniStat(
              label: 'Collection',
              value: '${summary.collectionRate.toStringAsFixed(0)}%',
              icon: Icons.speed_rounded,
              color: AppTheme.colors(context).success,
            ),
          ),
          Container(width: 1, height: 40, color: dividerColor),
          Expanded(
            child: _MiniStat(
              label: 'Loans',
              value: '${summary.totalLoansCount}/${summary.activeLoansCount}',
              icon: Icons.folder_open_rounded,
              color: AppTheme.colors(context).info,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTheme.text(context).valueDisplay.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.text(context).bodySmall,
        ),
      ],
    );
  }
}
