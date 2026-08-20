import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../new_loan/models/connection_model.dart';
import '../../../core/widgets/dashboard_app_bar.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../data/loan_users_repository.dart';

import '../../../core/providers/role_provider.dart';
import '../models/borrower_connection_model.dart';
import '../models/top_lender_model.dart';

class LoanUsersScreen extends ConsumerWidget {
  const LoanUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    
    if (role == AppRole.borrower) {
      return const _BorrowerView();
    } else {
      return const _LenderView();
    }
  }
}

class _BorrowerView extends ConsumerWidget {
  const _BorrowerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(borrowerConnectionsProvider);
    final topLendersAsync = ref.watch(topLendersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.colors(context).surface,
        body: Column(
          children: [
            const DashboardAppBar(
              title: 'Lenders',
              subtitle: 'View your lenders',
            ),
            TabBar(
              labelColor: AppTheme.colors(context).primary,
              unselectedLabelColor: AppTheme.colors(context).textSecondary,
              indicatorColor: AppTheme.colors(context).primary,
              tabs: const [
                Tab(text: 'My Lenders'),
                Tab(text: 'Top Lenders (Public)'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _BorrowerConnectionsList(asyncData: connectionsAsync),
                  _TopLendersList(asyncData: topLendersAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BorrowerConnectionsList extends StatelessWidget {
  const _BorrowerConnectionsList({required this.asyncData});

  final AsyncValue<List<BorrowerConnectionModel>> asyncData;

  @override
  Widget build(BuildContext context) {
    return asyncData.when(
      loading: () => Center(child: CircularProgressIndicator(color: AppTheme.colors(context).primary)),
      error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: AppTheme.colors(context).danger))),
      data: (connections) {
        if (connections.isEmpty) {
          return Center(child: Text('You have no active lenders.', style: TextStyle(color: AppTheme.colors(context).textSecondary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: connections.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final c = connections[index];
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.colors(context).cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/borrower-profile/${c.connectionId}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.colors(context).primary.withValues(alpha: 0.1),
                          radius: 24,
                          child: Text(
                            c.lenderName.isNotEmpty ? c.lenderName.substring(0, 1).toUpperCase() : 'L',
                            style: TextStyle(
                              color: AppTheme.colors(context).primary,
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
                              Text(c.lenderName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.colors(context).textPrimary)),
                              if (c.lenderPhone != null)
                                Text(c.lenderPhone!, style: TextStyle(fontSize: 14, color: AppTheme.colors(context).textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.colors(context).primarySurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${c.loans.length} Loans',
                            style: TextStyle(color: AppTheme.colors(context).primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TopLendersList extends StatelessWidget {
  const _TopLendersList({required this.asyncData});

  final AsyncValue<List<TopLenderModel>> asyncData;

  @override
  Widget build(BuildContext context) {
    return asyncData.when(
      loading: () => Center(child: CircularProgressIndicator(color: AppTheme.colors(context).primary)),
      error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: AppTheme.colors(context).danger))),
      data: (topLenders) {
        if (topLenders.isEmpty) {
          return Center(child: Text('No leaderboard data available.', style: TextStyle(color: AppTheme.colors(context).textSecondary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: topLenders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final t = topLenders[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.colors(context).cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: index < 3 ? AppTheme.colors(context).primary.withValues(alpha: 0.3) : Colors.transparent),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == 0 ? Colors.amber : index == 1 ? Colors.grey.shade400 : index == 2 ? Colors.brown.shade300 : AppTheme.colors(context).primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: index < 3 ? Colors.white : AppTheme.colors(context).primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    backgroundColor: AppTheme.colors(context).primary.withValues(alpha: 0.1),
                    radius: 20,
                    child: Text(
                      t.fullName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.colors(context).primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(t.fullName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.colors(context).textPrimary)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LenderView extends ConsumerWidget {
  const _LenderView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(activeConnectionsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.colors(context).surface,
        body: Column(
          children: [
            const DashboardAppBar(
              title: 'Loan Users',
              subtitle: 'Manage your connections',
            ),
            TabBar(
              labelColor: AppTheme.colors(context).primary,
              unselectedLabelColor: AppTheme.colors(context).textSecondary,
              indicatorColor: AppTheme.colors(context).primary,
              tabs: const [
                Tab(text: 'Claimed (Active)'),
                Tab(text: 'Invited (Pending)'),
              ],
            ),
            Expanded(
              child: connectionsAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.colors(context).primary,
                  ),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading users: $error',
                    style: TextStyle(color: AppTheme.colors(context).danger),
                  ),
                ),
                data: (connections) {
                  final claimed = connections
                      .where((c) => c.status == 'active' && c.claimStatus == 'claimed')
                      .toList();
                  final invited = connections
                      .where((c) => c.status == 'pending' || c.claimStatus == 'invited')
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
          style: TextStyle(color: AppTheme.colors(context).textSecondary),
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

  String _formatDuration(int days) {
    if (days >= 30) {
      final months = days ~/ 30;
      final remainingDays = days % 30;
      if (remainingDays == 0) return '$months month${months > 1 ? 's' : ''}';
      return '$months month${months > 1 ? 's' : ''}, $remainingDays day${remainingDays != 1 ? 's' : ''}';
    }
    return '$days day${days != 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerified = connection.lenderVerifiedAt != null;

    return InkWell(
      onTap: () {
        context.push('/borrower-profile/${connection.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.colors(context).cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.colors(context).primary.withValues(alpha: 0.1),
                radius: 24,
                child: Text(
                  connection.borrowerName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.colors(context).primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.borrowerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.colors(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CNIC: ${connection.borrowerCnic}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.colors(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Icon(Icons.verified, color: Colors.green, size: 28),
            ],
          ),
          if (connection.borrowerEmail != null ||
              connection.borrowerPhone != null) ...[
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            if (connection.borrowerEmail != null)
              Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: AppTheme.colors(context).textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    connection.borrowerEmail!,
                    style: TextStyle(
                      color: AppTheme.colors(context).textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            if (connection.borrowerPhone != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: AppTheme.colors(context).textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    connection.borrowerPhone!,
                    style: TextStyle(
                      color: AppTheme.colors(context).textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ],

          if (connection.loans.isNotEmpty) ...[
            const SizedBox(height: 16),
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
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.colors(context).primary.withValues(alpha: 0.15),
                      AppTheme.colors(context).primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.colors(context).primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: AppTheme.colors(context).primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Active Loan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.colors(context).primary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.colors(context).primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${loan.currency} ${totalWithInterest.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _LoanDetailRow(label: 'Principal', value: '${loan.currency} ${loan.principal.toStringAsFixed(0)}'),
                    _LoanDetailRow(label: 'Interest (${loan.interestRate}%)', value: '${loan.currency} ${interestAmount.toStringAsFixed(0)}'),
                    if (loan.disbursedAt != null)
                      _LoanDetailRow(label: 'Disbursed', value: '${loan.disbursedAt!.day}/${loan.disbursedAt!.month}/${loan.disbursedAt!.year}'),
                    _LoanDetailRow(label: 'Total Period', value: _formatDuration(totalPeriod)),
                    _LoanDetailRow(
                      label: 'Time Remaining', 
                      value: durationRemaining >= 0 ? _formatDuration(durationRemaining) : 'Overdue by ${_formatDuration(-durationRemaining)}',
                      valueColor: durationRemaining < 0 ? AppTheme.colors(context).danger : null,
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
                  backgroundColor: AppTheme.colors(context).primary,
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
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.colors(context).textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.colors(context).textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
