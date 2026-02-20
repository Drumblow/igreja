import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/searchable_entity_dropdown.dart';
import '../../members/data/member_repository.dart';
import '../bloc/ebd_bloc.dart';
import '../bloc/ebd_event_state.dart';
import '../data/ebd_repository.dart';
import '../data/models/ebd_models.dart';

class EbdClassDetailScreen extends StatelessWidget {
  final String classId;
  const EbdClassDetailScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => EbdBloc(
        repository: EbdRepository(apiClient: apiClient),
      )..add(EbdClassDetailLoadRequested(classId: classId)),
      child: _ClassDetailView(classId: classId),
    );
  }
}

class _ClassDetailView extends StatelessWidget {
  final String classId;
  const _ClassDetailView({required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalhes da Turma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar Turma',
            onPressed: () {
              final state = context.read<EbdBloc>().state;
              if (state is EbdClassDetailLoaded) {
                _showEditClassDialog(context, state.ebdClass);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Matricular Aluno',
            onPressed: () => _showEnrollDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Relatório da Turma',
            onPressed: () => context.go('/ebd/classes/$classId/report'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir Turma',
            color: AppColors.error,
            onPressed: () => _showDeleteClassDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<EbdBloc, EbdState>(
        listener: (context, state) {
          if (state is EbdSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context
                .read<EbdBloc>()
                .add(EbdClassDetailLoadRequested(classId: classId));
          }
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
          if (state is EbdClassDetailLoaded) {
            return _buildContent(context, state.ebdClass, state.enrollments);
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
                        .add(EbdClassDetailLoadRequested(classId: classId)),
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

  Widget _buildContent(
    BuildContext context,
    EbdClass ebdClass,
    List<EbdEnrollmentDetail> enrollments,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class info card
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
                    Icon(Icons.groups_outlined,
                        color: AppColors.accent, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(ebdClass.name,
                          style: AppTypography.headingMedium),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (ebdClass.isActive
                                ? AppColors.success
                                : AppColors.textMuted)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ebdClass.isActive ? 'Ativa' : 'Inativa',
                        style: AppTypography.bodySmall.copyWith(
                          color: ebdClass.isActive
                              ? AppColors.success
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow('Faixa Etária', ebdClass.ageRangeLabel),
                if (ebdClass.room != null)
                  _InfoRow('Sala', ebdClass.room!),
                if (ebdClass.maxCapacity != null)
                  _InfoRow('Capacidade', '${ebdClass.maxCapacity} alunos'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Enrollments section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alunos Matriculados (${enrollments.length})',
                  style: AppTypography.headingMedium),
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => _showEnrollDialog(context),
                tooltip: 'Matricular',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (enrollments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_off_outlined,
                      size: 40,
                      color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Nenhum aluno matriculado',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            ...enrollments.map((e) => _EnrollmentTile(
                  enrollment: e,
                  classId: classId,
                )),
        ],
      ),
    );
  }

  void _showDeleteClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Turma'),
        content: const Text(
          'Tem certeza que deseja excluir esta turma?\n\n'
          'Todas as matrículas, aulas e frequências vinculadas serão removidas. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<EbdBloc>().add(
                    EbdClassDeleteRequested(classId: classId),
                  );
              Navigator.pop(ctx);
              context.go('/ebd/classes');
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(BuildContext context, EbdClass ebdClass) {
    final nameCtrl = TextEditingController(text: ebdClass.name);
    final roomCtrl = TextEditingController(text: ebdClass.room ?? '');
    final capacityCtrl = TextEditingController(
        text: ebdClass.maxCapacity?.toString() ?? '');
    final ageStartCtrl = TextEditingController(
        text: ebdClass.ageRangeStart?.toString() ?? '');
    final ageEndCtrl = TextEditingController(
        text: ebdClass.ageRangeEnd?.toString() ?? '');
    bool isActive = ebdClass.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Turma'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Turma *',
                    hintText: 'Ex: Adultos, Jovens, Crianças',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageStartCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Idade Mín.',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: ageEndCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Idade Máx.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sala',
                    hintText: 'Sala da turma (opcional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: capacityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacidade Máxima',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  title: const Text('Turma Ativa'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final data = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'is_active': isActive,
                };
                if (ageStartCtrl.text.isNotEmpty) {
                  data['age_range_start'] =
                      int.tryParse(ageStartCtrl.text);
                }
                if (ageEndCtrl.text.isNotEmpty) {
                  data['age_range_end'] =
                      int.tryParse(ageEndCtrl.text);
                }
                if (roomCtrl.text.trim().isNotEmpty) {
                  data['room'] = roomCtrl.text.trim();
                }
                if (capacityCtrl.text.isNotEmpty) {
                  data['max_capacity'] =
                      int.tryParse(capacityCtrl.text);
                }
                context.read<EbdBloc>().add(
                      EbdClassUpdateRequested(
                        classId: classId,
                        data: data,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnrollDialog(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final memberRepo = MemberRepository(apiClient: apiClient);
    EntityOption? selectedMember;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Matricular Aluno'),
        content: SizedBox(
          width: 360,
          child: SearchableEntityDropdown(
            label: 'Membro *',
            hint: 'Busque pelo nome...',
            onSelected: (entity) => selectedMember = entity,
            searchCallback: (query) async {
              final result = await memberRepo.getMembers(
                search: query,
                perPage: 20,
                status: 'ativo',
              );
              return result.members
                  .map((m) => EntityOption(id: m.id, label: m.fullName))
                  .toList();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (selectedMember == null) return;
              context.read<EbdBloc>().add(EbdEnrollMemberRequested(
                    classId: classId,
                    data: {'member_id': selectedMember!.id},
                  ));
              Navigator.pop(ctx);
            },
            child: const Text('Matricular'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentTile extends StatelessWidget {
  final EbdEnrollmentDetail enrollment;
  final String classId;
  const _EnrollmentTile({required this.enrollment, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: enrollment.isActive
              ? AppColors.success.withValues(alpha: 0.15)
              : AppColors.border,
          child: Icon(
            Icons.person_outline,
            color: enrollment.isActive ? AppColors.success : AppColors.textMuted,
            size: 20,
          ),
        ),
        title: Text(
          enrollment.memberName ?? 'Membro',
          style: AppTypography.bodyMedium
              .copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Matrícula: ${enrollment.enrolledAt}${enrollment.isActive ? '' : ' (Inativo)'}',
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        trailing: enrollment.isActive
            ? IconButton(
                icon: const Icon(Icons.person_remove_outlined,
                    size: 20, color: AppColors.error),
                tooltip: 'Remover Matrícula',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remover Matrícula'),
                      content: Text(
                          'Deseja remover ${enrollment.memberName ?? "este aluno"} da turma?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          onPressed: () {
                            context
                                .read<EbdBloc>()
                                .add(EbdRemoveEnrollmentRequested(
                                  classId: classId,
                                  enrollmentId: enrollment.id,
                                ));
                            Navigator.pop(ctx);
                          },
                          child: const Text('Remover'),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}
