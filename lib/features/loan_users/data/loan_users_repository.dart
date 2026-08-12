import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../new_loan/models/connection_model.dart';
import '../../../core/providers/profile_providers.dart';

import '../models/repayment_model.dart';
import '../models/credit_score_model.dart';
import '../models/borrower_connection_model.dart';
import '../models/top_lender_model.dart';

final loanUsersRepositoryProvider = Provider<LoanUsersRepository>((ref) {
  return LoanUsersRepository(Supabase.instance.client);
});

class LoanUsersRepository {
  LoanUsersRepository(this._client);
  final SupabaseClient _client;

  /// Returns the profile ID for the currently authenticated user.
  Future<String> _currentProfileId() async {
    final authUserId = _client.auth.currentUser!.id;
    final row = await _client
        .from('profiles')
        .select('id')
        .eq('auth_user_id', authUserId)
        .single();
    return row['id'] as String;
  }

  Future<List<ConnectionModel>> fetchActiveConnections(String lenderId) async {
    // 1. Fetch active and pending connections
    final connectionsResponse = await _client
        .from('connections')
        .select('''
          id,
          borrower_profile_id,
          status,
          lender_verified_at,
          profiles!connections_borrower_profile_id_fkey (
            full_name,
            cnic,
            phone,
            email,
            claim_status
          ),
          loans ( * )
        ''')
        .eq('lender_profile_id', lenderId)
        .inFilter('status', ['active', 'pending']);

    // 2. Fetch pending invitations
    final invitationsResponse = await _client
        .from('invitations')
        .select('''
          id,
          profile_id,
          status,
          profiles!invitations_profile_id_fkey (
            full_name,
            cnic,
            phone,
            email,
            claim_status
          )
        ''')
        .eq('invited_by', lenderId)
        .eq('status', 'pending');

    final activeConnections = (connectionsResponse as List).map<ConnectionModel>((json) {
      return ConnectionModel.fromJson(json as Map<String, dynamic>);
    }).toList();

    final pendingInvitationsList = invitationsResponse as List;
    final pendingBorrowerIds = pendingInvitationsList
        .map((inv) => inv['profile_id'] as String?)
        .where((id) => id != null)
        .toSet();

    // 3. If an active connection has a pending invitation, override its status to 'pending'
    for (int i = 0; i < activeConnections.length; i++) {
      final conn = activeConnections[i];
      if (conn.borrowerProfileId != null && pendingBorrowerIds.contains(conn.borrowerProfileId)) {
        activeConnections[i] = ConnectionModel(
          id: conn.id,
          borrowerProfileId: conn.borrowerProfileId,
          status: 'pending', // OVERRIDE
          borrowerName: conn.borrowerName,
          borrowerCnic: conn.borrowerCnic,
          borrowerPhone: conn.borrowerPhone,
          borrowerEmail: conn.borrowerEmail,
          claimStatus: conn.claimStatus,
          lenderVerifiedAt: conn.lenderVerifiedAt,
          loans: conn.loans,
        );
      }
    }

    // 4. Map pure pending invitations (those WITHOUT an existing connection)
    final existingConnectionBorrowerIds = activeConnections
        .map((c) => c.borrowerProfileId)
        .where((id) => id != null)
        .toSet();

    final purePendingInvitations = pendingInvitationsList
        .where((inv) {
          final profileId = inv['profile_id'] as String?;
          return profileId == null || !existingConnectionBorrowerIds.contains(profileId);
        })
        .map<ConnectionModel>((json) {
      final profile = json['profiles'] as Map<String, dynamic>?;
      return ConnectionModel(
        id: json['id'] as String,
        borrowerProfileId: json['profile_id'] as String?,
        borrowerName: profile?['full_name'] as String? ?? 'Unknown',
        borrowerCnic: profile?['cnic'] as String? ?? 'Unknown',
        borrowerPhone: profile?['phone'] as String?,
        borrowerEmail: profile?['email'] as String?,
        status: 'pending',
        claimStatus: profile?['claim_status'] as String? ?? 'invited',
        lenderVerifiedAt: null,
        loans: const [],
      );
    }).toList();

    return [...activeConnections, ...purePendingInvitations];
  }

  /// Fetches connections where the given profile is the **borrower**.
  Future<List<BorrowerConnectionModel>> fetchBorrowerConnections(String borrowerId) async {
    final response = await _client
        .from('connections')
        .select('''
          id,
          status,
          lender_profile_id,
          profiles!connections_lender_profile_id_fkey (
            full_name,
            phone,
            email
          ),
          loans ( * )
        ''')
        .eq('borrower_profile_id', borrowerId)
        .inFilter('status', ['active', 'pending']);



    // 2. Fetch pending invitations where this borrower is the invited user
    final invitationsResponse = await _client
        .from('invitations')
        .select('''
          id,
          status,
          invited_by,
          profiles!invitations_invited_by_fkey (
            full_name,
            phone,
            email
          )
        ''')
        .eq('profile_id', borrowerId)
        .eq('status', 'pending');

    final pendingInvitationLenderIds = (invitationsResponse as List)
        .map((inv) => inv['invited_by'] as String?)
        .where((id) => id != null)
        .toSet();

    // Map active/pending connections and set hasPendingInvitation flag
    final activeAndPendingConnections = (response as List).map<BorrowerConnectionModel>((json) {
      final hasInv = pendingInvitationLenderIds.contains(json['lender_profile_id'] as String?);
      final jsonWithInv = Map<String, dynamic>.from(json as Map<String, dynamic>);
      jsonWithInv['hasPendingInvitation'] = hasInv;
      return BorrowerConnectionModel.fromJson(jsonWithInv);
    }).toList();

    final purePendingInvitations = (invitationsResponse as List).map<BorrowerConnectionModel>((json) {
      final lenderProfile = json['profiles'] as Map<String, dynamic>?;
      final jsonWithInv = Map<String, dynamic>.from(json as Map<String, dynamic>);
      jsonWithInv['hasPendingInvitation'] = true;
      return BorrowerConnectionModel.fromJson(jsonWithInv);
    }).toList();

    // Combine them. Exclude pure invitations if a connection already exists for that lender
    final existingLenderIds = activeAndPendingConnections
        .map((c) => c.lenderProfileId)
        .where((id) => id != null)
        .toSet();

    final uniqueInvitations = purePendingInvitations
        .where((inv) => !existingLenderIds.contains(inv.lenderProfileId))
        .toList();

    return [...activeAndPendingConnections, ...uniqueInvitations];
  }

  Future<ConnectionModel> fetchConnectionDetails(String connectionId) async {
    final response = await _client
        .from('connections')
        .select('''
          id,
          borrower_profile_id,
          status,
          lender_verified_at,
          profiles!connections_borrower_profile_id_fkey (
            full_name,
            cnic,
            phone,
            email,
            claim_status
          ),
          lender:profiles!connections_lender_profile_id_fkey (
            full_name,
            phone,
            email
          ),
          loans ( * )
        ''')
        .eq('id', connectionId)
        .single();

    return ConnectionModel.fromJson(response);
  }

  Future<void> updateConnectionStatus(String connectionId, String status) async {
    await _client.from('connections').update({'status': status}).eq('id', connectionId);
  }

  Future<void> updateLoanStatus(String loanId, String status) async {
    await _client.rpc('lender_update_loan_status', params: {
      'p_loan_id': loanId,
      'p_status': status,
    });
  }

  Future<void> acceptLoan(String loanId) async {
    await _client.rpc('accept_loan', params: {
      'p_loan_id': loanId,
    });
  }

  Future<void> acceptConnectionInvitation(String lenderProfileId) async {
    await _client.rpc('accept_connection_invitation', params: {
      'p_lender_profile_id': lenderProfileId,
    });
  }

  Future<void> verifyConnection(String connectionId) async {
    await _client.rpc('verify_connection', params: {
      'p_connection_id': connectionId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchConnectionRepayments(String connectionId) async {
    final response = await _client
        .from('repayments')
        .select('''
          id, loan_id, amount, status, method, note, paid_date, due_date, created_at,
          loans!inner(connection_id)
        ''')
        .eq('loans.connection_id', connectionId)
        .order('due_date', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<void> updateRepaymentSchedule(String repaymentId, DateTime newDueDate, double newAmount) async {
    await _client.from('repayments').update({
      'due_date': newDueDate.toIso8601String(),
      'amount': newAmount,
    }).eq('id', repaymentId);
  }

  Future<void> deleteRepayment(String repaymentId) async {
    await _client.from('repayments').delete().eq('id', repaymentId);
  }

  Future<void> addScheduledRepayment(String loanId, DateTime dueDate, double amount) async {
    final profileId = await _currentProfileId();
    await _client.from('repayments').insert({
      'loan_id': loanId,
      'amount': amount,
      'status': 'pending',
      'due_date': dueDate.toIso8601String(),
      'recorded_by': profileId,
    });
  }

  Future<void> generateMonthlySchedule(String loanId, double totalAmount, DateTime startDate, int months) async {
    if (months <= 0) return;

    final profileId = await _currentProfileId();
    final double monthlyAmount = totalAmount / months;
    final List<Map<String, dynamic>> batch = [];

    for (int i = 1; i <= months; i++) {
      // Calculate next due date by adding 'i' months to start date
      final nextDueDate = DateTime(startDate.year, startDate.month + i, startDate.day);
      
      batch.add({
        'loan_id': loanId,
        'amount': double.parse(monthlyAmount.toStringAsFixed(2)),
        'status': 'pending',
        'due_date': nextDueDate.toIso8601String(),
        'recorded_by': profileId,
      });
    }

    await _client.from('repayments').insert(batch);
  }

  Future<Map<String, dynamic>?> fetchCreditScore(String borrowerProfileId) async {
    final response = await _client
        .from('credit_scores')
        .select()
        .eq('profile_id', borrowerProfileId)
        .maybeSingle();
        
    return response;
  }

  Future<RepaymentModel> fetchRepaymentById(String repaymentId) async {
    final response = await _client
        .from('repayments')
        .select('*')
        .eq('id', repaymentId)
        .single();
    
    return RepaymentModel.fromJson(response);
  }

  Future<void> updateRepayment(String repaymentId, Map<String, dynamic> data) async {
    await _client
        .from('repayments')
        .update(data)
        .eq('id', repaymentId);
  }

  Future<List<TopLenderModel>> fetchTopLenders() async {
    final response = await _client.rpc('get_top_lenders');
    return (response as List).map((json) => TopLenderModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}

final activeConnectionsProvider = FutureProvider<List<ConnectionModel>>((ref) async {
  final String currentProfileId = await ref.watch(currentProfileIdProvider.future);
  final repo = ref.watch(loanUsersRepositoryProvider);
  return repo.fetchActiveConnections(currentProfileId);
});

/// Connections where the current user is the **borrower**.
final borrowerConnectionsProvider = FutureProvider<List<BorrowerConnectionModel>>((ref) async {
  final String currentProfileId = await ref.watch(currentProfileIdProvider.future);
  final repo = ref.watch(loanUsersRepositoryProvider);
  return repo.fetchBorrowerConnections(currentProfileId);
});

final connectionDetailsProvider = FutureProvider.family<ConnectionModel, String>((ref, connectionId) async {
  final repo = ref.watch(loanUsersRepositoryProvider);
  return repo.fetchConnectionDetails(connectionId);
});

final connectionRepaymentsProvider = FutureProvider.family<List<RepaymentModel>, String>((ref, connectionId) async {
  final repo = ref.watch(loanUsersRepositoryProvider);
  final data = await repo.fetchConnectionRepayments(connectionId);
  return data.map((json) => RepaymentModel.fromJson(json)).toList();
});

final borrowerCreditScoreProvider = FutureProvider.family<CreditScoreModel?, String>((ref, borrowerProfileId) async {
  final repo = ref.watch(loanUsersRepositoryProvider);
  final data = await repo.fetchCreditScore(borrowerProfileId);
  if (data == null) return null;
  return CreditScoreModel.fromJson(data);
});

final repaymentDetailsProvider = FutureProvider.family<RepaymentModel, String>((ref, repaymentId) async {
  final repo = ref.watch(loanUsersRepositoryProvider);
  return repo.fetchRepaymentById(repaymentId);
});

final topLendersProvider = FutureProvider<List<TopLenderModel>>((ref) async {
  final repo = ref.watch(loanUsersRepositoryProvider);
  return repo.fetchTopLenders();
});

