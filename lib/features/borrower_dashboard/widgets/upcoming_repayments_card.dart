import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../loan_users/data/loan_users_repository.dart';
import '../../loan_users/models/repayment_model.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../../lender_dashboard/widgets/section_header.dart';

class UpcomingRepaymentsCard extends ConsumerWidget {
  const UpcomingRepaymentsCard({super.key});

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
                        'UPCOMING REPAYMENTS',
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
                        (c) => _UpcomingRepaymentsSection(
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
        final upcoming = repayments
            .where((r) => r.status == 'pending' && r.dueDate != null)
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

        if (upcoming.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
              child: Text(
                'From $lenderName',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colors(context).primary,
                ),
              ),
            ),
            ...upcoming.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final r = entry.value;
              return Column(
                children: [
                  _UpcomingTile(repayment: r),
                  if (index < 2 && index < upcoming.length - 1)
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

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.repayment});
  final RepaymentModel repayment;

  @override
  Widget build(BuildContext context) {
    final dateStr = repayment.dueDate?.toLocal().toString().split(' ')[0] ?? '';
    final daysLeft = repayment.dueDate != null
        ? repayment.dueDate!.difference(DateTime.now()).inDays
        : 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/borrower-repayment-form?repaymentId=${repayment.id}'),
        splashColor: AppTheme.colors(context).primary.withValues(alpha: 0.05),
        highlightColor: AppTheme.colors(context).primary.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: daysLeft < 7
                        ? [const Color(0xFFF39C12), const Color(0xFFE67E22)]
                        : (isDark 
                            ? [const Color(0xFF2C3E50), const Color(0xFF3498DB)]
                            : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: daysLeft < 7 
                          ? const Color(0xFFF39C12).withValues(alpha: 0.3)
                          : (isDark ? Colors.black26 : Colors.blue.withValues(alpha: 0.2)),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.event_rounded,
                    size: 24,
                    color: daysLeft < 7 
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF2C3E50)),
                  ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.colors(context).textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppTheme.colors(context).textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: $dateStr', 
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.colors(context).textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: daysLeft < 0
                      ? AppTheme.colors(context).dangerSurface
                      : (daysLeft < 7
                            ? AppTheme.colors(context).warningSurface
                            : (isDark ? Colors.white10 : Colors.grey.shade100)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: daysLeft < 0
                        ? AppTheme.colors(context).danger.withValues(alpha: 0.3)
                        : (daysLeft < 7
                              ? AppTheme.colors(context).warning.withValues(alpha: 0.3)
                              : Colors.transparent),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      daysLeft < 0 ? Icons.error_rounded : Icons.schedule_rounded,
                      size: 14,
                      color: daysLeft < 0
                          ? AppTheme.colors(context).danger
                          : (daysLeft < 7
                                ? AppTheme.colors(context).warning
                                : AppTheme.colors(context).textTertiary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      daysLeft >= 0 ? '${daysLeft}d' : '${-daysLeft}d',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: daysLeft < 0
                            ? AppTheme.colors(context).danger
                            : (daysLeft < 7
                                  ? AppTheme.colors(context).warning
                                  : AppTheme.colors(context).textTertiary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
