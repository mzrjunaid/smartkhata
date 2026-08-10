import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/profile_providers.dart';
import '../../../core/widgets/dashboard_app_bar.dart';
import '../../lender_dashboard/theme/dashboard_theme.dart';

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
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;

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
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: DashboardTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: DashboardTheme.danger,
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

    return Scaffold(
      backgroundColor: DashboardTheme.surface,
      body: Column(
        children: [
          const DashboardAppBar(title: 'My Profile', showBackButton: false),
          Expanded(
            child: profileAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: DashboardTheme.primary),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: DashboardTheme.danger),
                ),
              ),
              data: (profile) {
                _initControllers(profile);
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(DashboardTheme.spacingLg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // ── Avatar header card ──
                        _buildAvatarCard(),
                        const SizedBox(height: DashboardTheme.spacingXl),

                        // ── Info card ──
                        _buildInfoCard(),
                        const SizedBox(height: DashboardTheme.spacingXl),

                        // ── Account details ──
                        _buildAccountCard(),
                        const SizedBox(height: DashboardTheme.spacingXl),

                        // ── Action buttons ──
                        _buildActions(),
                        const SizedBox(height: 80),
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

  Widget _buildAvatarCard() {
    final name = _nameController.text.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: DashboardTheme.spacingXxl,
        horizontal: DashboardTheme.spacingLg,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DashboardTheme.primary, Color(0xFF2E7D32)],
        ),
        borderRadius: DashboardTheme.radiusLg,
        boxShadow: DashboardTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: DashboardTheme.spacingMd),
          Text(
            name.isNotEmpty ? name : 'User',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (_cnic.isNotEmpty) ...[
            const SizedBox(height: DashboardTheme.spacingSm),
            Text(
              'CNIC: $_cnic',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Editable Personal Info ────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personal Information',
                style: DashboardTheme.headingMedium,
              ),
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.close : Icons.edit_outlined,
                  color: DashboardTheme.primary,
                  size: 22,
                ),
                tooltip: _isEditing ? 'Cancel' : 'Edit',
                onPressed: () {
                  if (_isEditing) {
                    // Revert changes
                    ref.invalidate(_fullProfileProvider);
                    _initialized = false;
                  }
                  setState(() => _isEditing = !_isEditing);
                },
              ),
            ],
          ),
          const SizedBox(height: DashboardTheme.spacingLg),

          // Full Name
          _buildField(
            label: 'Full Name',
            icon: Icons.person_outline,
            controller: _nameController,
            enabled: _isEditing,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: DashboardTheme.spacingMd),

          // CNIC (read-only always)
          _buildReadOnlyField(
            label: 'CNIC',
            icon: Icons.credit_card,
            value: _cnic.isNotEmpty ? _cnic : '—',
            helperText: 'CNIC can only be updated by your lender',
          ),
          const SizedBox(height: DashboardTheme.spacingMd),

          // Phone
          _buildField(
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
            ],
          ),
          const SizedBox(height: DashboardTheme.spacingMd),

          // Email
          _buildField(
            label: 'Email',
            icon: Icons.email_outlined,
            controller: _emailController,
            enabled: _isEditing,
            keyboardType: TextInputType.emailAddress,
          ),

          // Save button when editing
          if (_isEditing) ...[
            const SizedBox(height: DashboardTheme.spacingXl),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

  Widget _buildAccountCard() {
    final displayClaim = _claimStatus.isNotEmpty
        ? '${_claimStatus[0].toUpperCase()}${_claimStatus.substring(1)}'
        : '—';
    final joinedDate = _createdAt != null
        ? '${_createdAt!.day}/${_createdAt!.month}/${_createdAt!.year}'
        : '—';

    return Container(
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Details', style: DashboardTheme.headingMedium),
          const SizedBox(height: DashboardTheme.spacingLg),
          _buildDetailRow(
            Icons.verified_user_outlined,
            'Claim Status',
            displayClaim,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.calendar_today_outlined,
            'Member Since',
            joinedDate,
          ),
        ],
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(DashboardTheme.spacingLg),
      decoration: DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Security', style: DashboardTheme.headingMedium),
          const SizedBox(height: DashboardTheme.spacingMd),
          _buildActionTile(
            icon: Icons.lock_outline,
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
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: enabled
            ? DashboardTheme.textPrimary
            : DashboardTheme.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? DashboardTheme.primary : DashboardTheme.textTertiary,
          size: 22,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : DashboardTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardTheme.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required IconData icon,
    required String value,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: DashboardTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, color: DashboardTheme.textTertiary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DashboardTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: DashboardTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.lock,
                size: 16,
                color: DashboardTheme.textTertiary,
              ),
            ],
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              helperText,
              style: const TextStyle(
                fontSize: 11,
                color: DashboardTheme.textTertiary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DashboardTheme.primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DashboardTheme.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: DashboardTheme.textTertiary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DashboardTheme.spacingSm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DashboardTheme.warningSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: DashboardTheme.warning, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: DashboardTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DashboardTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: DashboardTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  // ── Change Password Dialog ────────────────────────────────────────────

  void _showChangePasswordDialog() {
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
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
                      const SnackBar(
                        content: Text('Password updated successfully'),
                        backgroundColor: DashboardTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: DashboardTheme.danger,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
