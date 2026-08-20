import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/widgets/dashboard_app_bar.dart';
import 'package:smartkhata/core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          const DashboardAppBar(
            title: 'Settings',
            subtitle: 'Manage your preferences',
            showBackButton: false,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                _buildSectionCard(
                  context,
                  title: 'Appearance',
                  children: [
                    _buildSettingsRow(
                      context,
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: 'Toggle dark theme',
                      trailing: Switch(
                        value: isDark,
                        activeColor: AppTheme.colors(context).primary,
                        onChanged: (val) {
                          ref
                              .read(themeProvider.notifier)
                              .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionCard(
                  context,
                  title: 'Account',
                  children: [
                    _buildSettingsRow(
                      context,
                      icon: Icons.person_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal details',
                      onTap: () {
                        context.go('/profile', extra: {'edit': true});
                      },
                    ),
                    _buildDivider(context),
                    _buildSettingsRow(
                      context,
                      icon: Icons.lock_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your login credentials',
                      onTap: () {
                        _showChangePasswordDialog(context);
                      },
                    ),
                  ],
                ),

                if (ref.watch(roleProvider) == AppRole.lender) ...[
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    context,
                    title: 'Security & Logs',
                    children: [
                      _buildSettingsRow(
                        context,
                        icon: Icons.history_edu_rounded,
                        title: 'Audit Logs',
                        subtitle: 'View activity and changes',
                        onTap: () {
                          context.push('/audit-logs');
                        },
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                _buildSectionCard(
                  context,
                  title: 'Preferences',
                  children: [
                    _buildSettingsRow(
                      context,
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      subtitle: 'Manage your alerts',
                      onTap: () {
                        context.push('/notifications');
                      },
                    ),
                    _buildDivider(context),
                    _buildSettingsRow(
                      context,
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: 'Change app language',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'English',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.colors(context).textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: AppTheme.colors(context).textTertiary),
                        ],
                      ),
                      onTap: () {
                        // TODO: Navigate to Language selection
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Logout Button ──
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.colors(context).dangerSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.colors(context).danger.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        _showLogoutDialog(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: AppTheme.colors(context).danger),
                            const SizedBox(width: 12),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.colors(context).danger,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'SmartKhata v1.0.0',
                    style: TextStyle(
                      color: AppTheme.colors(context).textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppTheme.colors(context).textSecondary,
            ),
          ),
        ),
        Container(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
      indent: 64, // Aligns with text start
    );
  }

  Widget _buildSettingsRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.colors(context).primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.colors(context).primary, size: 22),
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.colors(context).textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) 
                trailing 
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: AppTheme.colors(context).textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Log Out', 
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.colors(context).textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.colors(context).textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.colors(context).textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colors(context).danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      // GoRouter will automatically redirect to /login because auth state changed
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
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
