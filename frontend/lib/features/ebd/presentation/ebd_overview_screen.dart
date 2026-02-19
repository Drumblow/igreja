import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Stats model for EBD overview
class _EbdOverviewStats {
  final int totalClasses;
  final int totalEnrolled;
  final int activeTerms;
  final double avgAttendanceRate;

  const _EbdOverviewStats({
    this.totalClasses = 0,
    this.totalEnrolled = 0,
    this.activeTerms = 0,
    this.avgAttendanceRate = 0,
  });

  factory _EbdOverviewStats.fromJson(Map<String, dynamic> json) {
    return _EbdOverviewStats(
      totalClasses: json['total_classes'] as int? ?? 0,
      totalEnrolled: json['total_enrolled'] as int? ?? 0,
      activeTerms: json['active_terms'] as int? ?? 0,
      avgAttendanceRate: (json['avg_attendance_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class EbdOverviewScreen extends StatefulWidget {
  const EbdOverviewScreen({super.key});

  @override
  State<EbdOverviewScreen> createState() => _EbdOverviewScreenState();
}

class _EbdOverviewScreenState extends State<EbdOverviewScreen> {
  _EbdOverviewStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final response = await apiClient.dio.get('/v1/ebd/stats');
      if (mounted) {
        setState(() {
          _stats = _EbdOverviewStats.fromJson(
              response.data['data'] as Map<String, dynamic>);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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

              // Stats section — wired to API
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
                    const SizedBox(height: AppSpacing.lg),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: CircularProgressIndicator(
                              color: AppColors.accent),
                        ),
                      )
                    else if (_stats != null)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 500;
                          return Wrap(
                            spacing: isWide ? AppSpacing.xxl : AppSpacing.lg,
                            runSpacing: AppSpacing.lg,
                            children: [
                              _StatTile(
                                label: 'Trimestres Ativos',
                                value: '${_stats!.activeTerms}',
                                icon: Icons.date_range_outlined,
                                color: AppColors.accent,
                              ),
                              _StatTile(
                                label: 'Turmas',
                                value: '${_stats!.totalClasses}',
                                icon: Icons.groups_outlined,
                                color: AppColors.info,
                              ),
                              _StatTile(
                                label: 'Alunos Matriculados',
                                value: '${_stats!.totalEnrolled}',
                                icon: Icons.person_outlined,
                                color: AppColors.success,
                              ),
                              _StatTile(
                                label: 'Frequência Média',
                                value:
                                    '${_stats!.avgAttendanceRate.toStringAsFixed(1)}%',
                                icon: Icons.fact_check_outlined,
                                color: AppColors.primary,
                              ),
                            ],
                          );
                        },
                      )
                    else
                      Text(
                        'Não foi possível carregar as estatísticas.',
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
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
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
