import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../lender_dashboard/theme/dashboard_theme.dart';

/// Gradient header for the new loan form with back button and title.
class LoanFormHeader extends StatelessWidget {
  const LoanFormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + DashboardTheme.spacingMd,
        left: DashboardTheme.spacingSm,
        right: DashboardTheme.spacingLg,
        bottom: DashboardTheme.spacingXl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardTheme.primary,
            Color(0xFF2E7D32),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Back button ───────────────────────────────────────────
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
            tooltip: 'Back to Dashboard',
          ),

          Padding(
            padding: const EdgeInsets.only(
              left: DashboardTheme.spacingMd,
              top: DashboardTheme.spacingSm,
            ),
            child: Row(
              children: [
                // ── Icon badge ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(DashboardTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: DashboardTheme.radiusMd,
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: DashboardTheme.spacingLg),

                // ── Title & subtitle ────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Loan',
                        style: DashboardTheme.headingLarge.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fill in borrower and loan details below',
                        style: DashboardTheme.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
