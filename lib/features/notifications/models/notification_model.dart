class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.profileId,
    this.loanId,
    required this.title,
    required this.body,
    required this.type,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String profileId;
  final String? loanId;
  final String title;
  final String body;
  final String type;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      loanId: json['loan_id'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }
}
