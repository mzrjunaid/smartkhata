import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String cnic,
    String? phone,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'cnic': cnic,
        ...?phone != null ? {'phone': phone} : null,
      },
    );
  }

  /// Verifies if a given CNIC has an invited invitation.
  /// Returns a map with the pre-filled profile data if found, or null if not.
  Future<Map<String, dynamic>?> verifyInvitation(String cnic) async {
    final response = await _client.rpc('verify_cnic_invitation', params: {
      'p_cnic': cnic,
    });
    return response as Map<String, dynamic>?;
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();
}
