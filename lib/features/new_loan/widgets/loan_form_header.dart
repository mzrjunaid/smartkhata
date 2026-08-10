import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartkhata/core/theme/app_theme.dart';

/// Gradient header for the new loan form with back button and title.
class LoanFormHeader extends StatelessWidget {
  const LoanFormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTheme.spacingMd,
        left: AppTheme.spacingSm,
        right: AppTheme.spacingLg,
        bottom: AppTheme.spacingXl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.colors(context).primary,
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
            icon: Icon(Icons.arrow_back_rounded),
            color: Colors.white,
            tooltip: 'Back to Dashboard',
          ),

          Padding(
            padding: EdgeInsets.only(
              left: AppTheme.spacingMd,
              top: AppTheme.spacingSm,
            ),
            child: Row(
              children: [
                // ── Icon badge ──────────────────────────────────────
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: AppTheme.radiusMd,
                  ),
                  child: Icon(
                    Icons.handshake_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                SizedBox(width: AppTheme.spacingLg),

                // ── Title & subtitle ────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Loan',
                        style: AppTheme.text(context).headingLarge.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Fill in borrower and loan details below',
                        style: AppTheme.text(context).bodyMedium.copyWith(
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
