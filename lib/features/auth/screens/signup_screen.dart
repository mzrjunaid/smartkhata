import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/auth_providers.dart';
import 'package:smartkhata/core/theme/app_theme.dart';

enum SignupCategory { lender, borrower }

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormBuilderState>();
  final _cnicFormatter = MaskTextInputFormatter(mask: '#####-#######-#');
  final _phoneFormatter = MaskTextInputFormatter(mask: '####-#######');

  SignupCategory _category = SignupCategory.lender;

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  // Borrower specific state
  bool _invitationVerified = false;
  String? _verifiedCnic;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verifyCnic() async {
    final fields = _formKey.currentState;
    if (fields == null) return;

    fields.save();
    final cnicField = fields.fields['cnic'];
    if (cnicField == null || !cnicField.validate()) return;

    final cnic = cnicField.value as String;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final profile = await repo.verifyInvitation(cnic.replaceAll('-', ''));

      if (profile == null) {
        setState(() {
          _error =
              'No pending invitation found for this CNIC. Please ask your lender to invite you first.';
        });
        return;
      }

      // Pre-fill fields and unlock the rest of the form
      setState(() {
        _invitationVerified = true;
        _verifiedCnic = cnic;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.patchValue({
          'full_name': profile['full_name'],
          'phone': profile['phone'],
        });
      });
    } catch (e) {
      setState(() => _error = 'Error verifying CNIC: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final v = _formKey.currentState!.value;

    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: v['email'],
            password: v['password'],
            fullName: v['full_name'],
            cnic:
                (_category == SignupCategory.borrower
                        ? _verifiedCnic!
                        : v['cnic'])
                    .replaceAll('-', ''),
            phone: (v['phone'] as String?)?.isNotEmpty == true
                ? (v['phone'] as String).replaceAll('-', '')
                : null,
          );
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(
        () => _error = 'An unexpected error occurred. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetBorrowerFlow() {
    setState(() {
      _invitationVerified = false;
      _verifiedCnic = null;
      _error = null;
    });
    _formKey.currentState?.reset();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTheme.colors(context).textSecondary),
      prefixIcon: Icon(icon, color: AppTheme.colors(context).primary),
      filled: true,
      fillColor: AppTheme.colors(context).surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.colors(context).primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBorrower = _category == SignupCategory.borrower;
    final showFullForm = !isBorrower || _invitationVerified;

    return Scaffold(
      backgroundColor: AppTheme.colors(context).surface,
      body: Stack(
        children: [
          // Background abstract shapes
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.colors(context).primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.colors(context).accent.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.colors(context).textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Join SmartKhata today',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.colors(context).textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Category Toggle
                        Center(
                          child: SegmentedButton<SignupCategory>(
                            segments: const [
                              ButtonSegment(
                                value: SignupCategory.lender,
                                label: Text('Lender'),
                                icon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                              ),
                              ButtonSegment(
                                value: SignupCategory.borrower,
                                label: Text('Borrower'),
                                icon: Icon(Icons.person_outline),
                              ),
                            ],
                            selected: {_category},
                            onSelectionChanged:
                                (Set<SignupCategory> newSelection) {
                                  setState(() {
                                    _category = newSelection.first;
                                    _error = null;
                                  });
                                },
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppTheme.colors(context).primary.withValues(
                                        alpha: 0.1,
                                      );
                                    }
                                    return AppTheme.colors(context).surface;
                                  }),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppTheme.colors(context).primary;
                                    }
                                    return AppTheme.colors(context).textSecondary;
                                  }),
                            ),
                          ),
                        ),
                        SizedBox(height: 32),

                        // Form Card
                        Container(
                          padding: EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppTheme.colors(context).cardBackground,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.colors(context).textPrimary.withValues(alpha: 0.04),
                                blurRadius: 24,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: FormBuilder(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // CNIC Field
                                FormBuilderTextField(
                                  name: 'cnic',
                                  initialValue: _verifiedCnic,
                                  decoration:
                                      _buildInputDecoration(
                                        'CNIC',
                                        Icons.badge_outlined,
                                      ).copyWith(
                                        hintText: '12345-1234567-1',
                                        suffixIcon:
                                            isBorrower && _invitationVerified
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                  color: AppTheme.colors(context).primary,
                                                ),
                                                onPressed: _resetBorrowerFlow,
                                                tooltip: 'Change CNIC',
                                              )
                                            : null,
                                      ),
                                  readOnly: isBorrower && _invitationVerified,
                                  inputFormatters: [_cnicFormatter],
                                  keyboardType: TextInputType.number,
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(),
                                    FormBuilderValidators.equalLength(15),
                                  ]),
                                ),

                                // Verify button for borrower flow
                                if (isBorrower && !_invitationVerified) ...[
                                  SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _loading ? null : _verifyCnic,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.colors(context).accent,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: _loading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            Icons.verified_user_outlined,
                                          ),
                                    label: Text(
                                      'Verify Invitation',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],

                                // Full Form
                                if (showFullForm) ...[
                                  SizedBox(height: 20),
                                  FormBuilderTextField(
                                    name: 'full_name',
                                    decoration: _buildInputDecoration(
                                      'Full Name',
                                      Icons.person_outline,
                                    ),
                                    validator: FormBuilderValidators.required(),
                                  ),
                                  SizedBox(height: 20),
                                  FormBuilderTextField(
                                    name: 'phone',
                                    decoration: _buildInputDecoration(
                                      'Phone (optional)',
                                      Icons.phone_outlined,
                                    ).copyWith(hintText: '03XX-XXXXXXX'),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [_phoneFormatter],
                                  ),
                                  SizedBox(height: 20),
                                  FormBuilderTextField(
                                    name: 'email',
                                    decoration: _buildInputDecoration(
                                      'Email',
                                      Icons.email_outlined,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.email(),
                                    ]),
                                  ),
                                  SizedBox(height: 20),
                                  FormBuilderTextField(
                                    name: 'password',
                                    decoration:
                                        _buildInputDecoration(
                                          'Password',
                                          Icons.lock_outline,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color:
                                                  AppTheme.colors(context).textTertiary,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                    obscureText: _obscurePassword,
                                    validator: FormBuilderValidators.minLength(
                                      6,
                                    ),
                                  ),
                                  SizedBox(height: 32),

                                  if (_error != null)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.colors(context).dangerSurface,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: AppTheme.colors(context).danger,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: TextStyle(
                                                  color: AppTheme.colors(context).danger,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  ElevatedButton(
                                    onPressed: _loading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.colors(context).primary,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child:
                                        _loading &&
                                            (!isBorrower || _invitationVerified)
                                        ? SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : Text(
                                            'Complete Sign Up',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account?",
                              style: TextStyle(
                                color: AppTheme.colors(context).textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: AppTheme.colors(context).primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
