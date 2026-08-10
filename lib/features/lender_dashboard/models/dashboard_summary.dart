/// Holds portfolio-level KPI data for the lender dashboard.
///
/// Intentionally kept as a plain immutable class (no freezed) to avoid
/// code-gen overhead for a read-only view model.
class DashboardSummary {
  const DashboardSummary({
    required this.totalLent,
    required this.totalReceived,
    required this.outstandingBalance,
    required this.activeLoansCount,
    required this.overdueCount,
    required this.monthlyInterestEarned,
  });

  final double totalLent;
  final double totalReceived;
  final double outstandingBalance;
  final int activeLoansCount;
  final int overdueCount;
  final double monthlyInterestEarned;

  /// Percentage of total lent that has been collected back.
  double get collectionRate =>
      totalLent > 0 ? (totalReceived / totalLent) * 100 : 0;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalLent: (json['total_lent'] as num).toDouble(),
      totalReceived: (json['total_received'] as num).toDouble(),
      outstandingBalance: (json['outstanding_balance'] as num).toDouble(),
      activeLoansCount: json['active_loans_count'] as int,
      overdueCount: json['overdue_count'] as int,
      monthlyInterestEarned:
          (json['monthly_interest_earned'] as num).toDouble(),
    );
  }
}
