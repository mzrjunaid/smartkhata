import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/connection_model.dart';
import '../models/new_loan_form_data.dart';

/// Data source for creating new loans and managing connections.
class NewLoanRepository {
  NewLoanRepository(this._client);

  final SupabaseClient _client;

  /// Fetches active connections where the given profile is the lender.
  Future<List<ConnectionModel>> fetchLenderConnections(String lenderId) async {
    final response = await _client
        .from('connections')
        .select('''
          id,
          status,
          profiles!connections_borrower_profile_id_fkey (
            full_name,
            cnic,
            phone
          )
        ''')
        .eq('lender_profile_id', lenderId)
        .eq('status', 'active');

    return (response as List).map((json) {
      return ConnectionModel.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  /// Invites a new borrower (or reuses profile by CNIC) and creates a connection.
  /// Returns the new connection ID.
  Future<String> inviteBorrower({
    required String fullName,
    required String cnic,
    String? phone,
    String? nickname,
  }) async {
    final response = await _client.rpc('invite_borrower', params: {
      'p_full_name': fullName,
      'p_cnic': cnic,
      'p_phone': phone,
      'p_nickname': nickname,
    });
    return response as String;
  }

  /// Inserts a new loan record via RPC and returns the generated loan ID.
  Future<String> createLoan(NewLoanFormData data) async {
    final response = await _client.rpc('create_loan', params: {
      'p_connection_id': data.connectionId,
      'p_principal': data.principalAmount,
      'p_currency': data.currencyCode,
      'p_interest_rate': data.interestRate,
      'p_interest_type': data.interestType,
      if (data.disbursedAt != null) 'p_disbursed_at': data.disbursedAt!.toIso8601String(),
      if (data.dueDate != null) 'p_due_date': data.dueDate!.toIso8601String(),
      if (data.notes != null) 'p_note': data.notes,
    });
    return response as String;
  }
}
