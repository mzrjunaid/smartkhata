enum TransactionDirection {
  moneyIn,
  moneyOut,
}

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.counterpartyName,
    required this.direction,
    required this.category,
    required this.status,
    this.notes,
    this.dueDate,
    this.paidDate,
    this.confirmedBy,
  });

  final String id;
  final double amount;
  final DateTime date;
  final String counterpartyName;
  final TransactionDirection direction;
  final String category; // e.g. "Loan Disbursed", "Repayment Received"
  final String status;   // 'pending', 'confirmed', 'rejected', 'missed'
  final String? notes;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String? confirmedBy;
}
