/// Immutable data object representing the form submission for creating a new loan.
///
/// Matches the parameters required by the `create_loan` Supabase RPC.
class NewLoanFormData {
  const NewLoanFormData({
    required this.connectionId,
    required this.principalAmount,
    required this.currencyCode,
    required this.interestRate,
    required this.interestType,
    this.disbursedAt,
    this.dueDate,
    this.notes,
  });

  /// The connection ID this loan belongs to.
  final String connectionId;

  /// The loan principal.
  final double principalAmount;

  /// Currency code (e.g., 'PKR').
  final String currencyCode;

  /// Annual interest rate as a percentage.
  final double interestRate;

  /// Type of interest ('none', 'flat', 'reducing').
  final String interestType;

  /// The date the loan starts/was disbursed.
  final DateTime? disbursedAt;

  /// The date the loan is due.
  final DateTime? dueDate;

  /// Optional notes / remarks.
  final String? notes;
}
