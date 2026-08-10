// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Loan _$LoanFromJson(Map<String, dynamic> json) => _Loan(
  id: json['id'] as String,
  connectionId: json['connectionId'] as String,
  principalAmount: (json['principalAmount'] as num).toDouble(),
);

Map<String, dynamic> _$LoanToJson(_Loan instance) => <String, dynamic>{
  'id': instance.id,
  'connectionId': instance.connectionId,
  'principalAmount': instance.principalAmount,
};
