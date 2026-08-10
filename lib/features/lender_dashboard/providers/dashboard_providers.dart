import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/profile_providers.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_summary.dart';
import '../models/loan_activity.dart';
import '../models/monthly_stat.dart';
import '../services/dashboard_service.dart';

/// Provides the singleton [DashboardRepository].
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseClientProvider));
});

/// Provides the singleton [DashboardService].
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.watch(dashboardRepositoryProvider));
});

/// Async provider for portfolio-level KPIs.
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final lenderId = await ref.watch(currentProfileIdProvider.future);
  return ref.watch(dashboardServiceProvider).getSummary(lenderId);
});

/// Async provider for the recent activity feed.
final recentActivityProvider = FutureProvider<List<LoanActivity>>((ref) async {
  final lenderId = await ref.watch(currentProfileIdProvider.future);
  return ref.watch(dashboardServiceProvider).getRecentActivity(lenderId);
});

/// Async provider for monthly chart data.
final monthlyStatsProvider = FutureProvider<List<MonthlyStat>>((ref) async {
  final lenderId = await ref.watch(currentProfileIdProvider.future);
  return ref.watch(dashboardServiceProvider).getMonthlyStats(lenderId);
});

final pendingConfirmationsProvider = FutureProvider<List<LoanActivity>>((ref) async {
  final lenderId = await ref.watch(currentProfileIdProvider.future);
  return ref.watch(dashboardServiceProvider).getPendingConfirmations(lenderId);
});
