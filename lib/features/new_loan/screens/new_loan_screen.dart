import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../lender_dashboard/providers/dashboard_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../models/new_loan_form_data.dart';
import '../providers/new_loan_providers.dart';
import '../services/new_loan_service.dart';
import '../widgets/loan_form_header.dart';
import '../widgets/loan_summary_preview.dart';
import '../widgets/styled_form_field.dart';

enum _BorrowerFlow { existing, newBorrower }

/// New loan creation screen.
class NewLoanScreen extends ConsumerStatefulWidget {
  const NewLoanScreen({super.key});

  @override
  ConsumerState<NewLoanScreen> createState() => _NewLoanScreenState();
}

class _NewLoanScreenState extends ConsumerState<NewLoanScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _cnicFormatter = MaskTextInputFormatter(mask: '#####-#######-#');

  bool _loading = false;
  String? _error;
  _BorrowerFlow _flow = _BorrowerFlow.existing;

  // ── Live preview state ─────────────────────────────────────────────
  double _principal = 0;
  double _rate = 0;
  int _months = 0;
  String _interestType = 'none';

  // ── Submit ─────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final v = _formKey.currentState!.value;
    final service = ref.read(newLoanServiceProvider);

    try {
      String connectionId;

      if (_flow == _BorrowerFlow.newBorrower) {
        // 1. Create borrower & connection
        connectionId = await service.inviteBorrower(
          fullName: v['borrower_name'] as String,
          cnic: (v['borrower_cnic'] as String).replaceAll('-', ''),
          phone: (v['borrower_phone'] as String?)?.isNotEmpty == true
              ? v['borrower_phone'] as String
              : null,
          nickname: (v['borrower_nickname'] as String?)?.isNotEmpty == true
              ? v['borrower_nickname'] as String
              : null,
        );
      } else {
        // 2. Use existing connection
        connectionId = v['connection_id'] as String;
      }

      // 3. Create Loan
      final formData = NewLoanFormData(
        connectionId: connectionId,
        principalAmount: double.parse(v['principal_amount'] as String),
        currencyCode: 'PKR',
        interestRate: double.parse(v['interest_rate']?.toString() ?? '0'),
        interestType: v['interest_type'] as String,
        disbursedAt: v['disbursed_at'] as DateTime?,
        dueDate: v['due_date'] as DateTime?,
        notes: (v['notes'] as String?)?.isNotEmpty == true
            ? v['notes'] as String
            : null,
      );

      await service.submitLoan(formData);

      // Invalidate dashboard and connections
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(recentActivityProvider);
      ref.invalidate(lenderConnectionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loan created successfully!'),
            backgroundColor: AppTheme.colors(context).success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.radiusSm,
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  void _updatePreview() {
    final fields = _formKey.currentState;
    if (fields == null) return;

    fields.save();
    final principalStr = fields.fields['principal_amount']?.value as String?;
    final rateStr = fields.fields['interest_rate']?.value as String?;
    final disbursedAt = fields.fields['disbursed_at']?.value as DateTime?;
    final dueDate = fields.fields['due_date']?.value as DateTime?;
    final interestType = fields.fields['interest_type']?.value as String? ?? 'none';

    int calculatedMonths = 0;
    if (disbursedAt != null && dueDate != null) {
      final days = dueDate.difference(disbursedAt).inDays;
      calculatedMonths = (days / 30).round();
    }

    setState(() {
      _principal = double.tryParse(principalStr ?? '') ?? 0;
      _rate = double.tryParse(rateStr ?? '') ?? 0;
      _months = calculatedMonths;
      _interestType = interestType;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(newLoanServiceProvider);
    final connectionsAsync = ref.watch(lenderConnectionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.colors(context).cardBackground,
      body: SingleChildScrollView(
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────
              const LoanFormHeader(),
              const SizedBox(height: AppTheme.spacingXl),

              // ── Borrower Flow Selector ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: SegmentedButton<_BorrowerFlow>(
                  segments: const [
                    ButtonSegment(
                      value: _BorrowerFlow.existing,
                      label: Text('Existing Borrower'),
                      icon: Icon(Icons.people_outline),
                    ),
                    ButtonSegment(
                      value: _BorrowerFlow.newBorrower,
                      label: Text('New Borrower'),
                      icon: Icon(Icons.person_add_outlined),
                    ),
                  ],
                  selected: {_flow},
                  onSelectionChanged: (Set<_BorrowerFlow> newSelection) {
                    setState(() {
                      _flow = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // ── Borrower Details Section ──────────────────────────
              _SectionTitle(
                icon: Icons.person_outline,
                title: 'Borrower Details',
              ),
              const SizedBox(height: AppTheme.spacingMd),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: _flow == _BorrowerFlow.existing
                    ? connectionsAsync.when(
                        data: (connections) {
                          if (connections.isEmpty) {
                            return Container(
                              padding: EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                color: AppTheme.colors(context).primarySurface,
                                borderRadius: AppTheme.radiusMd,
                              ),
                              child: Text(
                                'No active connections found. Please select "New Borrower" to invite someone.',
                                style: AppTheme.text(context).bodyMedium.copyWith(color: AppTheme.colors(context).primary),
                              ),
                            );
                          }
                          return FormBuilderDropdown<String>(
                            name: 'connection_id',
                            decoration: InputDecoration(
                              labelText: 'Select Borrower',
                              filled: true,
                              fillColor: AppTheme.colors(context).surface,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.radiusMd,
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: FormBuilderValidators.required(),
                            items: connections.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.borrowerName} (${c.borrowerCnic})'),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => Center(child: CircularProgressIndicator()),
                        error: (e, st) => Text('Error loading connections: $e'),
                      )
                    : Column(
                        children: [
                          StyledFormField(
                            name: 'borrower_name',
                            label: 'Full Name',
                            hint: 'Enter borrower\'s full name',
                            prefixIcon: Icons.person_outline,
                            validator: FormBuilderValidators.required(),
                          ),
                          StyledFormField(
                            name: 'borrower_cnic',
                            label: 'CNIC',
                            hint: '12345-1234567-1',
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [_cnicFormatter],
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.equalLength(15),
                            ]),
                          ),
                          StyledFormField(
                            name: 'borrower_phone',
                            label: 'Phone (optional)',
                            hint: '03XX-XXXXXXX',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          StyledFormField(
                            name: 'borrower_nickname',
                            label: 'Nickname (optional)',
                            hint: 'e.g. Work Colleague',
                            prefixIcon: Icons.label_outline,
                          ),
                        ],
                      ),
              ),

              SizedBox(height: AppTheme.spacingLg),

              // ── Loan Details Section ──────────────────────────────
              _SectionTitle(
                icon: Icons.account_balance_outlined,
                title: 'Loan Details',
              ),
              SizedBox(height: AppTheme.spacingMd),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: Column(
                  children: [
                    StyledFormField(
                      name: 'principal_amount',
                      label: 'Principal Amount',
                      hint: 'e.g. 100000',
                      prefixText: '₨  ',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _updatePreview(),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.min(NewLoanService.minPrincipal),
                        FormBuilderValidators.max(NewLoanService.maxPrincipal),
                      ]),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: FormBuilderDropdown<String>(
                            name: 'interest_type',
                            initialValue: 'none',
                            decoration: InputDecoration(
                              labelText: 'Interest Type',
                              filled: true,
                              fillColor: AppTheme.colors(context).surface,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.radiusMd,
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => _updatePreview(),
                            items: [
                              DropdownMenuItem(value: 'none', child: Text('No Interest')),
                              DropdownMenuItem(value: 'flat', child: Text('Flat Rate')),
                              DropdownMenuItem(value: 'reducing', child: Text('Reducing Balance')),
                            ],
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          flex: 1,
                          child: StyledFormField(
                            name: 'interest_rate',
                            label: 'Rate',
                            hint: '12',
                            suffixText: '%',
                            enabled: _interestType != 'none',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => _updatePreview(),
                            validator: _interestType == 'none'
                                ? null
                                : FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.numeric(),
                                    FormBuilderValidators.min(NewLoanService.minInterestRate),
                                    FormBuilderValidators.max(NewLoanService.maxInterestRate),
                                  ]),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderDateTimePicker(
                            name: 'disbursed_at',
                            initialValue: DateTime.now(),
                            inputType: InputType.date,
                            format: DateFormat('dd MMM yyyy'),
                            decoration: InputDecoration(
                              labelText: 'Disbursed Date',
                              filled: true,
                              fillColor: AppTheme.colors(context).surface,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.radiusMd,
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => _updatePreview(),
                          ),
                        ),
                        SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: FormBuilderDateTimePicker(
                            name: 'due_date',
                            inputType: InputType.date,
                            format: DateFormat('dd MMM yyyy'),
                            decoration: InputDecoration(
                              labelText: 'Due Date',
                              filled: true,
                              fillColor: AppTheme.colors(context).surface,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.radiusMd,
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => _updatePreview(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppTheme.spacingXl),

              // ── Live Summary Preview ──────────────────────────────
              LoanSummaryPreview(
                principal: _principal,
                annualRate: _rate,
                months: _months,
                interestType: _interestType,
                service: service,
              ),

              SizedBox(height: AppTheme.spacingXl),

              // ── Notes Section ─────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: StyledFormField(
                  name: 'notes',
                  label: 'Notes (optional)',
                  hint: 'Any additional remarks...',
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 3,
                ),
              ),

              // ── Error message ─────────────────────────────────────
              if (_error != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.colors(context).dangerSurface,
                      borderRadius: AppTheme.radiusSm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppTheme.colors(context).danger,
                          size: 18,
                        ),
                        SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: AppTheme.text(context).bodyMedium.copyWith(color: AppTheme.colors(context).danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: AppTheme.spacingXl),

              // ── Submit Button ─────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colors(context).primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.colors(context).primary.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radiusMd,
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text('Create Loan'),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.colors(context).primarySurface,
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(icon, size: 16, color: AppTheme.colors(context).primary),
          ),
          SizedBox(width: AppTheme.spacingSm),
          Text(title, style: AppTheme.text(context).headingMedium),
        ],
      ),
    );
  }
}

