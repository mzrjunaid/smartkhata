import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../providers/audit_logs_providers.dart';
import 'widgets/audit_log_tile.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      appBar: AppBar(
        backgroundColor: AppTheme.colors(context).primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Audit Logs',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: \$err')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Text(
                'No audit logs found.',
                style: AppTheme.text(context).bodyLarge,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(auditLogsProvider);
              await ref.read(auditLogsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return AuditLogTile(log: logs[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
