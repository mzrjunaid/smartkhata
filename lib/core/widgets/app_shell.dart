import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartkhata/core/theme/app_theme.dart';
import '../providers/role_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _GlossyBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        role: role,
      ),
    );
  }
}

class _GlossyBottomNav extends StatelessWidget {
  const _GlossyBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isLender = role == AppRole.lender;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 24,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.colors(context).cardBackground.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: AppTheme.colors(context).textTertiary.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: isLender ? Icons.people_alt_rounded : Icons.account_balance,
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_rounded,
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    isSelected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    isSelected: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.colors(context).primary : AppTheme.colors(context).textSecondary.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(
          icon,
          color: color,
          size: isSelected ? 30 : 26,
        ),
      ),
    );
  }
}
