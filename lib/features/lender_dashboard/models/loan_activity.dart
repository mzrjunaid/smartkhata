/// The type of loan activity event shown in the recent-activity feed.
enum ActivityType {
  disbursed,
  repaymentPending,
  repaymentConfirmed,
  repaymentRejected,
  repaymentMissed,
  overdue,
}

/// A single item in the lender's recent activity feed.
class LoanActivity {
  const LoanActivity({
    required this.id,
    required this.borrowerName,
    required this.type,
    required this.amount,
    required this.date,
  });

  final String id;
  final String borrowerName;
  final ActivityType type;
  final double amount;
  final DateTime date;

  factory LoanActivity.fromJson(Map<String, dynamic> json) {
    // Determine type based on table or status (this is simplified, actual logic
    // depends on the exact query structure used in the repository).
    final typeStr = json['type'] as String? ?? 'repaymentConfirmed';
    final amount = num.tryParse(json['amount']?.toString() ?? '0')?.toDouble() ?? 0.0;
    
    // Nested borrower name from connections -> profiles
    String borrowerName = 'Unknown';
    if (json['borrower_name'] != null) {
      borrowerName = json['borrower_name'] as String;
    } else if (json['connections'] != null) {
      final conn = json['connections'] as Map<String, dynamic>?;
      if (conn != null && conn['profiles'] != null) {
        borrowerName = (conn['profiles'] as Map<String, dynamic>)['full_name'] as String? ?? 'Unknown';
      }
    }

    return LoanActivity(
      id: json['id'] as String,
      borrowerName: borrowerName,
      type: ActivityType.values.byName(typeStr),
      amount: amount,
      date: DateTime.parse(json['date'] as String? ?? json['created_at'] as String),
    );
  }
}
