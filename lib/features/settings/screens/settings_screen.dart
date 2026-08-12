import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:go_router/go_router.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/widgets/dashboard_app_bar.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          const DashboardAppBar(
            title: 'Settings',
            subtitle: 'Manage your preferences',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20, bottom: 120),
              children: [
          _buildSectionHeader(context, 'Appearance'),
          _buildListTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: isDark,
              onChanged: (val) {
                ref
                    .read(themeProvider.notifier)
                    .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Account'),
          _buildListTile(
            context,
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {
              // TODO: Navigate to Edit Profile
            },
          ),
          _buildListTile(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () {
              // TODO: Navigate to Change Password
            },
          ),

          if (ref.watch(roleProvider) == AppRole.lender) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Security & Logs'),
            _buildListTile(
              context,
              icon: Icons.history_edu_rounded,
              title: 'Audit Logs',
              onTap: () {
                context.push('/audit-logs');
              },
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Preferences'),
          _buildListTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              // TODO: Navigate to Notifications
            },
          ),
          _buildListTile(
            context,
            icon: Icons.language_outlined,
            title: 'Language',
            trailing: const Text(
              'English',
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              // TODO: Navigate to Language selection
            },
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 8),

          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await Supabase.instance.client.auth.signOut();
                // GoRouter will automatically redirect to /login because auth state changed
              }
            },
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'SmartKhata v1.0.0',
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
