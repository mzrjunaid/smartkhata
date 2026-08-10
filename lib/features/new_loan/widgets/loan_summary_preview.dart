import 'package:flutter/material.dart';

import '../../lender_dashboard/theme/dashboard_theme.dart';
import '../services/new_loan_service.dart';

/// Live preview card that recalculates financial projections as the user types.
///
/// Shows monthly installment, total interest, and total repayable.
/// Receives raw values from the parent form and uses [NewLoanService]
/// for calculations.
class LoanSummaryPreview extends StatelessWidget {
  const LoanSummaryPreview({
    super.key,
    required this.principal,
    required this.annualRate,
    required this.months,
    required this.interestType,
    required this.service,
  });

  final double principal;
  final double annualRate;
  final int months;
  final String interestType;
  final NewLoanService service;

  bool get _hasValidInputs => principal > 0 && months > 0;

  @override
  Widget build(BuildContext context) {
    if (!_hasValidInputs) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: DashboardTheme.spacingLg,
        ),
        padding: const EdgeInsets.all(DashboardTheme.spacingXl),
        decoration: BoxDecoration(
          color: DashboardTheme.surface,
          borderRadius: DashboardTheme.radiusMd,
          border: Border.all(
            color: DashboardTheme.textTertiary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 32,
              color: DashboardTheme.textTertiary,
            ),
            const SizedBox(height: DashboardTheme.spacingSm),
            Text(
              'Enter amount, rate & duration\nto see loan summary',
              textAlign: TextAlign.center,
              style: DashboardTheme.bodyMedium.copyWith(
                color: DashboardTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    final monthlyInstallment = service.calculateMonthlyInstallment(
      principal: principal,
      annualRate: annualRate,
      months: months,
      interestType: interestType,
    );
    final totalInterest = service.calculateTotalInterest(
      principal: principal,
      annualRate: annualRate,
      months: months,
      interestType: interestType,
    );
    final totalRepayable = service.calculateTotalRepayable(
      principal: principal,
      annualRate: annualRate,
      months: months,
      interestType: interestType,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: DashboardTheme.spacingLg,
      ),
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
          ],
        ),
        borderRadius: DashboardTheme.radiusMd,
        boxShadow: DashboardTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ─────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: DashboardTheme.spacingSm),
              Text(
                'Loan Summary',
                style: DashboardTheme.labelBold.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: DashboardTheme.spacingLg),

          // ── Monthly installment (hero metric) ─────────────────────
          Text(
            'Monthly Installment',
            style: DashboardTheme.bodySmall.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            service.formatCurrency(monthlyInstallment),
            style: DashboardTheme.headingLarge.copyWith(
              color: Colors.white,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: DashboardTheme.spacingLg),

          // ── Two-column details ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(DashboardTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: DashboardTheme.radiusSm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Total Interest',
                    value: service.formatCurrency(totalInterest),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white24,
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Total Repayable',
                    value: service.formatCurrency(totalRepayable),
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

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: DashboardTheme.bodySmall.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: DashboardTheme.headingSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
