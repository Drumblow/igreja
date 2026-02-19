import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/ebd_bloc.dart';
import '../bloc/ebd_event_state.dart';
import '../data/ebd_repository.dart';

class EbdClassReportScreen extends StatelessWidget {
  final String classId;
  const EbdClassReportScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => EbdBloc(
        repository: EbdRepository(apiClient: apiClient),
      )..add(EbdClassReportLoadRequested(classId: classId)),
      child: _ReportView(classId: classId),
    );
  }
}

class _ReportView extends StatelessWidget {
  final String classId;
  const _ReportView({required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Relatório da Turma')),
      body: BlocConsumer<EbdBloc, EbdState>(
        listener: (context, state) {
          if (state is EbdError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is EbdLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }
          if (state is EbdClassReportLoaded) {
            return _buildReport(context, state.report);
          }
          if (state is EbdError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(state.message, style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<EbdBloc>()
                        .add(EbdClassReportLoadRequested(classId: classId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildReport(BuildContext context, Map<String, dynamic> report) {
    final className = report['class_name'] as String? ?? 'Turma';
    final termName = report['term_name'] as String? ?? '';
    final totalLessons = report['total_lessons'] as int? ?? 0;
    final totalEnrolled = report['total_enrolled'] as int? ?? 0;
    final avgAttendance = (report['average_attendance'] as num?)?.toDouble() ?? 0;
    final students = report['students'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report header
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              side: BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(className, style: AppTypography.headingMedium),
                  if (termName.isNotEmpty)
                    Text(termName,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ReportStat(
                        label: 'Aulas',
                        value: '$totalLessons',
                        icon: Icons.menu_book_outlined,
                        color: AppColors.info,
                      ),
                      _ReportStat(
                        label: 'Matriculados',
                        value: '$totalEnrolled',
                        icon: Icons.people_outline,
                        color: AppColors.accent,
                      ),
                      _ReportStat(
                        label: 'Freq. Média',
                        value: '${avgAttendance.toStringAsFixed(0)}%',
                        icon: Icons.pie_chart_outline,
                        color: avgAttendance >= 75
                            ? AppColors.success
                            : avgAttendance >= 50
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Student attendance table
          Text('Frequência por Aluno', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          if (students.isEmpty)
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Nenhum dado de frequência',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            )
          else
            ...students.map((s) {
              final studentData = s as Map<String, dynamic>? ?? {};
              final name = studentData['member_name'] as String? ?? 'Aluno';
              final present = studentData['present_count'] as int? ?? 0;
              final absent = studentData['absent_count'] as int? ?? 0;
              final justified = studentData['justified_count'] as int? ?? 0;
              final total = present + absent + justified;
              final pct = total > 0
                  ? (present / total * 100)
                  : 0.0;
              final pctColor = pct >= 75
                  ? AppColors.success
                  : pct >= 50
                      ? AppColors.warning
                      : AppColors.error;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  side: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(name,
                            style: AppTypography.bodySmall
                                .copyWith(fontWeight: FontWeight.w500)),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text('$present',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.success)),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text('$absent',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.error)),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text('$justified',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.warning)),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('${pct.toStringAsFixed(0)}%',
                            textAlign: TextAlign.end,
                            style: AppTypography.bodySmall.copyWith(
                              color: pctColor,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ),
                ),
              );
            }),
          // Table header
          if (students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox()),
                  SizedBox(
                    width: 32,
                    child: Text('P',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.success,
                          fontSize: 10,
                        )),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text('A',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontSize: 10,
                        )),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text('J',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warning,
                          fontSize: 10,
                        )),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text('Freq.',
                        textAlign: TextAlign.end,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        )),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: AppSpacing.xs),
        Text(value,
            style: AppTypography.headingSmall.copyWith(color: color)),
        Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}
