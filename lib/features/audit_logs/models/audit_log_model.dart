import 'dart:convert';

class AuditLogModel {
  const AuditLogModel({
    required this.id,
    required this.actorProfileId,
    required this.loanId,
    required this.action,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
    this.actorName,
  });

  final String id;
  final String? actorProfileId;
  final String loanId;
  final String action; // e.g., 'inserted', 'updated', 'deleted'
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final DateTime createdAt;
  
  // Populated via join
  final String? actorName;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parseJsonValue(dynamic val) {
      if (val == null) return null;
      if (val is Map<String, dynamic>) return val;
      if (val is String) {
        try {
          return jsonDecode(val) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    final actor = json['profiles'] as Map<String, dynamic>?;

    return AuditLogModel(
      id: json['id'] as String? ?? json['idx'].toString(),
      actorProfileId: json['actor_profile_id'] as String?,
      loanId: json['loan_id'] as String,
      action: json['action'] as String,
      oldValue: parseJsonValue(json['old_value']),
      newValue: parseJsonValue(json['new_value']),
      createdAt: DateTime.parse(json['created_at'] as String),
      actorName: actor?['full_name'] as String?,
    );
  }

  /// Extracts the differences into a human readable format
  List<String> getChanges() {
    final changes = <String>[];
    
    if (action == 'inserted') {
      return ['Record created'];
    }
    
    if (action == 'deleted') {
      return ['Record deleted'];
    }

    if (oldValue == null || newValue == null) {
      return ['Record updated'];
    }

    // Compare keys in newValue to oldValue
    for (final key in newValue!.keys) {
      // Ignore timestamp updates as they are noisy
      if (key == 'updated_at' || key == 'created_at') continue;

      final oldVal = oldValue![key];
      final newVal = newValue![key];

      if (oldVal != newVal) {
        final formattedOld = oldVal?.toString() ?? 'empty';
        final formattedNew = newVal?.toString() ?? 'empty';
        changes.add('$key changed from $formattedOld to $formattedNew');
      }
    }
    
    if (changes.isEmpty) {
      return ['Record updated'];
    }

    return changes;
  }
}
