import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.email.split('@').first
        : 'Usuário';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: _buildHeader(context, userName),
          ),

          // ── Stats Cards ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            sliver: SliverGrid.count(
              crossAxisCount: _crossAxisCount(context),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.65,
              children: const [
                _StatCard(
                  icon: Icons.people_rounded,
                  label: 'Membros Ativos',
                  value: '—',
                  trend: null,
                  color: AppColors.primary,
                ),
                _StatCard(
                  icon: Icons.attach_money_rounded,
                  label: 'Entradas (Mês)',
                  value: '—',
                  trend: null,
                  color: AppColors.success,
                ),
                _StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Patrimônio',
                  value: '—',
                  trend: null,
                  color: AppColors.info,
                ),
                _StatCard(
                  icon: Icons.school_outlined,
                  label: 'Alunos EBD',
                  value: '—',
                  trend: null,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),

          // ── Quick Actions ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Ações Rápidas',
                style: AppTypography.headingSmall,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid.count(
              crossAxisCount: _crossAxisCount(context),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.2,
              children: [
                _QuickAction(
                  icon: Icons.person_add_outlined,
                  label: 'Novo Membro',
                  onTap: () => context.go('/members/new'),
                ),
                _QuickAction(
                  icon: Icons.receipt_long_outlined,
                  label: 'Lançamento',
                  onTap: () {
                    // TODO: Navigate to financial entry
                  },
                ),
                _QuickAction(
                  icon: Icons.fact_check_outlined,
                  label: 'Chamada EBD',
                  onTap: () {
                    // TODO: Navigate to EBD attendance
                  },
                ),
                _QuickAction(
                  icon: Icons.bar_chart_rounded,
                  label: 'Relatórios',
                  onTap: () {
                    // TODO: Navigate to reports
                  },
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxl),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $userName',
                  style: AppTypography.headingLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Bem-vindo ao painel de gestão.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Profile / Logout
          PopupMenuButton(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            icon: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              child: Text(
                userName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              }
            },
          ),
        ],
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;
    if (width >= 800) return 2;
    return 2;
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trend;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                if (trend != null)
                  Text(
                    trend!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action ──
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: AppColors.border.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
