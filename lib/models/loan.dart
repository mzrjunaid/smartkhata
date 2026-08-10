import 'package:freezed_annotation/freezed_annotation.dart';

part 'loan.freezed.dart';
part 'loan.g.dart';

@freezed
abstract class Loan with _$Loan {
  const factory Loan({
    required String id,
    required String connectionId,
    required double principalAmount,
  }) = _Loan;

  factory Loan.fromJson(Map<String, dynamic> json) => _$LoanFromJson(json);
}
