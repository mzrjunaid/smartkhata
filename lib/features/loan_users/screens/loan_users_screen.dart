import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../new_loan/models/connection_model.dart';
import '../../../core/widgets/dashboard_app_bar.dart';
import '../../lender_dashboard/theme/dashboard_theme.dart';
import '../data/loan_users_repository.dart';

class LoanUsersScreen extends ConsumerWidget {
  const LoanUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(activeConnectionsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: DashboardTheme.surface,
        body: Column(
          children: [
            const DashboardAppBar(
              title: 'Loan Users',
              subtitle: 'Manage your connections',
            ),
            const TabBar(
              labelColor: DashboardTheme.primary,
              unselectedLabelColor: DashboardTheme.textSecondary,
              indicatorColor: DashboardTheme.primary,
              tabs: [
                Tab(text: 'Claimed (Active)'),
                Tab(text: 'Invited (Pending)'),
              ],
            ),
            Expanded(
              child: connectionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: DashboardTheme.primary,
                  ),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading users: $error',
                    style: const TextStyle(color: DashboardTheme.danger),
                  ),
                ),
                data: (connections) {
                  final claimed = connections
                      .where((c) => c.claimStatus == 'claimed')
                      .toList();
                  final invited = connections
                      .where((c) => c.claimStatus == 'invited')
                      .toList();

                  return TabBarView(
                    children: [
                      _UserList(users: claimed, isInvitedTab: false),
                      _UserList(users: invited, isInvitedTab: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({required this.users, required this.isInvitedTab});

  final List<ConnectionModel> users;
  final bool isInvitedTab;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          isInvitedTab ? 'No pending invitations.' : 'No active users yet.',
          style: const TextStyle(color: DashboardTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
      itemCount: users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _UserCard(connection: users[index]);
      },
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.connection});

  final ConnectionModel connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerified = connection.lenderVerifiedAt != null;

    return InkWell(
      onTap: () {
        context.push('/borrower-profile/${connection.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DashboardTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: DashboardTheme.cardShadow,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: DashboardTheme.primary.withValues(alpha: 0.1),
                radius: 24,
                child: Text(
                  connection.borrowerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: DashboardTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.borrowerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DashboardTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CNIC: ${connection.borrowerCnic}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: DashboardTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                const Icon(Icons.verified, color: Colors.green, size: 28),
            ],
          ),
          if (connection.borrowerEmail != null ||
              connection.borrowerPhone != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            if (connection.borrowerEmail != null)
              Row(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: DashboardTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    connection.borrowerEmail!,
                    style: const TextStyle(
                      color: DashboardTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            if (connection.borrowerPhone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: DashboardTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    connection.borrowerPhone!,
                    style: const TextStyle(
                      color: DashboardTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ],

          if (connection.loans.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...connection.loans.map((loan) {
              final totalPeriod = loan.dueDate != null && loan.disbursedAt != null
                  ? loan.dueDate!.difference(loan.disbursedAt!).inDays
                  : 0;
              final durationRemaining = loan.dueDate != null
                  ? loan.dueDate!.difference(DateTime.now()).inDays
                  : 0;
              
              // Basic flat interest calculation for display purposes
              final interestAmount = loan.interestType == 'flat'
                  ? loan.principal * (loan.interestRate / 100) * (totalPeriod / 365)
                  : 0.0; // Extend logic for other types if needed
              
              final totalWithInterest = loan.principal + interestAmount;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DashboardTheme.primarySurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardTheme.primaryLight.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Active Loan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: DashboardTheme.primary,
                          ),
                        ),
                        Text(
                          '${loan.currency} ${totalWithInterest.toStringAsFixed(0)} total',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: DashboardTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _LoanDetailRow(label: 'Principal:', value: '${loan.currency} ${loan.principal.toStringAsFixed(0)}'),
                    _LoanDetailRow(label: 'Interest (${loan.interestRate}%):', value: '${loan.currency} ${interestAmount.toStringAsFixed(0)}'),
                    if (loan.disbursedAt != null)
                      _LoanDetailRow(label: 'Disbursed:', value: '${loan.disbursedAt!.day}/${loan.disbursedAt!.month}/${loan.disbursedAt!.year}'),
                    _LoanDetailRow(label: 'Total Period:', value: '$totalPeriod days'),
                    _LoanDetailRow(
                      label: 'Time Remaining:', 
                      value: durationRemaining >= 0 ? '$durationRemaining days' : 'Overdue by ${-durationRemaining} days',
                      valueColor: durationRemaining < 0 ? DashboardTheme.danger : null,
                    ),
                  ],
                ),
              );
            }),
          ],

          if (!isVerified) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(loanUsersRepositoryProvider)
                        .verifyConnection(connection.id);
                    // Refresh the list after verification
                    ref.invalidate(activeConnectionsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User verified successfully!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Verify User Info'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}

class _LoanDetailRow extends StatelessWidget {
  const _LoanDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: DashboardTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? DashboardTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
