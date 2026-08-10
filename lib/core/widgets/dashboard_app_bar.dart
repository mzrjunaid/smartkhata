import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/role_provider.dart';
import '../../features/lender_dashboard/theme/dashboard_theme.dart';

/// Custom app bar with user greeting, role toggle, notification bell, and logout.
class DashboardAppBar extends ConsumerWidget {
  const DashboardAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.showBackButton = false,
  });

  final String? title;
  final String? subtitle;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final role = ref.watch(roleProvider);
    final userRolesAsync = ref.watch(userRolesProvider);

    final fullName =
        profileAsync.whenOrNull(data: (p) => p['full_name'] as String?) ??
        'User';
    final firstName = fullName.split(' ').first;
    final isLender = role == AppRole.lender;

    // Check if we should show the toggle (only if they have both roles)
    final hasBothRoles =
        userRolesAsync.whenOrNull(
          data: (roles) =>
              (roles['hasLender'] ?? false) && (roles['hasBorrower'] ?? false),
        ) ??
        false;

    // Gradient colors adapt to the active role
    final gradientColors = isLender
        ? const [DashboardTheme.primary, Color(0xFF2E7D32)]
        : const [DashboardTheme.accent, Color(0xFF00695C)];

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + DashboardTheme.spacingMd,
        left: DashboardTheme.spacingLg,
        right: DashboardTheme.spacingLg,
        bottom: DashboardTheme.spacingLg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (showBackButton)
                Padding(
                  padding: const EdgeInsets.only(
                    right: DashboardTheme.spacingMd,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                ),
              // ── Avatar ────────────────────────────────────────────────
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(width: DashboardTheme.spacingMd),

              // ── Greeting / Title ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subtitle != null || title == null)
                      Text(
                        subtitle ?? 'Welcome back,',
                        style: DashboardTheme.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    if (subtitle != null || title == null)
                      const SizedBox(height: 2),
                    Text(
                      title ?? firstName,
                      style: DashboardTheme.headingLarge.copyWith(
                        color: Colors.white,
                        fontSize: title != null ? 22 : 20,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Notification bell ─────────────────────────────────────
              IconButton(
                onPressed: () {
                  // TODO: Navigate to notifications screen.
                },
                icon: const Badge(
                  smallSize: 8,
                  backgroundColor: DashboardTheme.danger,
                  child: Icon(Icons.notifications_outlined),
                ),
                color: Colors.white,
                tooltip: 'Notifications',
              ),

              // ── Logout ────────────────────────────────────────────────
              IconButton(
                onPressed: () async {
                  try {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/login');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                color: Colors.white70,
                tooltip: 'Logout',
              ),
            ],
          ),

          // ── Role Toggle (only on home screens, and only if user has both roles) ──────
          if (!showBackButton && hasBothRoles) ...[
            const SizedBox(height: DashboardTheme.spacingMd),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _RoleTab(
                      label: 'Lender',
                      icon: Icons.account_balance,
                      isActive: isLender,
                      onTap: () => ref
                          .read(roleProvider.notifier)
                          .setRole(AppRole.lender),
                    ),
                  ),
                  Expanded(
                    child: _RoleTab(
                      label: 'Borrower',
                      icon: Icons.person_outline,
                      isActive: !isLender,
                      onTap: () => ref
                          .read(roleProvider.notifier)
                          .setRole(AppRole.borrower),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? DashboardTheme.primary : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? DashboardTheme.primary : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
