class RepaymentModel {
  const RepaymentModel({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.status,
    this.method,
    this.note,
    this.paidDate,
    this.dueDate,
    this.createdAt,
  });

  final String id;
  final String loanId;
  final double amount;
  final String status;
  final String? method;
  final String? note;
  final DateTime? paidDate;
  final DateTime? dueDate;
  final DateTime? createdAt;

  factory RepaymentModel.fromJson(Map<String, dynamic> json) {
    return RepaymentModel(
      id: json['id'] as String? ?? '',
      loanId: json['loan_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      method: json['method'] as String?,
      note: json['note'] as String?,
      paidDate: json['paid_date'] != null
          ? DateTime.tryParse(json['paid_date'] as String)
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
