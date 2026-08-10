import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the current Supabase client instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Fetches the profile ID of the currently authenticated user.
final currentProfileIdProvider = FutureProvider<String>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;

  if (user == null) {
    throw Exception('User is not authenticated');
  }

  final response = await supabase
      .from('profiles')
      .select('id')
      .eq('auth_user_id', user.id)
      .single();

  return response['id'] as String;
});

/// Fetches the full profile map (id, full_name, role, etc.) for the current user.
final currentProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;

  if (user == null) {
    throw Exception('User is not authenticated');
  }

  final response = await supabase
      .from('profiles')
      .select('id, full_name')
      .eq('auth_user_id', user.id)
      .single();

  return response;
});
