import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smartkhata/core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_app_bar.dart';
import '../models/reminder_item.dart';
import '../providers/reminders_provider.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(lenderRemindersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      body: Column(
        children: [
          const DashboardAppBar(
            title: 'Payment Reminders',
            showBackButton: true,
          ),
          Expanded(
            child: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.colors(context).danger),
                const SizedBox(height: 12),
                Text(
                  'Failed to load reminders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colors(context).textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.colors(context).textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (reminders) {
          final pending = reminders['pending'] ?? [];
          final rejected = reminders['rejected'] ?? [];
          final missed = reminders['missed'] ?? [];

          if (pending.isEmpty && rejected.isEmpty && missed.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.colors(context).success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 40,
                      color: AppTheme.colors(context).success,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All Caught Up!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colors(context).textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending, rejected, or missed\ninstallments to remind about.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.colors(context).textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (missed.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Missed',
                    count: missed.length,
                    color: AppTheme.colors(context).danger,
                    icon: Icons.cancel_rounded,
                  ),
                  ...missed.map((item) => _ReminderTile(
                    item: item,
                    statusColor: AppTheme.colors(context).danger,
                    isDark: isDark,
                  )),
                ],
                if (rejected.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Rejected',
                    count: rejected.length,
                    color: AppTheme.colors(context).warning,
                    icon: Icons.replay_rounded,
                  ),
                  ...rejected.map((item) => _ReminderTile(
                    item: item,
                    statusColor: AppTheme.colors(context).warning,
                    isDark: isDark,
                  )),
                ],
                if (pending.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Upcoming (Next 30 Days)',
                    count: pending.length,
                    color: AppTheme.colors(context).info,
                    icon: Icons.schedule_rounded,
                  ),
                  ...pending.map((item) => _ReminderTile(
                    item: item,
                    statusColor: AppTheme.colors(context).info,
                    isDark: isDark,
                  )),
                ],
              ],
            ),
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppTheme.colors(context).textSecondary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.item,
    required this.statusColor,
    required this.isDark,
  });

  final ReminderItem item;
  final Color statusColor;
  final bool isDark;

  Future<void> _sendWhatsAppReminder(BuildContext context) async {
    final phone = item.borrowerPhone?.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Borrower phone number is not available')),
        );
      }
      return;
    }

    final dueDateStr = item.dueDate != null
        ? DateFormat('MMM dd, yyyy').format(item.dueDate!)
        : 'N/A';
    final amountStr = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'PKR ',
      decimalDigits: 0,
    ).format(item.amount);

    String statusNote;
    switch (item.status) {
      case 'missed':
        statusNote = 'Your installment of $amountStr due on $dueDateStr was missed.';
        break;
      case 'rejected':
        statusNote = 'Your installment submission of $amountStr (due $dueDateStr) was rejected. Please resubmit.';
        break;
      default:
        statusNote = 'This is a reminder for your upcoming installment of $amountStr due on $dueDateStr.';
    }

    final message =
        'Dear ${item.borrowerName},\n\n'
        '$statusNote\n\n'
        'Please pay this installment as soon as possible to avoid any penalties.\n\n'
        'Thank you,\nSmartKhata';

    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueDateStr = item.dueDate != null
        ? DateFormat('MMM dd, yyyy').format(item.dueDate!)
        : 'No due date';
    final amountStr = NumberFormat.currency(
      locale: 'en_PK',
      symbol: '₨ ',
      decimalDigits: 0,
    ).format(item.amount);

    // Determine days relative text
    String daysLabel = '';
    if (item.dueDate != null) {
      final diff = item.dueDate!.difference(DateTime.now()).inDays;
      if (diff < 0) {
        daysLabel = '${diff.abs()}d overdue';
      } else if (diff == 0) {
        daysLabel = 'Due today';
      } else {
        daysLabel = 'in $diff days';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Borrower avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                item.borrowerName.isNotEmpty
                    ? item.borrowerName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.borrowerName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colors(context).textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      amountStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: AppTheme.colors(context).textTertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        dueDateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.colors(context).textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (daysLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    daysLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: item.dueDate != null &&
                              item.dueDate!.isBefore(DateTime.now())
                          ? AppTheme.colors(context).danger
                          : AppTheme.colors(context).textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // WhatsApp button
          Material(
            color: const Color(0xFF25D366).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _sendWhatsAppReminder(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.message_rounded,
                  color: Color(0xFF25D366),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
