/// A single reminder item representing a repayment that needs attention.
class ReminderItem {
  const ReminderItem({
    required this.repaymentId,
    required this.loanId,
    required this.borrowerName,
    required this.borrowerPhone,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  final String repaymentId;
  final String loanId;
  final String borrowerName;
  final String? borrowerPhone;
  final double amount;
  final DateTime? dueDate;
  final String status; // 'pending', 'rejected', 'missed'
}
