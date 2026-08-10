import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/role_provider.dart';
import '../providers/dashboard_providers.dart';
import '../theme/dashboard_theme.dart';
import '../widgets/active_loans_card.dart';
import '../../../core/widgets/dashboard_app_bar.dart';
import '../widgets/loan_performance_chart.dart';
import '../widgets/portfolio_summary_card.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/pending_confirmations_card.dart';
import '../../borrower_dashboard/screens/borrower_dashboard.dart';

/// Main home screen — switches between Lender and Borrower dashboard
/// based on the global [roleProvider].
class LenderDashboard extends ConsumerStatefulWidget {
  const LenderDashboard({super.key, required this.title});

  final String title;

  @override
  ConsumerState<LenderDashboard> createState() => _LenderDashboardState();
}

class _LenderDashboardState extends ConsumerState<LenderDashboard> {
  @override
  Widget build(BuildContext context) {
    final role = ref.watch(roleProvider);

    if (role == AppRole.borrower) {
      return const BorrowerDashboard();
    }

    return Scaffold(
      backgroundColor: DashboardTheme.surface,
      body: RefreshIndicator(
        color: DashboardTheme.primary,
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // ── App bar with greeting ──────────────────────────────
              DashboardAppBar(),

              SizedBox(height: DashboardTheme.spacingLg),

              // ── Quick action chips ────────────────────────────────
              QuickActionsBar(),

              SizedBox(height: DashboardTheme.spacingXl),

              // ── Portfolio KPI grid ────────────────────────────────
              PortfolioSummaryCard(),

              SizedBox(height: DashboardTheme.spacingXl),

              // ── Monthly performance chart ─────────────────────────
              LoanPerformanceChart(),

              SizedBox(height: DashboardTheme.spacingXl),

              // ── Active loans list ─────────────────────────────────
              ActiveLoansCard(),

              SizedBox(height: DashboardTheme.spacingXl),

              // ── Pending Confirmations ─────────────────────────────
              PendingConfirmationsCard(),

              // ── Recent activity feed ──────────────────────────────
              RecentActivityCard(),

              // Bottom padding for comfortable scrolling (behind nav bar)
              SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  /// Pull-to-refresh: invalidates all providers so widgets reload.
  Future<void> _refreshDashboard() async {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(recentActivityProvider);
    ref.invalidate(monthlyStatsProvider);

    // Wait for all providers to complete before hiding the indicator.
    await Future.wait([
      ref.read(dashboardSummaryProvider.future),
      ref.read(recentActivityProvider.future),
      ref.read(monthlyStatsProvider.future),
    ]);
  }
}
