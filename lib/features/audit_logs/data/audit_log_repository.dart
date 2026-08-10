import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/audit_log_model.dart';

class AuditLogRepository {
  AuditLogRepository(this._client);
  final SupabaseClient _client;

  Future<List<AuditLogModel>> fetchLenderAuditLogs(String lenderProfileId) async {
    final response = await _client
        .from('audit_log')
        .select('''
          *,
          profiles(full_name),
          loans!inner(
            connections!inner(lender_profile_id)
          )
        ''')
        .eq('loans.connections.lender_profile_id', lenderProfileId)
        .order('created_at', ascending: false);
        
    final logs = <AuditLogModel>[];
    
    for (final row in (response as List)) {
      // In case the foreign key for profiles is different, fallback mapping
      final actor = row['profiles'] as Map<String, dynamic>?;
      if (actor != null) {
        row['profiles'] = actor;
      }
      
      logs.add(AuditLogModel.fromJson(row as Map<String, dynamic>));
    }
    
    return logs;
  }
}
