import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../data/notifications_repository.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppTheme.colors(context).textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppTheme.colors(context).textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded, color: AppTheme.colors(context).primary),
            tooltip: 'Mark all as read',
            onPressed: () async {
              final repository = ref.read(notificationsRepositoryProvider);
              final currentProfile = ref.read(notificationsProvider).value?.firstOrNull?.profileId;
              if (currentProfile != null) {
                await repository.markAllAsRead(currentProfile);
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppTheme.colors(context).primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading notifications:\n$err',
            style: TextStyle(color: AppTheme.colors(context).danger),
            textAlign: TextAlign.center,
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: AppTheme.colors(context).textTertiary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colors(context).textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(
                      color: AppTheme.colors(context).textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final NotificationModel notification;

  IconData _getIconForType(String type) {
    switch (type) {
      case 'repayment_due':
      case 'repayment_reminder':
        return Icons.calendar_month_rounded;
      case 'payment_received':
        return Icons.account_balance_wallet_rounded;
      case 'loan_request':
        return Icons.request_quote_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(BuildContext context, String type) {
    switch (type) {
      case 'repayment_due':
      case 'repayment_reminder':
        return AppTheme.colors(context).warning;
      case 'payment_received':
        return AppTheme.colors(context).success;
      case 'loan_request':
        return AppTheme.colors(context).primary;
      default:
        return AppTheme.colors(context).primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = !notification.isRead;
    final timeStr = notification.createdAt != null 
        ? timeago.format(notification.createdAt!) 
        : '';
        
    final iconColor = _getColorForType(context, notification.type);
    final bgColor = isUnread 
        ? (isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.colors(context).primary.withValues(alpha: 0.05))
        : Colors.transparent;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          if (isUnread) {
            ref.read(notificationsRepositoryProvider).markAsRead(notification.id);
          }
          // Handle navigation based on notification type and data (like loanId)
          // For now, it just marks as read
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUnread 
                      ? iconColor.withValues(alpha: 0.15)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getIconForType(notification.type),
                    color: isUnread ? iconColor : AppTheme.colors(context).textSecondary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppTheme.colors(context).textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.colors(context).primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUnread 
                            ? AppTheme.colors(context).textSecondary
                            : AppTheme.colors(context).textTertiary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.colors(context).textTertiary,
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
