import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../new_loan/models/connection_model.dart';
import '../../lender_dashboard/theme/dashboard_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';

import '../../../core/widgets/dashboard_app_bar.dart';

class RepaymentsBorrowerListScreen extends ConsumerWidget {
  const RepaymentsBorrowerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(activeConnectionsProvider);

    return Scaffold(
      backgroundColor: DashboardTheme.surface,
      body: Column(
        children: [
          const DashboardAppBar(title: 'Repayments', showBackButton: true),
          Expanded(
            child: connectionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DashboardTheme.primary),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading borrowers: $error', style: const TextStyle(color: DashboardTheme.danger)),
        ),
        data: (connections) {
          final claimed = connections.where((c) => c.claimStatus == 'claimed').toList();

          if (claimed.isEmpty) {
            return const Center(
              child: Text('No active borrowers found.', style: TextStyle(color: DashboardTheme.textSecondary)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(DashboardTheme.spacingLg),
            itemCount: claimed.length,
            separatorBuilder: (context, index) => const SizedBox(height: DashboardTheme.spacingMd),
            itemBuilder: (context, index) {
              return _BorrowerRepaymentCard(connection: claimed[index]);
            },
          );
        },
      ),
      ),
      ],
      ),
    );
  }
}

class _BorrowerRepaymentCard extends StatelessWidget {
  const _BorrowerRepaymentCard({required this.connection});

  final ConnectionModel connection;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/repayments/${connection.id}');
      },
      borderRadius: DashboardTheme.radiusLg,
      child: Container(
        padding: const EdgeInsets.all(DashboardTheme.spacingLg),
        decoration: DashboardTheme.cardDecoration,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                connection.borrowerName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            const SizedBox(width: DashboardTheme.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.borrowerName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DashboardTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text('CNIC: ${connection.borrowerCnic}', style: DashboardTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: DashboardTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
