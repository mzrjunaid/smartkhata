class LoanModel {
  const LoanModel({
    required this.id,
    this.createdAt,
    required this.principal,
    required this.currency,
    required this.interestRate,
    required this.interestType,
    required this.totalAmount,
    this.disbursedAt,
    this.dueDate,
    this.status,
  });

  final String id;
  final DateTime? createdAt;
  final double principal;
  final String currency;
  final double interestRate;
  final String interestType;
  final double totalAmount;
  final DateTime? disbursedAt;
  final DateTime? dueDate;
  final String? status;

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'] as String) 
          : null,
      principal: (json['principal_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'PKR',
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      interestType: json['interest_type'] as String? ?? 'none',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      disbursedAt: json['disbursed_at'] != null
          ? DateTime.tryParse(json['disbursed_at'] as String)
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      status: json['status'] as String?,
    );
  }
}
