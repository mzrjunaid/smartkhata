import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lender_dashboard/theme/dashboard_theme.dart';
import '../providers/audit_logs_providers.dart';
import 'widgets/audit_log_tile.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      backgroundColor: DashboardTheme.surface,
      appBar: AppBar(
        backgroundColor: DashboardTheme.primary,
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
            return const Center(
              child: Text(
                'No audit logs found.',
                style: DashboardTheme.bodyLarge,
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
