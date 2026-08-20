import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/profile_providers.dart';
import '../../../core/providers/role_provider.dart';
import '../models/transaction_model.dart';
import '../data/transactions_repository.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(Supabase.instance.client);
});

enum TransactionFilterType { all, moneyIn, moneyOut, pending }

class DateRange {
  final DateTime? start;
  final DateTime? end;
  DateRange(this.start, this.end);
  
  bool get hasFilter => start != null || end != null;
}

// State for filtering
class TransactionFilterNotifier extends Notifier<TransactionFilterType> {
  @override
  TransactionFilterType build() => TransactionFilterType.all;
  void setFilter(TransactionFilterType filter) => state = filter;
}

final transactionFilterTypeProvider = NotifierProvider<TransactionFilterNotifier, TransactionFilterType>(TransactionFilterNotifier.new);

class TransactionDateRangeNotifier extends Notifier<DateRange> {
  @override
  DateRange build() => DateRange(null, null);
  void setDateRange(DateTime? start, DateTime? end) => state = DateRange(start, end);
  void clear() => state = DateRange(null, null);
}

final transactionDateRangeProvider = NotifierProvider<TransactionDateRangeNotifier, DateRange>(TransactionDateRangeNotifier.new);


final allTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final profileId = await ref.watch(currentProfileIdProvider.future);
  final role = ref.watch(roleProvider);
  return ref.read(transactionsRepositoryProvider).fetchTransactions(profileId, role);
});

final filteredTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final asyncTx = ref.watch(allTransactionsProvider);
  
  return asyncTx.whenData((transactions) {
    final filterType = ref.watch(transactionFilterTypeProvider);
    final dateRange = ref.watch(transactionDateRangeProvider);
    
    var filtered = transactions;
    
    // 1. Filter by Type
    switch (filterType) {
      case TransactionFilterType.moneyIn:
        filtered = filtered.where((t) => t.direction == TransactionDirection.moneyIn).toList();
        break;
      case TransactionFilterType.moneyOut:
        filtered = filtered.where((t) => t.direction == TransactionDirection.moneyOut).toList();
        break;
      case TransactionFilterType.pending:
        filtered = filtered.where((t) {
          return t.status == 'pending' || t.status == 'pending_confirmation';
        }).toList();
        break;
      case TransactionFilterType.all:
        break;
    }
    
    // 2. Filter by Date Range
    if (dateRange.start != null) {
      // isAfter needs to be inclusive of the day
      final startDay = DateTime(dateRange.start!.year, dateRange.start!.month, dateRange.start!.day);
      filtered = filtered.where((t) => t.date.isAfter(startDay.subtract(const Duration(seconds: 1)))).toList();
    }
    if (dateRange.end != null) {
      final endDay = DateTime(dateRange.end!.year, dateRange.end!.month, dateRange.end!.day, 23, 59, 59);
      filtered = filtered.where((t) => t.date.isBefore(endDay.add(const Duration(seconds: 1)))).toList();
    }
    
    return filtered;
  });
});

final transactionSummaryProvider = Provider<Map<String, double>>((ref) {
  final txsAsync = ref.watch(filteredTransactionsProvider);
  return txsAsync.maybeWhen(
    data: (txs) {
      double inTotal = 0;
      double outTotal = 0;
      for (final t in txs) {
        if (t.status == 'rejected' || t.status == 'pending' || t.status == 'pending_confirmation' || t.status == 'missed') continue; // only count confirmed/active
        if (t.direction == TransactionDirection.moneyIn) inTotal += t.amount;
        if (t.direction == TransactionDirection.moneyOut) outTotal += t.amount;
      }
      return {'in': inTotal, 'out': outTotal};
    },
    orElse: () => {'in': 0.0, 'out': 0.0},
  );
});
