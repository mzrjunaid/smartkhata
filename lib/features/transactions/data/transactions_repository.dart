import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../../../core/providers/role_provider.dart';

class TransactionsRepository {
  TransactionsRepository(this._client);
  final SupabaseClient _client;

  Future<List<TransactionModel>> fetchTransactions(String profileId, AppRole role) async {
    final isLender = role == AppRole.lender;
    
    // 1. Fetch Loans
    final loansResponse = await _client
        .from('loans')
        .select('''
          id, principal_amount, created_at, status, note,
          connections!inner(
            lender_profile_id,
            borrower_profile_id,
            lender:profiles!connections_lender_profile_id_fkey(full_name),
            borrower:profiles!connections_borrower_profile_id_fkey(full_name)
          )
        ''')
        .eq(isLender ? 'connections.lender_profile_id' : 'connections.borrower_profile_id', profileId);

    // 2. Fetch Repayments
    final repsResponse = await _client
        .from('repayments')
        .select('''
          id, amount, created_at, status, note, due_date, paid_date,
          confirmed_by_profile:profiles!repayments_confirmed_by_fkey(full_name),
          loans!inner(
            connections!inner(
              lender_profile_id,
              borrower_profile_id,
              lender:profiles!connections_lender_profile_id_fkey(full_name),
              borrower:profiles!connections_borrower_profile_id_fkey(full_name)
            )
          )
        ''')
        .eq(isLender ? 'loans.connections.lender_profile_id' : 'loans.connections.borrower_profile_id', profileId)
        .not('paid_date', 'is', null);

    final transactions = <TransactionModel>[];
    
    for (final loan in (loansResponse as List)) {
      final conn = loan['connections'] as Map<String, dynamic>;
      final lender = conn['lender'] as Map<String, dynamic>?;
      final borrower = conn['borrower'] as Map<String, dynamic>?;
      final status = loan['status'] as String? ?? 'active';
      
      final counterpartyName = isLender 
          ? (borrower?['full_name'] as String? ?? 'Unknown') 
          : (lender?['full_name'] as String? ?? 'Unknown');
      
      String category = 'Loan';
      switch (status) {
        case 'draft':
          category = 'Draft Loan';
          break;
        case 'pending_disbursement':
          category = 'Pending Disbursement';
          break;
        case 'active':
          category = 'Loan Disbursed';
          break;
        case 'completed':
          category = 'Loan Completed';
          break;
        case 'cancelled':
          category = 'Loan Cancelled';
          break;
        case 'defaulted':
          category = 'Loan Defaulted';
          break;
        case 'overdue':
          category = 'Loan Overdue';
          break;
      }

      transactions.add(TransactionModel(
        id: 'loan_${loan['id']}',
        amount: (loan['principal_amount'] as num).toDouble(),
        date: DateTime.parse(loan['created_at'] as String),
        counterpartyName: counterpartyName,
        direction: isLender ? TransactionDirection.moneyOut : TransactionDirection.moneyIn,
        category: category,
        status: status,
        notes: loan['note'] as String?,
      ));
    }
    
    for (final rep in (repsResponse as List)) {
      final loan = rep['loans'] as Map<String, dynamic>;
      final conn = loan['connections'] as Map<String, dynamic>;
      final lender = conn['lender'] as Map<String, dynamic>?;
      final borrower = conn['borrower'] as Map<String, dynamic>?;
      
      final status = rep['status'] as String? ?? 'confirmed';
      final counterpartyName = isLender 
          ? (borrower?['full_name'] as String? ?? 'Unknown') 
          : (lender?['full_name'] as String? ?? 'Unknown');
      
      final confirmedByProfile = rep['confirmed_by_profile'] as Map<String, dynamic>?;
      
      transactions.add(TransactionModel(
        id: 'rep_${rep['id']}',
        amount: (rep['amount'] as num).toDouble(),
        date: DateTime.parse(rep['created_at'] as String),
        counterpartyName: counterpartyName,
        direction: isLender ? TransactionDirection.moneyIn : TransactionDirection.moneyOut,
        category: 'Repayment',
        status: status,
        notes: rep['note'] as String?,
        dueDate: rep['due_date'] != null ? DateTime.parse(rep['due_date'] as String) : null,
        paidDate: rep['paid_date'] != null ? DateTime.parse(rep['paid_date'] as String) : null,
        confirmedBy: confirmedByProfile?['full_name'] as String?,
      ));
    }
    
    // Sort transactions by date descending
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }
}
