import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_summary.dart';
import '../models/loan_activity.dart';
import '../models/monthly_stat.dart';

/// Data source for the lender dashboard.
class DashboardRepository {
  DashboardRepository(this._client);

  final SupabaseClient _client;

  /// Fetches the lender's portfolio KPIs.
  Future<DashboardSummary> fetchDashboardSummary(String lenderId) async {
    // 1. Fetch loans connected to this lender
    final loansResponse = await _client
        .from('loans')
        .select('''
          id, principal_amount, status,
          connections!inner(lender_profile_id)
        ''')
        .eq('connections.lender_profile_id', lenderId);
        
    final loans = loansResponse as List;
    
    double totalLent = 0;
    int activeLoansCount = 0;
    int overdueCount = 0;
    
    final loanIds = <String>[];

    for (final loan in loans) {
      final status = loan['status'] as String;
      if (status == 'active' || status == 'completed' || status == 'overdue') {
        totalLent += (loan['principal_amount'] as num).toDouble();
      }
      if (status == 'active') activeLoansCount++;
      if (status == 'overdue') overdueCount++;
      loanIds.add(loan['id'] as String);
    }

    // 2. Fetch repayments for those loans
    double totalReceived = 0;
    double monthlyInterestEarned = 0; // Simplified for now
    
    if (loanIds.isNotEmpty) {
      final repaymentsResponse = await _client
          .from('repayments')
          .select('amount, status, paid_date')
          .inFilter('loan_id', loanIds)
          .eq('status', 'confirmed');
          
      final repayments = repaymentsResponse as List;
      for (final rep in repayments) {
        totalReceived += (rep['amount'] as num).toDouble();
        
        // Simple monthly interest approximation: 10% of this month's payments
        // A real app would calculate the interest portion of each EMI.
        final paidDateStr = rep['paid_date'] as String?;
        if (paidDateStr != null) {
          final paidDate = DateTime.tryParse(paidDateStr);
          if (paidDate != null && paidDate.month == DateTime.now().month && paidDate.year == DateTime.now().year) {
             monthlyInterestEarned += (rep['amount'] as num).toDouble() * 0.10;
          }
        }
      }
    }

    final outstandingBalance = totalLent - totalReceived;

    return DashboardSummary(
      totalLent: totalLent,
      totalReceived: totalReceived,
      outstandingBalance: outstandingBalance > 0 ? outstandingBalance : 0,
      activeLoansCount: activeLoansCount,
      overdueCount: overdueCount,
      monthlyInterestEarned: monthlyInterestEarned,
    );
  }

  /// Fetches the most recent activity items.
  Future<List<LoanActivity>> fetchRecentActivity(String lenderId, {int limit = 10}) async {
    // A real unified activity feed would likely use a DB view or RPC.
    // Here we fetch recent loans and recent repayments separately and combine them.
    
    // Upcoming repayments (limited to next 30 days)
    final oneMonthFromNow = DateTime.now().add(const Duration(days: 30));
    final repsResponse = await _client
        .from('repayments')
        .select('''
          id, amount, due_date, created_at, status,
          loans!inner(
            connections!inner(
              lender_profile_id,
              profiles!connections_borrower_profile_id_fkey(full_name)
            )
          )
        ''')
        .eq('loans.connections.lender_profile_id', lenderId)
        .inFilter('status', ['pending', 'missed'])
        .not('due_date', 'is', null)
        .lte('due_date', oneMonthFromNow.toIso8601String())
        .order('due_date', ascending: true)
        .limit(limit);

    final activities = <LoanActivity>[];
    for (final rep in (repsResponse as List)) {
      final loan = rep['loans'] as Map<String, dynamic>;
      final conn = loan['connections'] as Map<String, dynamic>;
      final profile = conn['profiles'] as Map<String, dynamic>;
      
      final status = rep['status'] as String? ?? 'confirmed';
      ActivityType repType;
      switch (status) {
        case 'pending':
          repType = ActivityType.repaymentPending;
          break;
        case 'rejected':
          repType = ActivityType.repaymentRejected;
          break;
        case 'missed':
          repType = ActivityType.repaymentMissed;
          break;
        case 'confirmed':
        default:
          repType = ActivityType.repaymentConfirmed;
      }
      
      activities.add(LoanActivity(
        id: 'rep_${rep['id']}',
        borrowerName: profile['full_name'] as String? ?? 'Unknown',
        type: repType,
        amount: (rep['amount'] as num).toDouble(),
        date: DateTime.parse(rep['due_date'] as String),
      ));
    }
    
    return activities;
  }

  /// Fetches monthly disbursement vs collection stats for charts.
  Future<List<MonthlyStat>> fetchMonthlyStats(String lenderId, {int months = 6}) async {
    final now = DateTime.now();
    final statsMap = <String, MonthlyStat>{};
    
    for (int i = months - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('yyyy-MM').format(d);
      final label = DateFormat('MMM').format(d);
      statsMap[key] = MonthlyStat(month: label, disbursed: 0, collected: 0);
    }
    
    try {
      // Step 1: Get all loan IDs for this lender
      final loansResponse = await _client
          .from('loans')
          .select('''
            id, principal_amount, created_at, status,
            connections!inner(lender_profile_id)
          ''')
          .eq('connections.lender_profile_id', lenderId);
          
      final loanIds = <String>[];
      
      for (final loan in (loansResponse as List)) {
        loanIds.add(loan['id'] as String);
        
        // Disbursements: only count loans created within the time range
        final status = loan['status'] as String;
        if (status != 'draft' && status != 'rejected') {
          final createdAtStr = loan['created_at'] as String?;
          if (createdAtStr != null) {
            final createdAt = DateTime.parse(createdAtStr);
            final key = DateFormat('yyyy-MM').format(createdAt);
            if (statsMap.containsKey(key)) {
              final existing = statsMap[key]!;
              statsMap[key] = MonthlyStat(
                month: existing.month,
                disbursed: existing.disbursed + (loan['principal_amount'] as num).toDouble(),
                collected: existing.collected,
              );
            }
          }
        }
      }

      // Step 2: Get confirmed repayments for those loans
      if (loanIds.isNotEmpty) {
        final repsResponse = await _client
            .from('repayments')
            .select('amount, paid_date, status, loan_id')
            .inFilter('loan_id', loanIds);
        
        // Filter for confirmed only
        final confirmedReps = (repsResponse as List).where((rep) {
          final s = rep['status'] as String;
          return s == 'confirmed';
        }).toList();
            
        for (final rep in confirmedReps) {
          final paidDateStr = rep['paid_date'] as String?;
          if (paidDateStr != null) {
            final paidDate = DateTime.parse(paidDateStr);
            final key = DateFormat('yyyy-MM').format(paidDate);
            if (statsMap.containsKey(key)) {
              final existing = statsMap[key]!;
              statsMap[key] = MonthlyStat(
                month: existing.month,
                disbursed: existing.disbursed,
                collected: existing.collected + (rep['amount'] as num).toDouble(),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching monthly stats: $e');
    }

    return statsMap.values.toList();
  }

  /// Fetches payments submitted by borrowers that are awaiting lender confirmation.
  Future<List<LoanActivity>> fetchPendingConfirmations(String lenderId) async {
    final repsResponse = await _client
        .from('repayments')
        .select('''
          id, amount, due_date, paid_date, created_at, status,
          loans!inner(
            connections!inner(
              lender_profile_id,
              profiles!connections_borrower_profile_id_fkey(full_name)
            )
          )
        ''')
        .eq('loans.connections.lender_profile_id', lenderId)
        .eq('status', 'pending')
        .not('paid_date', 'is', null)
        .order('paid_date', ascending: false);

    final activities = <LoanActivity>[];
    for (final rep in (repsResponse as List)) {
      final loan = rep['loans'] as Map<String, dynamic>;
      final conn = loan['connections'] as Map<String, dynamic>;
      final profile = conn['profiles'] as Map<String, dynamic>;
      
      activities.add(LoanActivity(
        id: 'rep_${rep['id']}',
        borrowerName: profile['full_name'] as String? ?? 'Unknown',
        type: ActivityType.repaymentPending,
        amount: (rep['amount'] as num).toDouble(),
        date: DateTime.parse(rep['paid_date'] as String), // Sort by paid date
      ));
    }
    
    return activities;
  }
}
