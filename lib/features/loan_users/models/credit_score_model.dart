class CreditScoreModel {
  const CreditScoreModel({
    required this.profileId,
    required this.score,
    required this.totalLoans,
    required this.onTimeCount,
    required this.lateCount,
    required this.defaultCount,
    this.lastCalculatedAt,
  });

  final String profileId;
  final int score;
  final int totalLoans;
  final int onTimeCount;
  final int lateCount;
  final int defaultCount;
  final DateTime? lastCalculatedAt;

  factory CreditScoreModel.fromJson(Map<String, dynamic> json) {
    return CreditScoreModel(
      profileId: json['profile_id'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 500,
      totalLoans: (json['total_loans'] as num?)?.toInt() ?? 0,
      onTimeCount: (json['on_time_count'] as num?)?.toInt() ?? 0,
      lateCount: (json['late_count'] as num?)?.toInt() ?? 0,
      defaultCount: (json['default_count'] as num?)?.toInt() ?? 0,
      lastCalculatedAt: json['last_calculated_at'] != null
          ? DateTime.tryParse(json['last_calculated_at'] as String)
          : null,
    );
  }
}
