import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/inline_create_dropdown.dart';
import '../bloc/ebd_bloc.dart';
import '../bloc/ebd_event_state.dart';
import '../data/ebd_repository.dart';
import '../data/models/ebd_models.dart';

class EbdClassListScreen extends StatelessWidget {
  const EbdClassListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => EbdBloc(
        repository: EbdRepository(apiClient: apiClient),
      )..add(const EbdClassesLoadRequested()),
      child: const _ClassListView(),
    );
  }
}

class _ClassListView extends StatelessWidget {
  const _ClassListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Turmas EBD')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Turma'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<EbdBloc, EbdState>(
        listener: (context, state) {
          if (state is EbdSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<EbdBloc>().add(const EbdClassesLoadRequested());
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
          if (state is EbdClassesLoaded) {
            if (state.classes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_outlined,
                        size: 64,
                        color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.md),
                    Text('Nenhuma turma cadastrada',
                        style: AppTypography.bodyLarge
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100,
              ),
              itemCount: state.classes.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                if (i == state.classes.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Carregar mais'),
                        onPressed: () => context.read<EbdBloc>().add(
                              EbdClassesLoadRequested(page: state.currentPage + 1),
                            ),
                      ),
                    ),
                  );
                }
                return _ClassTile(classSummary: state.classes[i]);
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
                  Text(state.message, style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<EbdBloc>()
                        .add(const EbdClassesLoadRequested()),
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

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final capacityCtrl = TextEditingController();
    final ageStartCtrl = TextEditingController();
    final ageEndCtrl = TextEditingController();

    // Load terms for the dropdown
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final repo = EbdRepository(apiClient: apiClient);
    final bloc = context.read<EbdBloc>();
    String? selectedTermId;
    final outerContext = context;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return FutureBuilder<List<EbdTerm>>(
            future: repo.getTerms(),
            builder: (context, snapshot) {
              final terms = snapshot.data ?? [];
              final isLoadingTerms = snapshot.connectionState == ConnectionState.waiting;

              return AlertDialog(
                title: const Text('Nova Turma'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoadingTerms)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: LinearProgressIndicator(),
                        )
                      else if (terms.isEmpty)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Nenhum trimestre cadastrado.',
                              style: TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showCreateTermInlineDialog(outerContext, repo, bloc);
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Criar Trimestre'),
                            ),
                          ],
                        )
                      else
                        InlineCreateDropdown<String>(
                          labelText: 'Trimestre *',
                          value: selectedTermId,
                          items: terms.map((t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          )).toList(),
                          onChanged: (v) => setDialogState(() => selectedTermId = v),
                          createTooltip: 'Criar trimestre',
                          onCreatePressed: () {
                            Navigator.pop(ctx);
                            _showCreateTermInlineDialog(outerContext, repo, bloc);
                          },
                        ),
                      const SizedBox(height: AppSpacing.md),
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
                      if (nameCtrl.text.trim().isEmpty ||
                          selectedTermId == null) return;
                      final data = <String, dynamic>{
                        'term_id': selectedTermId,
                        'name': nameCtrl.text.trim(),
                      };
                      if (ageStartCtrl.text.isNotEmpty) {
                        data['age_range_start'] = int.tryParse(ageStartCtrl.text);
                      }
                      if (ageEndCtrl.text.isNotEmpty) {
                        data['age_range_end'] = int.tryParse(ageEndCtrl.text);
                      }
                      if (roomCtrl.text.trim().isNotEmpty) {
                        data['room'] = roomCtrl.text.trim();
                      }
                      if (capacityCtrl.text.isNotEmpty) {
                        data['max_capacity'] = int.tryParse(capacityCtrl.text);
                      }
                      bloc.add(
                            EbdClassCreateRequested(data: data),
                          );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Criar'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateTermInlineDialog(BuildContext context, EbdRepository repo, EbdBloc bloc) {
    final nameCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 90));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Novo Trimestre'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    hintText: 'Ex: 1º Trimestre 2025',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setDialogState(() => startDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data Início',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setDialogState(() => endDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data Fim',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}',
                    ),
                  ),
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
                bloc.add(EbdTermCreateRequested(
                      data: {
                        'name': nameCtrl.text.trim(),
                        'start_date':
                            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                        'end_date':
                            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                      },
                    ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trimestre criado! Abra o dialog de Nova Turma novamente.')),
                );
              },
              child: const Text('Criar Trimestre'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  final EbdClassSummary classSummary;
  const _ClassTile({required this.classSummary});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.go('/ebd/classes/${classSummary.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: classSummary.isActive
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.border,
                child: Icon(
                  Icons.groups_outlined,
                  color: classSummary.isActive
                      ? AppColors.accent
                      : AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classSummary.name,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      classSummary.ageRangeLabel,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    if (classSummary.teacherName != null)
                      Text(
                        'Professor: ${classSummary.teacherName}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${classSummary.enrolledCount} alunos',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (classSummary.room != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Sala: ${classSummary.room}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
