import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../lender_dashboard/theme/dashboard_theme.dart';
import '../../providers/transactions_providers.dart';

class TransactionFilterBar extends ConsumerWidget {
  const TransactionFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(transactionFilterTypeProvider);
    final dateRange = ref.watch(transactionDateRangeProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildDateRangeButton(context, ref, dateRange),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'All',
            isActive: activeFilter == TransactionFilterType.all,
            onTap: () => ref
                .read(transactionFilterTypeProvider.notifier)
                .setFilter(TransactionFilterType.all),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'Money In',
            isActive: activeFilter == TransactionFilterType.moneyIn,
            onTap: () => ref
                .read(transactionFilterTypeProvider.notifier)
                .setFilter(TransactionFilterType.moneyIn),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'Money Out',
            isActive: activeFilter == TransactionFilterType.moneyOut,
            onTap: () => ref
                .read(transactionFilterTypeProvider.notifier)
                .setFilter(TransactionFilterType.moneyOut),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: 'Pending',
            isActive: activeFilter == TransactionFilterType.pending,
            onTap: () => ref
                .read(transactionFilterTypeProvider.notifier)
                .setFilter(TransactionFilterType.pending),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeButton(
    BuildContext context,
    WidgetRef ref,
    DateRange dateRange,
  ) {
    final isActive = dateRange.hasFilter;

    String label = 'Date';
    if (isActive) {
      if (dateRange.start != null && dateRange.end != null) {
        final startStr = DateFormat('MMM d').format(dateRange.start!);
        final endStr = DateFormat('MMM d').format(dateRange.end!);
        label = '$startStr - $endStr';
      } else if (dateRange.start != null) {
        label = 'From ${DateFormat('MMM d').format(dateRange.start!)}';
      } else if (dateRange.end != null) {
        label = 'Until ${DateFormat('MMM d').format(dateRange.end!)}';
      }
    }

    return GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDateRange:
              dateRange.hasFilter &&
                  dateRange.start != null &&
                  dateRange.end != null
              ? DateTimeRange(start: dateRange.start!, end: dateRange.end!)
              : null,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: DashboardTheme.primary,
                  onPrimary: Colors.white,
                  surface: DashboardTheme.surface,
                  onSurface: DashboardTheme.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          ref
              .read(transactionDateRangeProvider.notifier)
              .setDateRange(picked.start, picked.end);
        } else if (isActive) {
          // If they tapped outside or canceled, maybe they want to clear?
          // We can provide a clear button inside the chip if active.
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? DashboardTheme.primary.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isActive ? DashboardTheme.primary : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: isActive ? DashboardTheme.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? DashboardTheme.primary : Colors.grey.shade700,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () =>
                    ref.read(transactionDateRangeProvider.notifier).clear(),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: DashboardTheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? DashboardTheme.primary : Colors.white,
          border: Border.all(
            color: isActive ? DashboardTheme.primary : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: DashboardTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
