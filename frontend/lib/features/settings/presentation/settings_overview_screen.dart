import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Settings overview — links to Church config and User management.
class SettingsOverviewScreen extends StatelessWidget {
  const SettingsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? AppSpacing.huge : AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Configurações', style: AppTypography.headingLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Gerencie a igreja, usuários e acessos ao sistema',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxl),

              _SettingsNavCard(
                icon: Icons.church_outlined,
                title: 'Dados da Igreja',
                subtitle:
                    'Informações cadastrais, endereço, contato e configurações',
                onTap: () => context.go('/settings/church'),
              ),
              const SizedBox(height: AppSpacing.md),
              _SettingsNavCard(
                icon: Icons.manage_accounts_outlined,
                title: 'Gestão de Usuários',
                subtitle:
                    'Criar, editar e desativar usuários e atribuir papéis',
                onTap: () => context.go('/settings/users'),
              ),
              const SizedBox(height: AppSpacing.md),
              _SettingsNavCard(
                icon: Icons.description_outlined,
                title: 'Relatórios',
                subtitle:
                    'Visão geral de métricas, aniversariantes e balanços',
                onTap: () => context.go('/reports'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsNavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, size: 28, color: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headingSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
