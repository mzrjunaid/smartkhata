import 'package:intl/intl.dart';

import '../data/dashboard_repository.dart';
import '../models/dashboard_summary.dart';
import '../models/loan_activity.dart';
import '../models/monthly_stat.dart';

/// Business-logic layer between providers and [DashboardRepository].
///
/// Handles currency formatting, derived metrics, and error wrapping so
/// widgets never deal with raw data or formatting concerns.
class DashboardService {
  DashboardService(this._repository);

  final DashboardRepository _repository;

  // ── Currency formatting ──────────────────────────────────────────────

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_PK',
    symbol: '₨ ',
    decimalDigits: 0,
  );

  static final _compactFormat = NumberFormat.compactCurrency(
    locale: 'en_PK',
    symbol: '₨ ',
    decimalDigits: 1,
  );

  /// Formats [amount] as ₨ 1,250,000.
  String formatCurrency(double amount) => _currencyFormat.format(amount);

  /// Formats [amount] in compact form, e.g. ₨ 1.3M.
  String formatCompact(double amount) => _compactFormat.format(amount);

  // ── Data fetching (delegates to repository) ──────────────────────────

  Future<DashboardSummary> getSummary(String lenderId) => _repository.fetchDashboardSummary(lenderId);

  Future<List<LoanActivity>> getRecentActivity(String lenderId, {int limit = 10}) =>
      _repository.fetchRecentActivity(lenderId, limit: limit);

  Future<List<MonthlyStat>> getMonthlyStats(String lenderId, {int months = 6}) =>
      _repository.fetchMonthlyStats(lenderId, months: months);

  Future<List<LoanActivity>> getPendingConfirmations(String lenderId) =>
      _repository.fetchPendingConfirmations(lenderId);

  // ── Derived metrics ──────────────────────────────────────────────────

  /// Returns a human-readable relative time string.
  /// Handles both past dates (e.g. "2h ago") and future dates (e.g. "12 Oct (in 5 days)").
  String relativeTime(DateTime date) {
    final now = DateTime.now();

    if (date.isAfter(now)) {
      final diff = date.difference(now);
      final formattedDate = DateFormat('dd MMM').format(date);
      if (diff.inDays == 0) return '$formattedDate (Due Today)';
      if (diff.inDays == 1) return '$formattedDate (in 1 day)';
      return '$formattedDate (in ${diff.inDays} days)';
    }

    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(date);
  }
}
