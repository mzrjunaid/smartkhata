import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/auth_providers.dart';
import '../../lender_dashboard/theme/dashboard_theme.dart';

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
            phone: v['phone'],
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
      labelStyle: const TextStyle(color: DashboardTheme.textSecondary),
      prefixIcon: Icon(icon, color: DashboardTheme.primary),
      filled: true,
      fillColor: DashboardTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: DashboardTheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBorrower = _category == SignupCategory.borrower;
    final showFullForm = !isBorrower || _invitationVerified;

    return Scaffold(
      backgroundColor: DashboardTheme.surface,
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
                color: DashboardTheme.primary.withValues(alpha: 0.08),
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
                color: DashboardTheme.accent.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
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
                        const Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: DashboardTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join SmartKhata today',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: DashboardTheme.textSecondary,
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
                                      return DashboardTheme.primary.withValues(
                                        alpha: 0.1,
                                      );
                                    }
                                    return Colors.white;
                                  }),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return DashboardTheme.primary;
                                    }
                                    return DashboardTheme.textSecondary;
                                  }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
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
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                  color: DashboardTheme.primary,
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
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _loading ? null : _verifyCnic,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DashboardTheme.accent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.verified_user_outlined,
                                          ),
                                    label: const Text(
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
                                  const SizedBox(height: 20),
                                  FormBuilderTextField(
                                    name: 'full_name',
                                    decoration: _buildInputDecoration(
                                      'Full Name',
                                      Icons.person_outline,
                                    ),
                                    validator: FormBuilderValidators.required(),
                                  ),
                                  const SizedBox(height: 20),
                                  FormBuilderTextField(
                                    name: 'phone',
                                    decoration: _buildInputDecoration(
                                      'Phone (optional)',
                                      Icons.phone_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
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
                                  const SizedBox(height: 20),
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
                                                  DashboardTheme.textTertiary,
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
                                  const SizedBox(height: 32),

                                  if (_error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: DashboardTheme.dangerSurface,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: DashboardTheme.danger,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: const TextStyle(
                                                  color: DashboardTheme.danger,
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
                                      backgroundColor: DashboardTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
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
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Text(
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

                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account?",
                              style: TextStyle(
                                color: DashboardTheme.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: DashboardTheme.primary,
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
