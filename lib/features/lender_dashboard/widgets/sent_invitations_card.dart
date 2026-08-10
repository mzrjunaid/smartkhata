import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';

class SentInvitationsCard extends ConsumerWidget {
  const SentInvitationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(activeConnectionsProvider);
    final theme = AppTheme.colors(context);

    return connectionsAsync.when(
      data: (connections) {
        final pendingInvitations = connections
            .where((c) => c.status == 'pending')
            .toList();

        if (pendingInvitations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: AppTheme.radiusLg,
            border: Border.all(color: theme.textTertiary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sent Invitations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to Loan Users screen which has the Invited tab
                      context.push('/loan-users');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ...pendingInvitations.take(3).map((connection) {
                // If there are draft loans attached, sum their principals
                final totalDraftAmount = connection.loans
                    .where((l) => l.status == 'draft')
                    .fold(0.0, (sum, l) => sum + l.principal);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.primary.withOpacity(0.1),
                        child: Text(
                          connection.borrowerName.isNotEmpty
                              ? connection.borrowerName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connection.borrowerName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.textPrimary,
                              ),
                            ),
                            Text(
                              connection.borrowerPhone ?? connection.borrowerCnic,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.warning,
                              ),
                            ),
                          ),
                          if (totalDraftAmount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${totalDraftAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
