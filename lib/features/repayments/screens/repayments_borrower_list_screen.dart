import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../new_loan/models/connection_model.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';

import '../../../core/widgets/dashboard_app_bar.dart';

class RepaymentsBorrowerListScreen extends ConsumerWidget {
  const RepaymentsBorrowerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(activeConnectionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      body: Column(
        children: [
          DashboardAppBar(title: 'Repayments', showBackButton: true),
          Expanded(
            child: connectionsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppTheme.colors(context).primary),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading borrowers: $error', style: TextStyle(color: AppTheme.colors(context).danger)),
        ),
        data: (connections) {
          final claimed = connections.where((c) => c.claimStatus == 'claimed').toList();

          if (claimed.isEmpty) {
            return Center(
              child: Text('No active borrowers found.', style: TextStyle(color: AppTheme.colors(context).textSecondary)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            itemCount: claimed.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingMd),
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
      borderRadius: AppTheme.radiusLg,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingLg),
        decoration: AppTheme.cardDecoration(context),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                connection.borrowerName.substring(0, 1).toUpperCase(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            SizedBox(width: AppTheme.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.borrowerName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.colors(context).textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text('CNIC: ${connection.borrowerCnic}', style: AppTheme.text(context).bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.colors(context).textSecondary),
          ],
        ),
      ),
    );
  }
}
