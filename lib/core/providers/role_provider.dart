import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_providers.dart';

/// The two contextual roles a user can view the app as.
enum AppRole { lender, borrower }

class RoleNotifier extends Notifier<AppRole> {
  @override
  AppRole build() => AppRole.lender;

  void setRole(AppRole role) {
    state = role;
  }
}

/// Global state for the currently active role view.
/// Defaults to [AppRole.lender].
final roleProvider = NotifierProvider<RoleNotifier, AppRole>(RoleNotifier.new);

/// Checks if the current user has lender and/or borrower connections.
/// Also auto-corrects the default role if they only have one type.
final userRolesProvider = FutureProvider<Map<String, bool>>((ref) async {
  final String profileId = await ref.watch(currentProfileIdProvider.future);
  final client = Supabase.instance.client;

  final lenderRes = await client
      .from('connections')
      .select('id')
      .eq('lender_profile_id', profileId)
      .limit(1);

  final borrowerRes = await client
      .from('connections')
      .select('id')
      .eq('borrower_profile_id', profileId)
      .limit(1);

  final hasLender = (lenderRes as List).isNotEmpty;
  final hasBorrower = (borrowerRes as List).isNotEmpty;

  // Auto-switch role if they only have borrower connections
  if (hasBorrower && !hasLender) {
    Future.microtask(() {
      if (ref.read(roleProvider) != AppRole.borrower) {
        ref.read(roleProvider.notifier).setRole(AppRole.borrower);
      }
    });
  } else if (hasLender && !hasBorrower) {
    Future.microtask(() {
      if (ref.read(roleProvider) != AppRole.lender) {
        ref.read(roleProvider.notifier).setRole(AppRole.lender);
      }
    });
  }

  return {
    'hasLender': hasLender,
    'hasBorrower': hasBorrower,
  };
});


