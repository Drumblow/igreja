import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Persistent shell with a responsive sidebar/bottom nav.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      path: '/',
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Membros',
      path: '/members',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;
    final currentPath = GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    for (int i = 0; i < _navItems.length; i++) {
      if (currentPath.startsWith(_navItems[i].path)) {
        selectedIndex = i;
      }
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              items: _navItems,
              selectedIndex: selectedIndex,
              onItemTap: (item) => context.go(item.path),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile: bottom nav
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(_navItems[i].path),
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final void Function(_NavItem) onItemTap;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.primary,
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Center(
                    child: Text(
                      'IM',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Igreja Manager',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gestão Inteligente',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Nav Items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;
                return _SidebarItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onItemTap(item),
                );
              },
            ),
          ),

          // ── Footer ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'v1.0.0',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  item.label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
