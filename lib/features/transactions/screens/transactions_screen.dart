import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/dashboard_app_bar.dart';
import '../../lender_dashboard/theme/dashboard_theme.dart';
import '../providers/transactions_providers.dart';
import '../models/transaction_model.dart';
import 'widgets/transaction_summary_card.dart';
import 'widgets/transaction_filter_bar.dart';
import 'widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);

    return Scaffold(
      backgroundColor: DashboardTheme.surface,
      body: Column(
        children: [
          const DashboardAppBar(
            title: 'Transactions',
            subtitle: 'Your money in and out',
          ),
          
          const TransactionSummaryCard(),
          const TransactionFilterBar(),
          
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transactions found for the selected filters.',
                      style: DashboardTheme.bodyMedium,
                    ),
                  );
                }

                // Group by date (YYYY-MM-DD)
                final grouped = _groupByDate(transactions);
                final listItems = _buildListItems(grouped);

                return RefreshIndicator(
                  color: DashboardTheme.primary,
                  onRefresh: () async {
                    ref.invalidate(allTransactionsProvider);
                    await ref.read(allTransactionsProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: listItems.length,
                    itemBuilder: (context, index) {
                      return listItems[index];
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<TransactionModel>> _groupByDate(List<TransactionModel> transactions) {
    final map = <String, List<TransactionModel>>{};
    final formatter = DateFormat('yyyy-MM-dd');
    for (final t in transactions) {
      final dateStr = formatter.format(t.date);
      if (!map.containsKey(dateStr)) {
        map[dateStr] = [];
      }
      map[dateStr]!.add(t);
    }
    return map;
  }

  List<Widget> _buildListItems(Map<String, List<TransactionModel>> grouped) {
    final items = <Widget>[];
    
    // keys are already sorted descending because transactions are sorted
    for (final entry in grouped.entries) {
      final dateStr = entry.key;
      final txs = entry.value;
      
      // Header
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            _formatDateHeader(DateTime.parse(dateStr)),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      
      // Items
      for (final tx in txs) {
        items.add(TransactionTile(transaction: tx));
      }
    }
    
    return items;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);
    
    if (target == today) return 'TODAY';
    if (target == yesterday) return 'YESTERDAY';
    
    return DateFormat('MMMM d, yyyy').format(date).toUpperCase();
  }
}
