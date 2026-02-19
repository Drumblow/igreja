import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class EbdOverviewScreen extends StatelessWidget {
  const EbdOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('Escola Bíblica Dominical',
                style: AppTypography.headingLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Gerencie trimestres, turmas, aulas e frequência',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Stats placeholder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school_outlined,
                          color: AppColors.accent, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Visão Geral da EBD',
                          style: AppTypography.headingMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'As estatísticas serão carregadas quando o backend estiver conectado.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Quick actions
            Text('Acesso Rápido', style: AppTypography.headingMedium),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.4,
                  children: [
                    _QuickActionCard(
                      icon: Icons.date_range_outlined,
                      title: 'Trimestres',
                      subtitle: 'Períodos letivos',
                      onTap: () => context.go('/ebd/terms'),
                    ),
                    _QuickActionCard(
                      icon: Icons.groups_outlined,
                      title: 'Turmas',
                      subtitle: 'Classes e alunos',
                      onTap: () => context.go('/ebd/classes'),
                    ),
                    _QuickActionCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Aulas',
                      subtitle: 'Registro de lições',
                      onTap: () => context.go('/ebd/lessons'),
                    ),
                    _QuickActionCard(
                      icon: Icons.fact_check_outlined,
                      title: 'Frequência',
                      subtitle: 'Chamada e presença',
                      onTap: () => context.go('/ebd/attendance'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppColors.accent),
              const SizedBox(height: AppSpacing.sm),
              Text(title,
                  style: AppTypography.labelLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
