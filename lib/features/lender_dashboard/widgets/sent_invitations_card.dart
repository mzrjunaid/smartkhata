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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return connectionsAsync.when(
      data: (connections) {
        final pendingInvitations = connections
            .where((c) => c.status == 'pending')
            .toList();

        if (pendingInvitations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SENT INVITATIONS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.colors(context).textSecondary,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          context.push('/loan-users');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.colors(context).primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
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
                                          ? connection.borrowerName[0]
                                                .toUpperCase()
                                          : '?',
                                      style: AppTheme.text(
                                        context,
                                      ).labelBold.copyWith(color: theme.primary),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          connection.borrowerName,
                                          style: AppTheme.text(
                                            context,
                                          ).headingSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          connection.borrowerPhone ??
                                              connection.borrowerCnic,
                                          style: AppTheme.text(
                                            context,
                                          ).bodyMedium,
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
                                          style: AppTheme.text(context).bodySmall
                                              .copyWith(
                                                color: theme.warning,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      if (totalDraftAmount > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            totalDraftAmount.toStringAsFixed(2),
                                            style: AppTheme.text(
                                              context,
                                            ).headingSmall,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (index <
                              (pendingInvitations.length > 3
                                      ? 3
                                      : pendingInvitations.length) -
                                  1)
                            Divider(
                              height: 1, 
                              indent: 76,
                              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
