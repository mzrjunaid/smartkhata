import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';
import '../../loan_users/models/borrower_connection_model.dart';
import '../../loan_users/models/repayment_model.dart';
import '../../lender_dashboard/widgets/loan_item_tile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/profile_providers.dart';

/// Dashboard shown when the user is viewing the app as a **borrower**.
class BorrowerDashboard extends ConsumerWidget {
  const BorrowerDashboard({super.key, this.hasBothRoles = false});
  final bool hasBothRoles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(borrowerConnectionsProvider);

    return RefreshIndicator(
      color: AppTheme.colors(context).accent,
      onRefresh: () async => ref.invalidate(borrowerConnectionsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: hasBothRoles ? 190 : 135),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            connectionsAsync.when(
              loading: () => Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.colors(context).accent,
                  ),
                ),
              ),
              error: (err, _) => Padding(
                padding: EdgeInsets.all(AppTheme.spacingLg),
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: AppTheme.colors(context).danger),
                ),
              ),
              data: (connections) {
                if (connections.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Aggregate data
                final allLoans = connections.expand((c) => c.loans).toList();
                final activeLoans = allLoans
                    .where((l) => l.status == 'active' || l.status == 'overdue')
                    .toList();
                final totalBorrowed = allLoans.fold<double>(
                  0,
                  (s, l) => s + l.principal,
                );

                return Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Smart Score ──
                      const _ScoreCard(),
                      SizedBox(height: AppTheme.spacingXl),

                      // ── Summary card ──
                      _buildSummaryCard(
                        context,
                        connections.length,
                        activeLoans.length,
                        totalBorrowed,
                      ),
                      SizedBox(height: AppTheme.spacingXl),

                      // ── Pending Invitations ──
                      ...(() {
                        final pendingInvitations = <Widget>[];

                        for (final c in connections) {
                          // 1. Pending connection / pure invitation
                          if (c.status == 'pending' || c.hasPendingInvitation) {
                            pendingInvitations.add(
                              _PendingInvitationTile(
                                title: 'Connection Invitation',
                                subtitle: 'From ${c.lenderName}',
                                icon: Icons.person_add_alt_1_outlined,
                                buttonText: 'Accept',
                                onAccept: () async {
                                  try {
                                    final repo = ref.read(
                                      loanUsersRepositoryProvider,
                                    );
                                    await repo.acceptConnectionInvitation(
                                      c.lenderProfileId!,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Invitation accepted successfully!',
                                          ),
                                        ),
                                      );
                                      ref.invalidate(
                                        borrowerConnectionsProvider,
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to accept invitation: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          }

                          // 2. Draft / Pending loans
                          final draftLoans = c.loans.where(
                            (l) =>
                                l.status == 'draft' ||
                                l.status == 'pending_disbursement',
                          );
                          for (final loan in draftLoans) {
                            final isDraft = loan.status == 'draft';
                            pendingInvitations.add(
                              _PendingInvitationTile(
                                title: isDraft
                                    ? 'Loan Invitation'
                                    : 'Pending Disbursement',
                                subtitle:
                                    'PKR ${loan.principal.toStringAsFixed(0)} from ${c.lenderName}',
                                icon: Icons.request_quote_outlined,
                                buttonText: isDraft ? 'Accept' : 'Waiting',
                                onAccept: isDraft
                                    ? () async {
                                        try {
                                          final repo = ref.read(
                                            loanUsersRepositoryProvider,
                                          );
                                          await repo.acceptLoan(loan.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Loan accepted successfully!',
                                                ),
                                              ),
                                            );
                                            ref.invalidate(
                                              borrowerConnectionsProvider,
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to accept loan: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    : null,
                              ),
                            );
                          }
                        }

                        if (pendingInvitations.isEmpty) return <Widget>[];

                        return [
                          Text(
                            'Pending Invitations',
                            style: AppTheme.text(context).headingMedium,
                          ),
                          SizedBox(height: AppTheme.spacingMd),
                          ...pendingInvitations,
                          SizedBox(height: AppTheme.spacingXl),
                        ];
                      })(),

                      // ── My Lenders ──
                      Text(
                        'My Lenders',
                        style: AppTheme.text(context).headingMedium,
                      ),
                      SizedBox(height: AppTheme.spacingMd),
                      ...connections.map((c) => _LenderCard(connection: c)),

                      // ── Active Loans ──
                      if (activeLoans.isNotEmpty) ...[
                        SizedBox(height: AppTheme.spacingXl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Loans',
                              style: AppTheme.text(context).headingMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                context.go('/loan-users');
                              },
                              child: Text(
                                'View All',
                                style: AppTheme.text(context).bodyMedium
                                    .copyWith(
                                      color: AppTheme.colors(context).primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTheme.spacingMd),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.colors(context).cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              ...(() {
                                final activeLoanEntries = connections
                                    .expand(
                                      (c) => c.loans
                                          .where(
                                            (l) =>
                                                l.status == 'active' ||
                                                l.status == 'overdue',
                                          )
                                          .map(
                                            (l) => (
                                              loan: l,
                                              lenderName: c.lenderName,
                                              connectionId: c.connectionId,
                                            ),
                                          ),
                                    )
                                    .toList();

                                return activeLoanEntries.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return Column(
                                    children: [
                                      LoanItemTile(
                                        borrowerName: item.lenderName,
                                        amount:
                                            '${item.loan.currency} ${item.loan.principal.toStringAsFixed(0)}',
                                        status: item.loan.status ?? 'active',
                                        onTap: () {
                                          context.push('/borrower-profile/${item.connectionId}');
                                        },
                                      ),
                                      if (index < activeLoanEntries.length - 1)
                                        const Divider(height: 1, indent: 68),
                                    ],
                                  );
                                }).toList();
                              })(),
                            ],
                          ),
                        ),
                      ],

                      // ── Upcoming repayments per connection ──
                      SizedBox(height: AppTheme.spacingXl),
                      Text(
                        'Upcoming Repayments',
                        style: AppTheme.text(context).headingMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      ...connections.map(
                        (c) => _UpcomingRepaymentsSection(
                          connectionId: c.connectionId,
                          lenderName: c.lenderName,
                        ),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: AppTheme.spacingLg),
            Text('No Borrowings', style: AppTheme.text(context).headingMedium),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              'You don\'t have any active loans as a borrower.',
              style: AppTheme.text(context).bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    int lenderCount,
    int activeLoansCount,
    double totalBorrowed,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.colors(context).primary,
            AppTheme.colors(context).accent,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.colors(context).primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Financial Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem(
                context,
                'Lenders',
                lenderCount.toString(),
                Icons.people_alt_outlined,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              _summaryItem(
                context,
                'Active Loans',
                activeLoansCount.toString(),
                Icons.receipt_long_outlined,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              _summaryItem(
                context,
                'Total Borrowed',
                'PKR ${_formatAmount(totalBorrowed)}',
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
      ],
    );
  }

  static String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

// ── Lender Card ─────────────────────────────────────────────────────────

class _LenderCard extends ConsumerWidget {
  const _LenderCard({required this.connection});
  final BorrowerConnectionModel connection;

  Future<void> _launchWhatsApp(
    BuildContext context,
    String? borrowerName,
    String? borrowerCnic,
    String? borrowerPhone,
  ) async {
    final phone = connection.lenderPhone?.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lender phone number is not available')),
        );
      }
      return;
    }

    final totalBorrowed = connection.loans.fold<double>(
      0,
      (s, l) => s + l.principal,
    );
    final activeLoansCount = connection.loans
        .where((l) => l.status == 'active' || l.status == 'overdue')
        .length;
    final loanProfile =
        '$activeLoansCount active loans, total: PKR ${totalBorrowed.toStringAsFixed(0)}';

    final message =
        'Borrower Name: ${borrowerName ?? 'Unknown'}\n'
        'CNIC: ${borrowerCnic ?? 'Unknown'}\n'
        'Contact Number: ${borrowerPhone ?? 'Unknown'}\n'
        'Loan Profile: $loanProfile\n\n'
        'Message: ';

    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanCount = connection.loans.length;
    final initial = connection.lenderName.isNotEmpty
        ? connection.lenderName[0].toUpperCase()
        : 'L';

    final profileAsync = ref.watch(currentProfileProvider);
    final borrowerName = profileAsync.value?['full_name'] as String?;
    final borrowerCnic = profileAsync.value?['cnic'] as String?;
    final borrowerPhone = profileAsync.value?['phone'] as String?;

    final hasPendingLoan = connection.loans.any(
      (l) =>
          l.status == 'draft' ||
          l.status == 'pending_disbursement' ||
          l.status == 'pending',
    );
    final isPendingConnection = connection.status == 'pending';
    final isPending =
        isPendingConnection ||
        connection.hasPendingInvitation ||
        hasPendingLoan;

    String pendingText = 'Pending';
    if (isPendingConnection) {
      pendingText = 'Pending Connection';
    } else if (connection.hasPendingInvitation) {
      pendingText = 'Pending Invitation';
    } else if (hasPendingLoan) {
      pendingText = 'Pending Loan';
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: isPending
            ? Theme.of(context).cardColor.withValues(alpha: 0.6)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.colors(context).accent.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.colors(context).accentSurface,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colors(context).accent,
                ),
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      connection.lenderName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colors(context).textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          pendingText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 14,
                      color: AppTheme.colors(context).textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$loanCount loan${loanCount != 1 ? 's' : ''}',
                      style: AppTheme.text(context).bodyMedium,
                    ),
                  ],
                ),
                if (connection.lenderPhone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppTheme.colors(context).textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        connection.lenderPhone!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.colors(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (connection.lenderPhone != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.chat, color: Colors.green, size: 24),
                onPressed: () => _launchWhatsApp(
                  context,
                  borrowerName,
                  borrowerCnic,
                  borrowerPhone,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Upcoming Repayments Section (per connection) ────────────────────────

class _UpcomingRepaymentsSection extends ConsumerWidget {
  const _UpcomingRepaymentsSection({
    required this.connectionId,
    required this.lenderName,
  });
  final String connectionId;
  final String lenderName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repaymentsAsync = ref.watch(
      connectionRepaymentsProvider(connectionId),
    );

    return repaymentsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (repayments) {
        final upcoming =
            repayments
                .where((r) => r.status == 'pending' && r.dueDate != null)
                .toList()
              ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

        if (upcoming.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Text(
                'From $lenderName',
                style: AppTheme.text(context).labelBold,
              ),
            ),
            ...upcoming.take(3).map((r) => _UpcomingTile(repayment: r)),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        );
      },
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.repayment});
  final RepaymentModel repayment;

  @override
  Widget build(BuildContext context) {
    final dateStr = repayment.dueDate?.toLocal().toString().split(' ')[0] ?? '';
    final daysLeft = repayment.dueDate != null
        ? repayment.dueDate!.difference(DateTime.now()).inDays
        : 0;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: daysLeft < 7
              ? AppTheme.colors(context).warning.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: daysLeft < 7
                  ? AppTheme.colors(context).warningSurface
                  : AppTheme.colors(context).accentSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.schedule,
              size: 20,
              color: daysLeft < 7
                  ? AppTheme.colors(context).warning
                  : AppTheme.colors(context).accent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PKR ${repayment.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Due: $dateStr', style: AppTheme.text(context).bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: daysLeft < 0
                  ? AppTheme.colors(context).dangerSurface
                  : (daysLeft < 7
                        ? AppTheme.colors(context).warningSurface
                        : Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              daysLeft >= 0 ? '${daysLeft}d' : '${-daysLeft}d late',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: daysLeft < 0
                    ? AppTheme.colors(context).danger
                    : (daysLeft < 7
                          ? AppTheme.colors(context).warning
                          : AppTheme.colors(context).textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Smart Score Component ───────────────────────────────────────────────

class _ScoreCard extends ConsumerWidget {
  const _ScoreCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileIdAsync = ref.watch(currentProfileIdProvider);
    final profileId = profileIdAsync.value;

    if (profileId == null) {
      return const SizedBox.shrink();
    }

    final scoreAsync = ref.watch(borrowerCreditScoreProvider(profileId));

    return scoreAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (scoreModel) {
        if (scoreModel == null) return const SizedBox.shrink();

        final score = scoreModel.score;
        Color scoreColor;
        String scoreLabel;

        if (score >= 700) {
          scoreColor = Colors.green.shade600;
          scoreLabel = 'Excellent';
        } else if (score >= 500) {
          scoreColor = Colors.orange.shade500;
          scoreLabel = 'Fair';
        } else {
          scoreColor = Colors.red.shade500;
          scoreLabel = 'Poor';
        }

        final double progress = (score.clamp(300, 850) - 300) / (850 - 300);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppTheme.spacingXl),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        color: scoreColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          score.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.colors(context).textPrimary,
                            height: 1,
                          ),
                        ),
                        Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.colors(context).textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        scoreLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your SmartKhata Trust Score',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colors(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on your repayment history across all lenders.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.colors(context).textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Pending Invitation Tile ─────────────────────────────────────────────

class _PendingInvitationTile extends StatelessWidget {
  const _PendingInvitationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onAccept,
    this.buttonText = 'Accept',
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAccept;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).warningSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.colors(context).warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.colors(context).warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colors(context).textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.colors(context).textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onAccept != null)
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors(context).primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.colors(context).textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
