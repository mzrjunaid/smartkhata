import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smartkhata/core/theme/app_theme.dart';
import '../../models/audit_log_model.dart';

class AuditLogTile extends StatelessWidget {
  const AuditLogTile({super.key, required this.log});

  final AuditLogModel log;

  @override
  Widget build(BuildContext context) {
    final changes = log.getChanges();
    final actionColor = _getActionColor(context, log.action);
    final iconData = _getActionIcon(context, log.action);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, size: 16, color: actionColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.actorName ?? 'System',
                      style: AppTheme.text(context).headingSmall,
                    ),
                    Text(
                      DateFormat('MMM d, yyyy - h:mm a').format(log.createdAt),
                      style: AppTheme.text(context).bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: actionColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  log.action.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: actionColor,
                  ),
                ),
              ),
            ],
          ),

          if (changes.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...changes.map(
              (change) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 8),
                      child: Icon(Icons.circle, size: 6, color: Colors.grey),
                    ),
                    Expanded(
                      child: Text(
                        change,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getActionColor(BuildContext context, String action) {
    switch (action.toLowerCase()) {
      case 'inserted':
        return AppTheme.colors(context).success;
      case 'updated':
        return AppTheme.colors(context).primary;
      case 'deleted':
        return AppTheme.colors(context).danger;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(BuildContext context, String action) {
    switch (action.toLowerCase()) {
      case 'inserted':
        return Icons.add;
      case 'updated':
        return Icons.edit;
      case 'deleted':
        return Icons.delete;
      default:
        return Icons.info_outline;
    }
  }
}
