import 'dart:math' as math;
import 'package:intl/intl.dart';

import '../data/new_loan_repository.dart';
import '../models/new_loan_form_data.dart';

/// Business logic layer for new loan creation.
///
/// Handles validation rules, financial calculations (flat vs reducing), and delegates
/// persistence to [NewLoanRepository].
class NewLoanService {
  NewLoanService(this._repository);

  final NewLoanRepository _repository;

  // ── Constants ────────────────────────────────────────────────────────

  static const double minPrincipal = 1000;
  static const double maxPrincipal = 10000000;
  static const double minInterestRate = 0;
  static const double maxInterestRate = 50;

  // ── Currency Formatting ──────────────────────────────────────────────

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_PK',
    symbol: '₨ ',
    decimalDigits: 0,
  );

  /// Formats [amount] as ₨ 1,250,000.
  String formatCurrency(double amount) => _currencyFormat.format(amount);

  // ── Financial Calculations ───────────────────────────────────────────

  /// Calculates the monthly installment.
  double calculateMonthlyInstallment({
    required double principal,
    required double annualRate,
    required int months,
    required String interestType,
  }) {
    if (months <= 0) return 0;
    if (interestType == 'none' || annualRate <= 0) {
      return principal / months;
    }
    
    if (interestType == 'flat') {
      final totalInterest = calculateTotalInterest(
        principal: principal,
        annualRate: annualRate,
        months: months,
        interestType: interestType,
      );
      return (principal + totalInterest) / months;
    } 
    
    // Reducing balance (EMI formula)
    final monthlyRate = annualRate / 100 / 12;
    return (principal * monthlyRate * math.pow(1 + monthlyRate, months)) /
        (math.pow(1 + monthlyRate, months) - 1);
  }

  /// Total interest over the full loan duration.
  double calculateTotalInterest({
    required double principal,
    required double annualRate,
    required int months,
    required String interestType,
  }) {
    if (months <= 0 || interestType == 'none' || annualRate <= 0) return 0;

    if (interestType == 'flat') {
      final monthlyRate = annualRate / 100 / 12;
      return principal * monthlyRate * months;
    }

    // Reducing balance
    final emi = calculateMonthlyInstallment(
      principal: principal,
      annualRate: annualRate,
      months: months,
      interestType: interestType,
    );
    return (emi * months) - principal;
  }

  /// Total amount repayable = principal + total interest.
  double calculateTotalRepayable({
    required double principal,
    required double annualRate,
    required int months,
    required String interestType,
  }) {
    return principal +
        calculateTotalInterest(
          principal: principal,
          annualRate: annualRate,
          months: months,
          interestType: interestType,
        );
  }

  // ── Persistence ──────────────────────────────────────────────────────

  /// Invites a new borrower (or reuses one based on CNIC) and creates a connection.
  Future<String> inviteBorrower({
    required String fullName,
    required String cnic,
    String? phone,
    String? nickname,
  }) async {
    return _repository.inviteBorrower(
      fullName: fullName,
      cnic: cnic,
      phone: phone,
      nickname: nickname,
    );
  }

  /// Validates the form data and creates the loan.
  ///
  /// Returns the created loan ID on success.
  /// Throws [ArgumentError] for invalid business rules.
  Future<String> submitLoan(NewLoanFormData data) async {
    // Business-rule validation
    if (data.principalAmount < minPrincipal) {
      throw ArgumentError(
        'Minimum loan amount is ${formatCurrency(minPrincipal)}',
      );
    }
    if (data.principalAmount > maxPrincipal) {
      throw ArgumentError(
        'Maximum loan amount is ${formatCurrency(maxPrincipal)}',
      );
    }
    if (data.interestRate < minInterestRate ||
        data.interestRate > maxInterestRate) {
      throw ArgumentError(
        'Interest rate must be between $minInterestRate% and $maxInterestRate%',
      );
    }

    return _repository.createLoan(data);
  }

  /// Validates the form data and creates the loan along with the invitation in a single transaction.
  Future<String> inviteAndCreateLoan({
    required String fullName,
    required String cnic,
    String? phone,
    String? nickname,
    required NewLoanFormData data,
  }) async {
    // Business-rule validation
    if (data.principalAmount < minPrincipal) {
      throw ArgumentError(
        'Minimum loan amount is ${formatCurrency(minPrincipal)}',
      );
    }
    if (data.principalAmount > maxPrincipal) {
      throw ArgumentError(
        'Maximum loan amount is ${formatCurrency(maxPrincipal)}',
      );
    }
    if (data.interestRate < minInterestRate ||
        data.interestRate > maxInterestRate) {
      throw ArgumentError(
        'Interest rate must be between $minInterestRate% and $maxInterestRate%',
      );
    }

    return _repository.inviteAndCreateLoan(
      fullName: fullName,
      cnic: cnic,
      phone: phone,
      nickname: nickname,
      data: data,
    );
  }
}

