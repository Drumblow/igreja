import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/inline_create_dropdown.dart';
import '../bloc/ebd_bloc.dart';
import '../bloc/ebd_event_state.dart';
import '../data/ebd_repository.dart';
import '../data/models/ebd_models.dart';

class EbdLessonListScreen extends StatelessWidget {
  const EbdLessonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => EbdBloc(
        repository: EbdRepository(apiClient: apiClient),
      )..add(const EbdLessonsLoadRequested()),
      child: const _LessonListView(),
    );
  }
}

class _LessonListView extends StatelessWidget {
  const _LessonListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Aulas EBD')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Aula'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<EbdBloc, EbdState>(
        listener: (context, state) {
          if (state is EbdSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<EbdBloc>().add(const EbdLessonsLoadRequested());
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
          if (state is EbdLessonsLoaded) {
            if (state.lessons.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_outlined,
                        size: 64,
                        color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.md),
                    Text('Nenhuma aula registrada',
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
              itemCount: state.lessons.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) =>
                  _LessonTile(lesson: state.lessons[i]),
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
                        .add(const EbdLessonsLoadRequested()),
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
    final titleCtrl = TextEditingController();
    final lessonNumCtrl = TextEditingController();
    final themeCtrl = TextEditingController();
    final bibleTextCtrl = TextEditingController();
    DateTime lessonDate = DateTime.now();

    // Load classes for the dropdown
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final repo = EbdRepository(apiClient: apiClient);
    final bloc = context.read<EbdBloc>();
    String? selectedClassId;
    final outerContext = context;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return FutureBuilder<List<EbdClassSummary>>(
            future: repo.getClasses(),
            builder: (context, snapshot) {
              final classes = snapshot.data ?? [];
              final isLoadingClasses = snapshot.connectionState == ConnectionState.waiting;

              return AlertDialog(
                title: const Text('Nova Aula'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoadingClasses)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: LinearProgressIndicator(),
                        )
                      else if (classes.isEmpty)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Nenhuma turma cadastrada.',
                              style: TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showCreateClassInlineDialog(outerContext, repo, bloc);
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Criar Turma'),
                            ),
                          ],
                        )
                      else
                        InlineCreateDropdown<String>(
                          labelText: 'Turma *',
                          value: selectedClassId,
                          items: classes.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          )).toList(),
                          onChanged: (v) => setDialogState(() => selectedClassId = v),
                          createTooltip: 'Criar nova turma',
                          onCreatePressed: () {
                            Navigator.pop(ctx);
                            _showCreateClassInlineDialog(outerContext, repo, bloc);
                          },
                        ),
                      const SizedBox(height: AppSpacing.md),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: lessonDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setDialogState(() => lessonDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data da Aula',
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            '${lessonDate.day.toString().padLeft(2, '0')}/${lessonDate.month.toString().padLeft(2, '0')}/${lessonDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: lessonNumCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Número da Lição',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          hintText: 'Título da lição (opcional)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: themeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tema',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: bibleTextCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Texto Bíblico',
                          hintText: 'Ex: João 3:16',
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
                      if (selectedClassId == null) return;
                      final data = <String, dynamic>{
                        'class_id': selectedClassId,
                        'lesson_date':
                            '${lessonDate.year}-${lessonDate.month.toString().padLeft(2, '0')}-${lessonDate.day.toString().padLeft(2, '0')}',
                      };
                      if (lessonNumCtrl.text.isNotEmpty) {
                        data['lesson_number'] = int.tryParse(lessonNumCtrl.text);
                      }
                      if (titleCtrl.text.trim().isNotEmpty) {
                        data['title'] = titleCtrl.text.trim();
                      }
                      if (themeCtrl.text.trim().isNotEmpty) {
                        data['theme'] = themeCtrl.text.trim();
                      }
                      if (bibleTextCtrl.text.trim().isNotEmpty) {
                        data['bible_text'] = bibleTextCtrl.text.trim();
                      }
                      bloc.add(
                            EbdLessonCreateRequested(data: data),
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

  void _showCreateClassInlineDialog(BuildContext context, EbdRepository repo, EbdBloc bloc) {
    final nameCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    String? selectedTermId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return FutureBuilder<List<EbdTerm>>(
            future: repo.getTerms(),
            builder: (_, snapshot) {
              final terms = snapshot.data ?? [];
              final isLoadingTerms =
                  snapshot.connectionState == ConnectionState.waiting;

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
                        const Text(
                          'Nenhum trimestre cadastrado. Crie um trimestre primeiro na tela de Trimestres EBD.',
                          style: TextStyle(color: AppColors.error),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedTermId,
                          decoration: const InputDecoration(
                            labelText: 'Trimestre *',
                          ),
                          items: terms
                              .map((t) => DropdownMenuItem(
                                    value: t.id,
                                    child: Text(t.name),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedTermId = v),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome da Turma *',
                          hintText: 'Ex: Adultos, Jovens, Crianças',
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: roomCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Sala (opcional)',
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
                          selectedTermId == null) {
                        return;
                      }
                      final data = <String, dynamic>{
                        'term_id': selectedTermId,
                        'name': nameCtrl.text.trim(),
                      };
                      if (roomCtrl.text.trim().isNotEmpty) {
                        data['room'] = roomCtrl.text.trim();
                      }
                      bloc.add(
                            EbdClassCreateRequested(data: data),
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Turma criada! Abra o dialog de Nova Aula novamente.'),
                        ),
                      );
                    },
                    child: const Text('Criar Turma'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final EbdLessonSummary lesson;
  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: Text(
                  lesson.lessonNumber != null
                      ? '${lesson.lessonNumber}'
                      : '#',
                  style: AppTypography.headingSmall
                      .copyWith(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.displayTitle,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Data: ${lesson.lessonDate}',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if (lesson.className != null)
                    Text(
                      'Turma: ${lesson.className}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  if (lesson.teacherName != null)
                    Text(
                      'Professor: ${lesson.teacherName}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 14, color: AppColors.info),
                  const SizedBox(width: 4),
                  Text(
                    '${lesson.attendanceCount}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
