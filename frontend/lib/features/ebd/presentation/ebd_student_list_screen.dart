import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/ebd_bloc.dart';
import '../bloc/ebd_event_state.dart';
import '../data/ebd_repository.dart';
import '../data/models/ebd_models.dart';

class EbdStudentListScreen extends StatelessWidget {
  const EbdStudentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => EbdBloc(
        repository: EbdRepository(apiClient: apiClient),
      )..add(const EbdStudentsLoadRequested()),
      child: const _StudentListView(),
    );
  }
}

class _StudentListView extends StatefulWidget {
  const _StudentListView();

  @override
  State<_StudentListView> createState() => _StudentListViewState();
}

class _StudentListViewState extends State<_StudentListView> {
  final _searchCtrl = TextEditingController();
  String? _searchQuery;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alunos EBD'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar aluno por nome...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: _searchQuery != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = null);
                          context
                              .read<EbdBloc>()
                              .add(const EbdStudentsLoadRequested());
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() => _searchQuery = value.trim());
                  context
                      .read<EbdBloc>()
                      .add(EbdStudentsLoadRequested(search: value.trim()));
                }
              },
            ),
          ),
          // Student list
          Expanded(
            child: BlocConsumer<EbdBloc, EbdState>(
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
                    child:
                        CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                if (state is EbdStudentsLoaded) {
                  if (state.students.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined,
                              size: 64,
                              color: AppColors.textMuted
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _searchQuery != null
                                ? 'Nenhum aluno encontrado'
                                : 'Nenhum aluno matriculado na EBD',
                            style: AppTypography.bodyLarge
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          if (_searchQuery == null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.sm),
                              child: Text(
                                'Matricule membros em turmas da EBD',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 24),
                    itemCount: state.students.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) {
                      if (i == state.students.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.expand_more),
                              label: const Text('Carregar mais'),
                              onPressed: () => context.read<EbdBloc>().add(
                                    EbdStudentsLoadRequested(page: state.currentPage + 1),
                                  ),
                            ),
                          ),
                        );
                      }
                      return _StudentTile(student: state.students[i]);
                    },
                  );
                }
                if (state is EbdError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(state.message,
                            style: AppTypography.bodyMedium),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: () => context
                              .read<EbdBloc>()
                              .add(const EbdStudentsLoadRequested()),
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
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final EbdStudentSummary student;
  const _StudentTile({required this.student});

  Color _attendanceColor() {
    if (student.attendancePercentage >= 75) return AppColors.success;
    if (student.attendancePercentage >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.pushNamed('ebd-student-profile',
            pathParameters: {'memberId': student.memberId}),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                backgroundImage: student.photoUrl != null
                    ? NetworkImage(student.photoUrl!)
                    : null,
                child: student.photoUrl == null
                    ? Text(
                        student.fullName.isNotEmpty
                            ? student.fullName[0].toUpperCase()
                            : '?',
                        style: AppTypography.headingSmall
                            .copyWith(color: AppColors.accent),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.class_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${student.activeEnrollments} turma(s) ativa(s)',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(Icons.calendar_today,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${student.termsAttended} trimestre(s)',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Attendance percentage badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _attendanceColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Column(
                  children: [
                    Text(
                      '${student.attendancePercentage.toStringAsFixed(0)}%',
                      style: AppTypography.bodyMedium.copyWith(
                        color: _attendanceColor(),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text('Freq.',
                        style: AppTypography.bodySmall.copyWith(
                          color: _attendanceColor(),
                          fontSize: 9,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
