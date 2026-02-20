import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Persistent shell with a responsive sidebar/bottom nav.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  /// All navigation items (used by sidebar on desktop).
  static const _allNavItems = [
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
    _NavItem(
      icon: Icons.family_restroom_outlined,
      activeIcon: Icons.family_restroom_rounded,
      label: 'Famílias',
      path: '/families',
    ),
    _NavItem(
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      label: 'Ministérios',
      path: '/ministries',
    ),
    _NavItem(
      icon: Icons.attach_money_outlined,
      activeIcon: Icons.attach_money_rounded,
      label: 'Financeiro',
      path: '/financial',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Patrimônio',
      path: '/assets',
    ),
    _NavItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'EBD',
      path: '/ebd',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Configurações',
      path: '/settings',
    ),
  ];

  /// Items shown in the mobile bottom nav (first 4 + "Mais").
  static const _mobileNavItems = [
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
    _NavItem(
      icon: Icons.family_restroom_outlined,
      activeIcon: Icons.family_restroom_rounded,
      label: 'Famílias',
      path: '/families',
    ),
    _NavItem(
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      label: 'Ministérios',
      path: '/ministries',
    ),
  ];

  /// Items shown inside the "Mais" bottom sheet.
  static const _moreNavItems = [
    _NavItem(
      icon: Icons.attach_money_outlined,
      activeIcon: Icons.attach_money_rounded,
      label: 'Financeiro',
      path: '/financial',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Patrimônio',
      path: '/assets',
    ),
    _NavItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'EBD',
      path: '/ebd',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Configurações',
      path: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;
    final currentPath = GoRouterState.of(context).matchedLocation;

    // Desktop sidebar: match against all items
    if (isWide) {
      int selectedIndex = 0;
      for (int i = 0; i < _allNavItems.length; i++) {
        if (currentPath.startsWith(_allNavItems[i].path)) {
          selectedIndex = i;
        }
      }

      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              items: _allNavItems,
              selectedIndex: selectedIndex,
              onItemTap: (item) => context.go(item.path),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile: bottom nav with 4 items + "Mais"
    int selectedIndex = -1;
    for (int i = 0; i < _mobileNavItems.length; i++) {
      if (currentPath.startsWith(_mobileNavItems[i].path)) {
        selectedIndex = i;
      }
    }
    // If current path is in the "more" group, highlight "Mais" tab
    final isInMore = _moreNavItems.any((item) => currentPath.startsWith(item.path));
    final mobileSelectedIndex = isInMore ? 4 : (selectedIndex < 0 ? 0 : selectedIndex);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileSelectedIndex,
        onDestinationSelected: (i) {
          if (i < _mobileNavItems.length) {
            context.go(_mobileNavItems[i].path);
          } else {
            // "Mais" tab — show bottom sheet
            _showMoreSheet(context, currentPath);
          }
        },
        destinations: [
          ..._mobileNavItems.map((item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: item.label,
              )),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'Mais',
          ),
        ],
      ),
    );
  }

  static void _showMoreSheet(BuildContext context, String currentPath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.md),
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mais opções',
                      style: AppTypography.headingSmall,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._moreNavItems.map((item) {
                  final isActive = currentPath.startsWith(item.path);
                  return ListTile(
                    leading: Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isActive ? AppColors.accent : AppColors.textSecondary,
                      size: 24,
                    ),
                    title: Text(
                      item.label,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isActive ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: isActive
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go(item.path);
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
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
