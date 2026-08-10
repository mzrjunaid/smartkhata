import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/profile_providers.dart';
import '../data/new_loan_repository.dart';
import '../models/connection_model.dart';
import '../services/new_loan_service.dart';

/// Provides the singleton [NewLoanRepository].
final newLoanRepositoryProvider = Provider<NewLoanRepository>((ref) {
  return NewLoanRepository(ref.watch(supabaseClientProvider));
});

/// Provides the singleton [NewLoanService].
final newLoanServiceProvider = Provider<NewLoanService>((ref) {
  return NewLoanService(ref.watch(newLoanRepositoryProvider));
});

/// Fetches active connections for the current lender.
final lenderConnectionsProvider = FutureProvider<List<ConnectionModel>>((ref) async {
  final lenderId = await ref.watch(currentProfileIdProvider.future);
  return ref.watch(newLoanRepositoryProvider).fetchLenderConnections(lenderId);
});
