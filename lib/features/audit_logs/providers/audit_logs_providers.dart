import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/profile_providers.dart';
import '../models/audit_log_model.dart';
import '../data/audit_log_repository.dart';

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(Supabase.instance.client);
});

final auditLogsProvider = FutureProvider<List<AuditLogModel>>((ref) async {
  final profileId = await ref.watch(currentProfileIdProvider.future);
  return ref.read(auditLogRepositoryProvider).fetchLenderAuditLogs(profileId);
});
