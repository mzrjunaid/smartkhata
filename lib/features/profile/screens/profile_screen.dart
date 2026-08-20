import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/profile_providers.dart';
import '../../../core/widgets/dashboard_app_bar.dart';
import 'package:smartkhata/core/theme/app_theme.dart';

/// Fetches the full editable profile for the current user.
final _fullProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Not authenticated');

  return await supabase
      .from('profiles')
      .select('id, full_name, cnic, phone, email, claim_status, created_at')
      .eq('auth_user_id', user.id)
      .single();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.initialEditMode = false});
  final bool initialEditMode;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialEditMode;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEditMode != oldWidget.initialEditMode && widget.initialEditMode) {
      setState(() {
        _isEditing = true;
      });
    }
  }

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  String _cnic = '';
  String _claimStatus = '';
  DateTime? _createdAt;
  String? _profileId;

  bool _initialized = false;

  void _initControllers(Map<String, dynamic> profile) {
    if (_initialized) return;
    _nameController = TextEditingController(
      text: profile['full_name'] as String? ?? '',
    );
    _phoneController = TextEditingController(
      text: profile['phone'] as String? ?? '',
    );
    _emailController = TextEditingController(
      text: profile['email'] as String? ?? '',
    );
    _cnic = profile['cnic'] as String? ?? '';
    _claimStatus = profile['claim_status'] as String? ?? '';
    _profileId = profile['id'] as String? ?? '';
    _createdAt = profile['created_at'] != null
        ? DateTime.tryParse(profile['created_at'] as String)
        : null;
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _phoneController.dispose();
      _emailController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': _nameController.text.trim(),
            'phone': _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            'email': _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          })
          .eq('id', _profileId!);

      // Sync display name to Supabase Auth user metadata
      final name = _nameController.text.trim();
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'full_name': name, 'display_name': name}),
      );

      ref.invalidate(_fullProfileProvider);
      ref.invalidate(currentProfileProvider);

      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppTheme.colors(context).success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: AppTheme.colors(context).danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_fullProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          const DashboardAppBar(
            title: 'My Profile',
            subtitle: 'Manage your personal details',
            showBackButton: false,
          ),
          Expanded(
            child: profileAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppTheme.colors(context).primary),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: TextStyle(color: AppTheme.colors(context).danger),
                ),
              ),
              data: (profile) {
                _initControllers(profile);
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // ── Avatar header card ──
                        _buildAvatarCard(context),
                        const SizedBox(height: 24),

                        // ── Info card ──
                        _buildInfoCard(context),
                        const SizedBox(height: 24),

                        // ── Account details ──
                        _buildAccountCard(context),
                        const SizedBox(height: 24),

                        // ── Action buttons ──
                        _buildActions(context),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar & Name Header ──────────────────────────────────────────────

  Widget _buildAvatarCard(BuildContext context) {
    final name = _nameController.text.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name.isNotEmpty ? name : 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          if (_cnic.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'CNIC: $_cnic',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Editable Personal Info ────────────────────────────────────────────

  Widget _buildInfoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppTheme.colors(context).textPrimary,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (_isEditing) {
                      // Revert changes
                      ref.invalidate(_fullProfileProvider);
                      _initialized = false;
                    }
                    setState(() => _isEditing = !_isEditing);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isEditing 
                          ? AppTheme.colors(context).danger.withValues(alpha: 0.1)
                          : AppTheme.colors(context).primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                      color: _isEditing 
                          ? AppTheme.colors(context).danger 
                          : AppTheme.colors(context).primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Full Name
          _buildField(
            label: 'Full Name',
            icon: Icons.person_rounded,
            controller: _nameController,
            enabled: _isEditing,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),

          // CNIC (read-only always)
          _buildReadOnlyField(context, 
            label: 'CNIC',
            icon: Icons.badge_rounded,
            value: _cnic.isNotEmpty ? _cnic : '—',
            helperText: 'CNIC can only be updated by your lender',
          ),
          const SizedBox(height: 16),

          // Phone
          _buildField(
            label: 'Phone Number',
            icon: Icons.phone_iphone_rounded,
            controller: _phoneController,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
            ],
          ),
          const SizedBox(height: 16),

          // Email
          _buildField(
            label: 'Email',
            icon: Icons.email_rounded,
            controller: _emailController,
            enabled: _isEditing,
            keyboardType: TextInputType.emailAddress,
          ),

          // Save button when editing
          if (_isEditing) ...[
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.colors(context).primary,
                    AppTheme.colors(context).accent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.colors(context).primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSaving ? null : _saveProfile,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Account Details (read-only) ───────────────────────────────────────

  Widget _buildAccountCard(BuildContext context) {
    final displayClaim = _claimStatus.isNotEmpty
        ? '${_claimStatus[0].toUpperCase()}${_claimStatus.substring(1)}'
        : '—';
    final joinedDate = _createdAt != null
        ? '${_createdAt!.day}/${_createdAt!.month}/${_createdAt!.year}'
        : '—';
        
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Details', 
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.colors(context).textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow(context, 
            Icons.verified_user_rounded,
            'Claim Status',
            displayClaim,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              height: 1,
            ),
          ),
          _buildDetailRow(context, 
            Icons.event_available_rounded,
            'Member Since',
            joinedDate,
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security', 
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.colors(context).textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionTile(context, 
            icon: Icons.lock_reset_rounded,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () => _showChangePasswordDialog(),
          ),
        ],
      ),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.colors(context).textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: enabled
                ? AppTheme.colors(context).textPrimary
                : AppTheme.colors(context).textSecondary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled 
                ? (isDark ? const Color(0xFF2D2D35) : const Color(0xFFF8F9FA))
                : (isDark ? Colors.black12 : Colors.grey.withValues(alpha: 0.05)),
            prefixIcon: Icon(
              icon,
              color: enabled ? AppTheme.colors(context).primary : AppTheme.colors(context).textTertiary,
              size: 22,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.colors(context).primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
    String? helperText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.colors(context).textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.black12 : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.colors(context).textTertiary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colors(context).textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.lock_rounded,
                size: 18,
                color: AppTheme.colors(context).textTertiary,
              ),
            ],
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: Text(
              helperText,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.colors(context).textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.colors(context).primarySurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.colors(context).primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors(context).textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colors(context).textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.colors(context).warningSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.colors(context).warning, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colors(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.colors(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.colors(context).textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  // ── Change Password Dialog ────────────────────────────────────────────

  void _showChangePasswordDialog() {
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Change Password', 
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.colors(context).textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassController,
                obscureText: true,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors(context).textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPassController,
                obscureText: true,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors(context).textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.colors(context).textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPassController.text.isEmpty ||
                    newPassController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                  return;
                }
                if (newPassController.text != confirmPassController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: newPassController.text),
                  );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Password updated successfully!'),
                        backgroundColor: AppTheme.colors(context).success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.colors(context).danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors(context).primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}
