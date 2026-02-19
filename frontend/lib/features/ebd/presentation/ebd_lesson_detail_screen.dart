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

class EbdLessonDetailScreen extends StatelessWidget {
  final String lessonId;
  const EbdLessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => EbdBloc(
        repository: EbdRepository(apiClient: apiClient),
      )..add(EbdLessonContentsLoadRequested(lessonId: lessonId)),
      child: _LessonDetailView(lessonId: lessonId),
    );
  }
}

class _LessonDetailView extends StatelessWidget {
  final String lessonId;
  const _LessonDetailView({required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<EbdBloc, EbdState>(
        listener: (context, state) {
          if (state is EbdSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context
                .read<EbdBloc>()
                .add(EbdLessonContentsLoadRequested(lessonId: lessonId));
          }
          if (state is EbdError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is EbdLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Detalhes da Aula')),
              body: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            );
          }
          if (state is EbdLessonFullLoaded) {
            return _buildContent(context, state);
          }
          if (state is EbdError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Detalhes da Aula')),
              body: Center(
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
                          .add(EbdLessonContentsLoadRequested(
                              lessonId: lessonId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Detalhes da Aula')),
            body: const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, EbdLessonFullLoaded state) {
    final lesson = state.lesson;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(lesson.displayTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar aula',
              onPressed: () => _showEditLessonDialog(context, lesson),
            ),
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: 'Registrar Frequência',
              onPressed: () =>
                  context.pushNamed('ebd-attendance', pathParameters: {
                'lessonId': lessonId,
              }),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error),
                      SizedBox(width: AppSpacing.sm),
                      Text('Excluir Aula'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Conteúdo', icon: Icon(Icons.description_outlined)),
              Tab(text: 'Atividades', icon: Icon(Icons.quiz_outlined)),
              Tab(text: 'Materiais', icon: Icon(Icons.attach_file)),
              Tab(text: 'Frequência', icon: Icon(Icons.people_outline)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Lesson header info
            _LessonHeaderCard(lesson: lesson),
            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _ContentTab(
                    lessonId: lessonId,
                    contents: state.contents,
                  ),
                  _ActivitiesTab(
                    lessonId: lessonId,
                    activities: state.activities,
                  ),
                  _MaterialsTab(
                    lessonId: lessonId,
                    materials: state.materials,
                  ),
                  _AttendanceTab(
                    lessonId: lessonId,
                    attendance: state.attendance,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLessonDialog(BuildContext context, EbdLesson lesson) {
    final titleCtrl = TextEditingController(text: lesson.title);
    final themeCtrl = TextEditingController(text: lesson.theme);
    final bibleTextCtrl = TextEditingController(text: lesson.bibleText);
    final summaryCtrl = TextEditingController(text: lesson.summary);
    final bloc = context.read<EbdBloc>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Aula'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: themeCtrl,
                decoration: const InputDecoration(labelText: 'Tema'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: bibleTextCtrl,
                decoration: const InputDecoration(
                  labelText: 'Texto Bíblico',
                  hintText: 'Ex: João 3:16',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: summaryCtrl,
                decoration: const InputDecoration(labelText: 'Resumo'),
                maxLines: 3,
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
              final data = <String, dynamic>{};
              if (titleCtrl.text.trim().isNotEmpty) {
                data['title'] = titleCtrl.text.trim();
              }
              if (themeCtrl.text.trim().isNotEmpty) {
                data['theme'] = themeCtrl.text.trim();
              }
              if (bibleTextCtrl.text.trim().isNotEmpty) {
                data['bible_text'] = bibleTextCtrl.text.trim();
              }
              if (summaryCtrl.text.trim().isNotEmpty) {
                data['summary'] = summaryCtrl.text.trim();
              }
              bloc.add(EbdLessonUpdateRequested(
                lessonId: lessonId,
                data: data,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final bloc = context.read<EbdBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Aula'),
        content: const Text(
          'Tem certeza que deseja excluir esta aula? '
          'Todos os dados de frequência, conteúdo e atividades serão removidos.',
        ),
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
              bloc.add(EbdLessonDeleteRequested(
                lessonId: lessonId,
                force: true,
              ));
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Lesson Header Card
// ==========================================

class _LessonHeaderCard extends StatelessWidget {
  final EbdLesson lesson;
  const _LessonHeaderCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          if (lesson.lessonNumber != null)
            _InfoChip(
              icon: Icons.tag,
              label: 'Lição ${lesson.lessonNumber}',
            ),
          _InfoChip(
            icon: Icons.calendar_today,
            label: lesson.lessonDate,
          ),
          if (lesson.bibleText != null)
            _InfoChip(
              icon: Icons.auto_stories,
              label: lesson.bibleText!,
            ),
          if (lesson.theme != null)
            _InfoChip(
              icon: Icons.topic,
              label: lesson.theme!,
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

// ==========================================
// Tab: Conteúdo (E1)
// ==========================================

class _ContentTab extends StatelessWidget {
  final String lessonId;
  final List<EbdLessonContent> contents;
  const _ContentTab({required this.lessonId, required this.contents});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showAddContentDialog(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        tooltip: 'Adicionar Conteúdo',
        child: const Icon(Icons.add),
      ),
      body: contents.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      size: 48,
                      color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSpacing.md),
                  Text('Nenhum conteúdo adicionado',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Adicione textos, imagens e referências bíblicas',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
              itemCount: contents.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) => _ContentBlockCard(
                content: contents[i],
                lessonId: lessonId,
              ),
            ),
    );
  }

  void _showAddContentDialog(BuildContext context) {
    String selectedType = 'text';
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    final imageCaptionCtrl = TextEditingController();
    final bloc = context.read<EbdBloc>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Adicionar Conteúdo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de Conteúdo'),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('Texto')),
                    DropdownMenuItem(value: 'image', child: Text('Imagem')),
                    DropdownMenuItem(
                        value: 'bible_reference',
                        child: Text('Referência Bíblica')),
                    DropdownMenuItem(
                        value: 'note',
                        child: Text('Nota do Professor')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? 'text'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título (opcional)',
                    hintText: 'Ex: Introdução, Versículo-chave',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: bodyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo',
                    hintText: 'Texto do conteúdo...',
                  ),
                  maxLines: 5,
                ),
                if (selectedType == 'image') ...[
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: imageUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL da Imagem',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: imageCaptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Legenda',
                    ),
                  ),
                ],
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
                final data = <String, dynamic>{
                  'content_type': selectedType,
                };
                if (titleCtrl.text.trim().isNotEmpty) {
                  data['title'] = titleCtrl.text.trim();
                }
                if (bodyCtrl.text.trim().isNotEmpty) {
                  data['body'] = bodyCtrl.text.trim();
                }
                if (imageUrlCtrl.text.trim().isNotEmpty) {
                  data['image_url'] = imageUrlCtrl.text.trim();
                }
                if (imageCaptionCtrl.text.trim().isNotEmpty) {
                  data['image_caption'] = imageCaptionCtrl.text.trim();
                }
                data['sort_order'] = contents.length;
                bloc.add(EbdLessonContentCreateRequested(
                  lessonId: lessonId,
                  data: data,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentBlockCard extends StatelessWidget {
  final EbdLessonContent content;
  final String lessonId;
  const _ContentBlockCard({required this.content, required this.lessonId});

  Color get _borderColor {
    switch (content.contentType) {
      case 'bible_reference':
        return const Color(0xFF8D6E63);
      case 'note':
        return AppColors.warning;
      case 'image':
        return AppColors.info;
      default:
        return AppColors.border;
    }
  }

  Color get _bgColor {
    switch (content.contentType) {
      case 'bible_reference':
        return const Color(0xFF8D6E63).withValues(alpha: 0.05);
      case 'note':
        return AppColors.warning.withValues(alpha: 0.05);
      default:
        return AppColors.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: _borderColor, width: content.contentType == 'text' ? 1 : 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(content.typeIcon, size: 16, color: _borderColor),
                const SizedBox(width: AppSpacing.xs),
                Text(content.typeLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: _borderColor,
                      fontWeight: FontWeight.w600,
                    )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.error,
                  onPressed: () {
                    context.read<EbdBloc>().add(EbdLessonContentDeleteRequested(
                      lessonId: lessonId,
                      contentId: content.id,
                    ));
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (content.title != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(content.title!,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
            if (content.body != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(content.body!, style: AppTypography.bodyMedium),
            ],
            if (content.imageUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Image.network(
                  content.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: AppColors.border.withValues(alpha: 0.3),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 32),
                    ),
                  ),
                ),
              ),
              if (content.imageCaption != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(content.imageCaption!,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Tab: Atividades (E2)
// ==========================================

class _ActivitiesTab extends StatelessWidget {
  final String lessonId;
  final List<EbdLessonActivity> activities;
  const _ActivitiesTab({required this.lessonId, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showAddActivityDialog(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        tooltip: 'Adicionar Atividade',
        child: const Icon(Icons.add),
      ),
      body: activities.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_outlined,
                      size: 48,
                      color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSpacing.md),
                  Text('Nenhuma atividade registrada',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Adicione perguntas, tarefas ou dinâmicas',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
              itemCount: activities.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) => _ActivityCard(
                activity: activities[i],
                lessonId: lessonId,
                index: i + 1,
              ),
            ),
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    String selectedType = 'question';
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final bibleRefCtrl = TextEditingController();
    final correctAnswerCtrl = TextEditingController();
    final optionsCtrl = TextEditingController();
    bool isRequired = false;
    final bloc = context.read<EbdBloc>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nova Atividade'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de Atividade'),
                  items: const [
                    DropdownMenuItem(
                        value: 'question', child: Text('❓ Pergunta')),
                    DropdownMenuItem(
                        value: 'multiple_choice',
                        child: Text('📋 Múltipla Escolha')),
                    DropdownMenuItem(
                        value: 'fill_blank', child: Text('📝 Complete')),
                    DropdownMenuItem(
                        value: 'group_activity',
                        child: Text('👥 Dinâmica de Grupo')),
                    DropdownMenuItem(
                        value: 'homework',
                        child: Text('🏠 Tarefa de Casa')),
                    DropdownMenuItem(value: 'other', child: Text('📌 Outro')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? 'question'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Enunciado *',
                    hintText: 'Descreva a atividade...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Instruções (opcional)',
                  ),
                  maxLines: 2,
                ),
                if (selectedType == 'multiple_choice') ...[
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: optionsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Opções (separadas por ;)',
                      hintText: 'a) Opção 1; b) Opção 2; c) Opção 3',
                    ),
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: correctAnswerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Resposta esperada (visível só p/ professor)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: bibleRefCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Referência Bíblica',
                    hintText: 'Ex: Mateus 5:1-12',
                  ),
                ),
                SwitchListTile(
                  title: const Text('Obrigatória'),
                  value: isRequired,
                  onChanged: (v) =>
                      setDialogState(() => isRequired = v),
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
                if (titleCtrl.text.trim().isEmpty) return;
                final data = <String, dynamic>{
                  'activity_type': selectedType,
                  'title': titleCtrl.text.trim(),
                  'is_required': isRequired,
                  'sort_order': activities.length,
                };
                if (descCtrl.text.trim().isNotEmpty) {
                  data['description'] = descCtrl.text.trim();
                }
                if (correctAnswerCtrl.text.trim().isNotEmpty) {
                  data['correct_answer'] = correctAnswerCtrl.text.trim();
                }
                if (bibleRefCtrl.text.trim().isNotEmpty) {
                  data['bible_reference'] = bibleRefCtrl.text.trim();
                }
                if (selectedType == 'multiple_choice' &&
                    optionsCtrl.text.trim().isNotEmpty) {
                  data['options'] = optionsCtrl.text
                      .split(';')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                }
                bloc.add(EbdLessonActivityCreateRequested(
                  lessonId: lessonId,
                  data: data,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final EbdLessonActivity activity;
  final String lessonId;
  final int index;
  const _ActivityCard({
    required this.activity,
    required this.lessonId,
    required this.index,
  });

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Center(
                    child: Text(activity.typeEmoji,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.title,
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(activity.typeLabel,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (activity.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Obrigatória',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontSize: 10,
                        )),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.error,
                  onPressed: () {
                    context.read<EbdBloc>().add(
                          EbdLessonActivityDeleteRequested(
                            lessonId: lessonId,
                            activityId: activity.id,
                          ),
                        );
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (activity.description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(activity.description!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
            if (activity.optionsList.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...activity.optionsList.map((opt) => Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6,
                            color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(opt, style: AppTypography.bodySmall),
                      ],
                    ),
                  )),
            ],
            if (activity.bibleReference != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.auto_stories, size: 14,
                      color: Color(0xFF8D6E63)),
                  const SizedBox(width: 4),
                  Text(activity.bibleReference!,
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFF8D6E63),
                        fontStyle: FontStyle.italic,
                      )),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Tab: Materiais (E4)
// ==========================================

class _MaterialsTab extends StatelessWidget {
  final String lessonId;
  final List<EbdLessonMaterial> materials;
  const _MaterialsTab({required this.lessonId, required this.materials});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final repo = EbdRepository(apiClient: apiClient);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showAddMaterialDialog(context, repo),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        tooltip: 'Adicionar Material',
        child: const Icon(Icons.add),
      ),
      body: materials.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_file,
                      size: 48,
                      color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSpacing.md),
                  Text('Nenhum material adicionado',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Adicione documentos, links e vídeos',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
              itemCount: materials.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) => _MaterialCard(
                material: materials[i],
                lessonId: lessonId,
              ),
            ),
    );
  }

  void _showAddMaterialDialog(BuildContext context, EbdRepository repo) {
    String selectedType = 'link';
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final bloc = context.read<EbdBloc>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Adicionar Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de Material'),
                  items: const [
                    DropdownMenuItem(
                        value: 'link', child: Text('🔗 Link')),
                    DropdownMenuItem(
                        value: 'document', child: Text('📄 Documento')),
                    DropdownMenuItem(
                        value: 'video', child: Text('🎬 Vídeo')),
                    DropdownMenuItem(
                        value: 'audio', child: Text('🎵 Áudio')),
                    DropdownMenuItem(
                        value: 'image', child: Text('🖼️ Imagem')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? 'link'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL *',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                  ),
                  maxLines: 2,
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
                if (titleCtrl.text.trim().isEmpty ||
                    urlCtrl.text.trim().isEmpty) return;
                final data = <String, dynamic>{
                  'material_type': selectedType,
                  'title': titleCtrl.text.trim(),
                  'url': urlCtrl.text.trim(),
                };
                if (descCtrl.text.trim().isNotEmpty) {
                  data['description'] = descCtrl.text.trim();
                }
                bloc.add(EbdLessonContentCreateRequested(
                  lessonId: lessonId,
                  data: data,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final EbdLessonMaterial material;
  final String lessonId;
  const _MaterialCard({required this.material, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
          child: Icon(material.typeIcon, size: 20, color: AppColors.accent),
        ),
        title: Text(material.title,
            style: AppTypography.bodyMedium
                .copyWith(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(material.typeLabel,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            if (material.description != null)
              Text(material.description!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          color: AppColors.error,
          onPressed: () {
            // Use content delete event as workaround - should use material-specific event
            context.read<EbdBloc>().add(EbdLessonContentDeleteRequested(
              lessonId: lessonId,
              contentId: material.id,
            ));
          },
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

// ==========================================
// Tab: Frequência (resumo)
// ==========================================

class _AttendanceTab extends StatelessWidget {
  final String lessonId;
  final List<EbdAttendanceDetail> attendance;
  const _AttendanceTab({required this.lessonId, required this.attendance});

  @override
  Widget build(BuildContext context) {
    if (attendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 48,
                color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text('Nenhuma frequência registrada',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () =>
                  context.pushNamed('ebd-attendance', pathParameters: {
                'lessonId': lessonId,
              }),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Registrar Frequência'),
            ),
          ],
        ),
      );
    }

    final present =
        attendance.where((a) => a.status == 'presente').length;
    final absent =
        attendance.where((a) => a.status == 'ausente').length;
    final justified =
        attendance.where((a) => a.status == 'justificado').length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttendanceStatCard(
                  label: 'Presentes',
                  value: '$present',
                  color: AppColors.success),
              _AttendanceStatCard(
                  label: 'Ausentes',
                  value: '$absent',
                  color: AppColors.error),
              _AttendanceStatCard(
                  label: 'Justificados',
                  value: '$justified',
                  color: AppColors.warning),
              _AttendanceStatCard(
                  label: 'Total',
                  value: '${attendance.length}',
                  color: AppColors.info),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: attendance.length,
            itemBuilder: (ctx, i) {
              final a = attendance[i];
              Color statusColor;
              switch (a.status) {
                case 'presente':
                  statusColor = AppColors.success;
                  break;
                case 'ausente':
                  statusColor = AppColors.error;
                  break;
                case 'justificado':
                  statusColor = AppColors.warning;
                  break;
                default:
                  statusColor = AppColors.textMuted;
              }
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Icon(
                    a.status == 'presente'
                        ? Icons.check
                        : a.status == 'ausente'
                            ? Icons.close
                            : Icons.schedule,
                    size: 14,
                    color: statusColor,
                  ),
                ),
                title: Text(a.displayName,
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w500)),
                subtitle: Row(
                  children: [
                    Text(a.statusLabel,
                        style: AppTypography.bodySmall
                            .copyWith(color: statusColor, fontSize: 11)),
                    if (a.broughtBible == true) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.book, size: 12,
                          color: AppColors.accent),
                    ],
                    if (a.broughtMagazine == true) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.menu_book, size: 12,
                          color: AppColors.accent),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AttendanceStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AttendanceStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTypography.headingSmall.copyWith(color: color)),
        Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}
