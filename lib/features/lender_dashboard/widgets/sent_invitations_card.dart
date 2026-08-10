import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';
import 'section_header.dart';

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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Sent Invitations',
              onViewAll: () {
                context.push('/loan-users');
              },
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
              decoration: AppTheme.cardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              ...pendingInvitations.asMap().entries.take(3).map((entry) {
                final index = entry.key;
                final connection = entry.value;
                // If there are draft loans attached, sum their principals
                final totalDraftAmount = connection.loans
                    .where((l) => l.status == 'draft')
                    .fold(0.0, (sum, l) => sum + l.principal);

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        // Navigate to profile or detail
                        context.push('/borrower-profile/${connection.id}');
                      },
                      borderRadius: AppTheme.radiusSm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLg,
                          vertical: AppTheme.spacingMd,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.primarySurface,
                                borderRadius: AppTheme.radiusSm,
                              ),
                              child: Text(
                                connection.borrowerName.isNotEmpty
                                    ? connection.borrowerName[0].toUpperCase()
                                    : '?',
                                style: AppTheme.text(context).labelBold.copyWith(
                                  color: theme.primary,
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
                                    style: AppTheme.text(context).headingSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    connection.borrowerPhone ?? connection.borrowerCnic,
                                    style: AppTheme.text(context).bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.warningSurface,
                                    borderRadius: AppTheme.radiusSm,
                                  ),
                                  child: Text(
                                    'Pending',
                                    style: AppTheme.text(context).bodySmall.copyWith(
                                      color: theme.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (totalDraftAmount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${totalDraftAmount.toStringAsFixed(2)}',
                                      style: AppTheme.text(context).headingSmall,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < (pendingInvitations.length > 3 ? 3 : pendingInvitations.length) - 1)
                      const Divider(height: 1, indent: 68),
                  ],
                );
              }).toList(),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
