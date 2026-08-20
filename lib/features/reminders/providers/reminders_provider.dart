import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/profile_providers.dart';
import '../models/reminder_item.dart';

/// Fetches all pending (due within 30 days), rejected, and missed repayments
/// for the current lender, including borrower contact details.
final lenderRemindersProvider = FutureProvider<Map<String, List<ReminderItem>>>((ref) async {
  final client = Supabase.instance.client;
  final lenderId = await ref.watch(currentProfileIdProvider.future);

  final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));

  // Fetch pending repayments due within 30 days
  final pendingResponse = await client
      .from('repayments')
      .select('''
        id, loan_id, amount, due_date, status,
        loans!inner(
          connections!inner(
            lender_profile_id,
            profiles!connections_borrower_profile_id_fkey(full_name, phone)
          )
        )
      ''')
      .eq('loans.connections.lender_profile_id', lenderId)
      .eq('status', 'pending')
      .not('due_date', 'is', null)
      .lte('due_date', thirtyDaysFromNow.toIso8601String())
      .order('due_date', ascending: true);

  // Fetch rejected repayments
  final rejectedResponse = await client
      .from('repayments')
      .select('''
        id, loan_id, amount, due_date, status,
        loans!inner(
          connections!inner(
            lender_profile_id,
            profiles!connections_borrower_profile_id_fkey(full_name, phone)
          )
        )
      ''')
      .eq('loans.connections.lender_profile_id', lenderId)
      .eq('status', 'rejected')
      .order('due_date', ascending: true);

  // Fetch missed repayments
  final missedResponse = await client
      .from('repayments')
      .select('''
        id, loan_id, amount, due_date, status,
        loans!inner(
          connections!inner(
            lender_profile_id,
            profiles!connections_borrower_profile_id_fkey(full_name, phone)
          )
        )
      ''')
      .eq('loans.connections.lender_profile_id', lenderId)
      .eq('status', 'missed')
      .order('due_date', ascending: true);

  List<ReminderItem> _parse(List<dynamic> rows) {
    return rows.map<ReminderItem>((rep) {
      final loan = rep['loans'] as Map<String, dynamic>;
      final conn = loan['connections'] as Map<String, dynamic>;
      final profile = conn['profiles'] as Map<String, dynamic>;

      return ReminderItem(
        repaymentId: rep['id'] as String,
        loanId: rep['loan_id'] as String,
        borrowerName: profile['full_name'] as String? ?? 'Unknown',
        borrowerPhone: profile['phone'] as String?,
        amount: (rep['amount'] as num).toDouble(),
        dueDate: rep['due_date'] != null
            ? DateTime.tryParse(rep['due_date'] as String)
            : null,
        status: rep['status'] as String,
      );
    }).toList();
  }

  return {
    'pending': _parse(pendingResponse as List),
    'rejected': _parse(rejectedResponse as List),
    'missed': _parse(missedResponse as List),
  };
});
