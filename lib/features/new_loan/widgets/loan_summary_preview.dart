import 'package:flutter/material.dart';

import 'package:smartkhata/core/theme/app_theme.dart';
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
        margin: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
        ),
        padding: EdgeInsets.all(AppTheme.spacingXl),
        decoration: BoxDecoration(
          color: AppTheme.colors(context).surface,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(
            color: AppTheme.colors(context).textTertiary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 32,
              color: AppTheme.colors(context).textTertiary,
            ),
            SizedBox(height: AppTheme.spacingSm),
            Text(
              'Enter amount, rate & duration\nto see loan summary',
              textAlign: TextAlign.center,
              style: AppTheme.text(context).bodyMedium.copyWith(
                color: AppTheme.colors(context).textTertiary,
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
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
      ),
      padding: EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF388E3C),
          ],
        ),
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ─────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.auto_graph_rounded,
                color: Colors.white70,
                size: 18,
              ),
              SizedBox(width: AppTheme.spacingSm),
              Text(
                'Loan Summary',
                style: AppTheme.text(context).labelBold.copyWith(
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          SizedBox(height: AppTheme.spacingLg),

          // ── Monthly installment (hero metric) ─────────────────────
          Text(
            'Monthly Installment',
            style: AppTheme.text(context).bodySmall.copyWith(color: Colors.white60),
          ),
          SizedBox(height: 4),
          Text(
            service.formatCurrency(monthlyInstallment),
            style: AppTheme.text(context).headingLarge.copyWith(
              color: Colors.white,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // ── Two-column details ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: AppTheme.radiusSm,
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
          style: AppTheme.text(context).bodySmall.copyWith(color: Colors.white60),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.text(context).headingSmall.copyWith(
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
