import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartkhata/core/theme/app_theme.dart';
import '../../loan_users/data/loan_users_repository.dart';

// Import new widgets
import '../widgets/borrower_summary_card.dart';
import '../widgets/pending_borrower_actions_card.dart';
import '../widgets/my_lenders_card.dart';
import '../widgets/active_borrower_loans_card.dart';
import '../widgets/upcoming_repayments_card.dart';
import '../widgets/pending_borrower_confirmations_card.dart';
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
        padding: EdgeInsets.only(top: hasBothRoles ? 190 : 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            connectionsAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.colors(context).accent,
                  ),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: AppTheme.colors(context).danger),
                ),
              ),
              data: (connections) {
                if (connections.isEmpty) {
                  return _buildEmptyState(context);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Smart Score ──
                    const Padding(
                      padding: EdgeInsets.only(
                        left: AppTheme.spacingLg,
                        right: AppTheme.spacingLg,
                        bottom: 12,
                      ),
                      child: _ScoreCard(),
                    ),

                    // ── Summary card ──
                    const BorrowerSummaryCard(),
                    // const SizedBox(height: AppTheme.spacingLg),

                    // ── Pending Invitations ──
                    const PendingBorrowerActionsCard(),

                    // ── Pending Confirmations ──
                    const PendingBorrowerConfirmationsCard(),

                    // ── My Lenders ──
                    const MyLendersCard(),
                    // const SizedBox(height: AppTheme.spacingLg),

                    // ── Active Loans ──
                    const ActiveBorrowerLoansCard(),
                    // const SizedBox(height: AppTheme.spacingLg),

                    // ── Upcoming repayments per connection ──
                    const UpcomingRepaymentsCard(),

                    const SizedBox(height: 120),
                  ],
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
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text('No Borrowings', style: AppTheme.text(context).headingMedium),
            const SizedBox(height: AppTheme.spacingSm),
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
        Color scoreBgColor;
        String scoreLabel;
        IconData scoreIcon;

        if (score >= 700) {
          scoreColor = const Color(0xFF2ECC71); // vibrant green
          scoreBgColor = const Color(0xFF2ECC71).withValues(alpha: 0.1);
          scoreLabel = 'Excellent';
          scoreIcon = Icons.verified_user_rounded;
        } else if (score >= 500) {
          scoreColor = const Color(0xFFF39C12); // vibrant orange
          scoreBgColor = const Color(0xFFF39C12).withValues(alpha: 0.1);
          scoreLabel = 'Fair';
          scoreIcon = Icons.shield_rounded;
        } else {
          scoreColor = const Color(0xFFE74C3C); // vibrant red
          scoreBgColor = const Color(0xFFE74C3C).withValues(alpha: 0.1);
          scoreLabel = 'Poor';
          scoreIcon = Icons.gpp_bad_rounded;
        }

        final double progress = (score.clamp(300, 850) - 300) / (850 - 300);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: scoreColor.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
              if (isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : scoreColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
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
                        value: 1.0, // background track
                        strokeWidth: 8,
                        color: isDark
                            ? Colors.white10
                            : Colors.grey.withValues(alpha: 0.1),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
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
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.colors(context).textPrimary,
                            letterSpacing: -1.0,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.colors(context).textSecondary,
                            letterSpacing: 0.5,
                            textBaseline: TextBaseline.alphabetic,
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
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scoreBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scoreColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(scoreIcon, size: 14, color: scoreColor),
                          const SizedBox(width: 4),
                          Text(
                            scoreLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'SmartKhata Trust Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppTheme.colors(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on your repayment history across all lenders.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.colors(context).textSecondary,
                        fontWeight: FontWeight.w500,
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
