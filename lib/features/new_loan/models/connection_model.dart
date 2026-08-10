import 'loan_model.dart';

class ConnectionModel {
  const ConnectionModel({
    required this.id,
    this.borrowerProfileId,
    required this.borrowerName,
    required this.borrowerCnic,
    this.borrowerPhone,
    required this.status,
    required this.claimStatus,
    this.borrowerEmail,
    this.lenderVerifiedAt,
    this.loans = const [],
  });

  final String id;
  final String? borrowerProfileId;
  final String borrowerName;
  final String borrowerCnic;
  final String? borrowerPhone;
  final String status;
  final String claimStatus;
  final String? borrowerEmail;
  final DateTime? lenderVerifiedAt;
  final List<LoanModel> loans;

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    // The profile fields come from a join on `profiles`
    final profile = json['profiles'] as Map<String, dynamic>?;

    final loansData = json['loans'] as List<dynamic>?;
    final loans = loansData != null
        ? loansData.map((e) => LoanModel.fromJson(e as Map<String, dynamic>)).toList()
        : <LoanModel>[];

    return ConnectionModel(
      id: json['id'] as String? ?? '',
      borrowerProfileId: json['borrower_profile_id'] as String?,
      status: json['status'] as String? ?? 'active',
      borrowerName: profile?['full_name'] as String? ?? 'Unknown',
      borrowerCnic: profile?['cnic'] as String? ?? 'Unknown',
      borrowerPhone: profile?['phone'] as String?,
      borrowerEmail: profile?['email'] as String?,
      claimStatus: profile?['claim_status'] as String? ?? 'invited',
      lenderVerifiedAt: json['lender_verified_at'] != null
          ? DateTime.tryParse(json['lender_verified_at'] as String)
          : null,
      loans: loans,
    );
  }
}
