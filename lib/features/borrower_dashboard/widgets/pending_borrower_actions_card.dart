import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../loan_users/data/loan_users_repository.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../lender_dashboard/widgets/section_header.dart';

class PendingBorrowerActionsCard extends ConsumerWidget {
  const PendingBorrowerActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(borrowerConnectionsProvider);

    return connectionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (connections) {
        final pendingInvitations = <Widget>[];

        for (final c in connections) {
          // 1. Pending connection / pure invitation
          if (c.status == 'pending' || c.hasPendingInvitation) {
            pendingInvitations.add(
              _PendingActionTile(
                title: 'Connection Invitation',
                subtitle: 'From ${c.lenderName}',
                icon: Icons.person_add_alt_1_outlined,
                buttonText: 'Accept',
                onAccept: () async {
                  try {
                    final repo = ref.read(loanUsersRepositoryProvider);
                    await repo.acceptConnectionInvitation(c.lenderProfileId!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invitation accepted successfully!'),
                        ),
                      );
                      ref.invalidate(borrowerConnectionsProvider);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to accept invitation: $e')),
                      );
                    }
                  }
                },
              ),
            );
          }

          // 2. Draft / Pending loans
          final draftLoans = c.loans.where(
            (l) => l.status == 'draft' || l.status == 'pending_disbursement',
          );
          for (final loan in draftLoans) {
            final isDraft = loan.status == 'draft';
            pendingInvitations.add(
              _PendingActionTile(
                title: isDraft ? 'Loan Invitation' : 'Pending Disbursement',
                subtitle:
                    'PKR ${loan.principal.toStringAsFixed(0)} from ${c.lenderName}',
                icon: Icons.request_quote_outlined,
                buttonText: isDraft ? 'Accept' : 'Waiting',
                onAccept: isDraft
                    ? () async {
                        try {
                          final repo = ref.read(loanUsersRepositoryProvider);
                          await repo.acceptLoan(loan.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Loan accepted successfully!'),
                              ),
                            );
                            ref.invalidate(borrowerConnectionsProvider);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to accept loan: $e')),
                            );
                          }
                        }
                      }
                    : null,
              ),
            );
          }
        }

        if (pendingInvitations.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Pending Invitations'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              child: Column(children: pendingInvitations),
            ),
          ],
        );
      },
    );
  }
}

class _PendingActionTile extends StatelessWidget {
  const _PendingActionTile({
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
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.symmetric(
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
            child: Icon(icon, color: AppTheme.colors(context).warning, size: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
