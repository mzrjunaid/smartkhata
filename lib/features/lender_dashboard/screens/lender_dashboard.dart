import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/role_provider.dart';
import '../providers/dashboard_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../widgets/active_loans_card.dart';
import '../../../core/widgets/dashboard_app_bar.dart';
import '../widgets/loan_performance_chart.dart';
import '../widgets/portfolio_summary_card.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/pending_confirmations_card.dart';
import '../widgets/sent_invitations_card.dart';
import '../widgets/pending_disbursements_card.dart';
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
    // Determine if we should show both tabs based on user roles
    final userRolesAsync = ref.watch(userRolesProvider);
    final hasBothRoles =
        userRolesAsync.whenOrNull(
          data: (roles) =>
              (roles['hasLender'] ?? false) && (roles['hasBorrower'] ?? false),
        ) ??
        false;

    final role = ref.watch(roleProvider);

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: role == AppRole.borrower
                ? BorrowerDashboard(hasBothRoles: hasBothRoles)
                : _buildLenderView(context, hasBothRoles),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: DashboardAppBar()),
        ],
      ),
    );
  }

  Widget _buildLenderView(BuildContext context, bool hasBothRoles) {
    return RefreshIndicator(
      color: AppTheme.colors(context).primary,
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        key: const ValueKey('LenderView'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: hasBothRoles ? 190 : 135),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 12), // initial top spacing before first card's 12px vertical margin
            QuickActionsBar(),
            PortfolioSummaryCard(),
            LoanPerformanceChart(),
            SentInvitationsCard(),
            PendingDisbursementsCard(),
            ActiveLoansCard(),
            PendingConfirmationsCard(),
            RecentActivityCard(),
            SizedBox(height: 120),
          ],
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
