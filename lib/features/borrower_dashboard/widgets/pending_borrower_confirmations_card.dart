import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../loan_users/data/loan_users_repository.dart';
import '../../loan_users/models/repayment_model.dart';
import 'package:smartkhata/core/theme/app_theme.dart';

class PendingBorrowerConfirmationsCard extends ConsumerWidget {
  const PendingBorrowerConfirmationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(borrowerConnectionsProvider);

    return connectionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (connections) {
        if (connections.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        'PENDING CONFIRMATIONS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.colors(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: connections
                      .map(
                        (c) => _PendingConfirmationsSection(
                          connectionId: c.connectionId,
                          lenderName: c.lenderName,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PendingConfirmationsSection extends ConsumerWidget {
  const _PendingConfirmationsSection({
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
        final pending = repayments
            .where((r) => r.status == 'pending_confirmation')
            .toList()
          ..sort((a, b) => (b.paidDate ?? DateTime.now()).compareTo((a.paidDate ?? DateTime.now())));

        if (pending.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
              child: Text(
                'To $lenderName',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colors(context).primary,
                ),
              ),
            ),
            ...pending.asMap().entries.map((entry) {
              final index = entry.key;
              final r = entry.value;
              return Column(
                children: [
                  _PendingTile(repayment: r),
                  if (index < pending.length - 1)
                    Divider(
                      height: 1, 
                      indent: 84,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    ),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.repayment});
  final RepaymentModel repayment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        context.push('/borrower-repayment-form?repaymentId=${repayment.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rs. ${NumberFormat('#,##0').format(repayment.amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.colors(context).textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (repayment.paidDate != null)
                    Text(
                      'Submitted on ${DateFormat('MMM d, y').format(repayment.paidDate!)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.colors(context).textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.colors(context).textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
