import '../../new_loan/models/loan_model.dart';

/// Represents a connection from the borrower's perspective.
/// Shows lender info instead of borrower info.
class BorrowerConnectionModel {
  const BorrowerConnectionModel({
    required this.connectionId,
    this.lenderProfileId,
    required this.lenderName,
    this.lenderPhone,
    this.lenderEmail,
    required this.status,
    this.hasPendingInvitation = false,
    this.loans = const [],
  });

  final String connectionId;
  final String? lenderProfileId;
  final String lenderName;
  final String? lenderPhone;
  final String? lenderEmail;
  final String status;
  final bool hasPendingInvitation;
  final List<LoanModel> loans;

  factory BorrowerConnectionModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    final loansData = json['loans'] as List<dynamic>?;
    final loans = loansData != null
        ? loansData.map((e) => LoanModel.fromJson(e as Map<String, dynamic>)).toList()
        : <LoanModel>[];

    return BorrowerConnectionModel(
      connectionId: json['id'] as String? ?? '',
      lenderProfileId: json['lender_profile_id'] as String? ?? json['invited_by'] as String?,
      status: json['status'] as String? ?? 'active',
      lenderName: profile?['full_name'] as String? ?? 'Unknown',
      lenderPhone: profile?['phone'] as String?,
      lenderEmail: profile?['email'] as String?,
      hasPendingInvitation: json['hasPendingInvitation'] as bool? ?? false,
      loans: loans,
    );
  }
}
