import '../../new_loan/models/loan_model.dart';

/// Represents a connection from the borrower's perspective.
/// Shows lender info instead of borrower info.
class BorrowerConnectionModel {
  const BorrowerConnectionModel({
    required this.connectionId,
    required this.lenderName,
    this.lenderPhone,
    this.lenderEmail,
    required this.status,
    this.loans = const [],
  });

  final String connectionId;
  final String lenderName;
  final String? lenderPhone;
  final String? lenderEmail;
  final String status;
  final List<LoanModel> loans;

  factory BorrowerConnectionModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    final loansData = json['loans'] as List<dynamic>?;
    final loans = loansData != null
        ? loansData.map((e) => LoanModel.fromJson(e as Map<String, dynamic>)).toList()
        : <LoanModel>[];

    return BorrowerConnectionModel(
      connectionId: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      lenderName: profile?['full_name'] as String? ?? 'Unknown',
      lenderPhone: profile?['phone'] as String?,
      lenderEmail: profile?['email'] as String?,
      loans: loans,
    );
  }
}
