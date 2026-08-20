import 'package:flutter/material.dart';

import 'package:smartkhata/core/theme/app_theme.dart';

/// Single loan row displaying avatar, borrower name, amount, and status badge.
class LoanItemTile extends StatelessWidget {
  const LoanItemTile({
    super.key,
    required this.borrowerName,
    required this.amount,
    required this.status,
    this.onTap,
  });

  final String borrowerName;
  final String amount;

  /// One of: active, overdue, paid.
  final String status;
  final VoidCallback? onTap;

  Color _statusColor(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'overdue':
        return AppTheme.colors(context).danger;
      case 'paid':
        return AppTheme.colors(context).success;
      default:
        return AppTheme.colors(context).accent;
    }
  }

  Color _statusBg(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'overdue':
        return AppTheme.colors(context).dangerSurface;
      case 'paid':
        return AppTheme.colors(context).successSurface;
      default:
        return AppTheme.colors(context).accentSurface;
    }
  }

  IconData _statusIcon() {
    switch (status.toLowerCase()) {
      case 'overdue':
        return Icons.warning_rounded;
      case 'paid':
        return Icons.check_circle_rounded;
      default:
        return Icons.cached_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = borrowerName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
        
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.colors(context).primary.withValues(alpha: 0.05),
        highlightColor: AppTheme.colors(context).primary.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: 16.0,
          ),
          child: Row(
            children: [
              // ── Avatar ──────────────────────────────────────────────
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [const Color(0xFF2C3E50), const Color(0xFF3498DB)]
                        : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.blue.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF2C3E50),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // ── Name & amount ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      borrowerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amount, 
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.colors(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Status badge ────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusBg(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _statusColor(context).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(),
                          size: 14,
                          color: _statusColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: _statusColor(context),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.colors(context).textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
