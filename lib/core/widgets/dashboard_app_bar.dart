import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/role_provider.dart';
import 'package:smartkhata/core/theme/app_theme.dart';

/// Custom app bar with user greeting, role toggle, notification bell, and logout.
class DashboardAppBar extends ConsumerWidget {
  const DashboardAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.trailing,
  });

  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final Widget? trailing;

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
        ? [AppTheme.colors(context).primary.withValues(alpha: 0.8), const Color(0xFF2E7D32).withValues(alpha: 0.7)]
        : [AppTheme.colors(context).accent.withValues(alpha: 0.8), const Color(0xFF00695C).withValues(alpha: 0.7)];

    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppTheme.spacingMd,
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        bottom: AppTheme.spacingLg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
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
                    right: AppTheme.spacingMd,
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

              const SizedBox(width: AppTheme.spacingMd),

              // ── Greeting / Title ──────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subtitle != null || title == null)
                      Text(
                        subtitle ?? 'Welcome back,',
                        style: AppTheme.text(context).bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    if (subtitle != null || title == null)
                      const SizedBox(height: 2),
                    Text(
                      title ?? firstName,
                      style: AppTheme.text(context).headingLarge.copyWith(
                        color: Colors.white,
                        fontSize: title != null ? 22 : 20,
                      ),
                    ),
                  ],
                ),
              ),

              if (trailing != null)
                trailing!
              else ...[
                // ── Notification bell ─────────────────────────────────────
                IconButton(
                  onPressed: () {
                    context.push('/notifications');
                  },
                  icon: Badge(
                    smallSize: 8,
                    backgroundColor: AppTheme.colors(context).danger,
                    child: Icon(Icons.notifications_outlined),
                  ),
                  color: Colors.white,
                  tooltip: 'Notifications',
                ),

                // ── Logout ────────────────────────────────────────────────
                if (!showBackButton)
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
            ],
          ),

          // ── Role Toggle (only on home screens, and only if user has both roles) ──────
          if (!showBackButton && hasBothRoles) ...[
            const SizedBox(height: AppTheme.spacingMd),
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
          ),
        ),
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
              color: isActive ? AppTheme.colors(context).primary : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? AppTheme.colors(context).primary : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
