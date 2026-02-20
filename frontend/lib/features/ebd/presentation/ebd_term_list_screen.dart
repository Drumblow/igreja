import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/ebd_bloc.dart';
import '../bloc/ebd_event_state.dart';
import '../data/ebd_repository.dart';
import '../data/models/ebd_models.dart';

class EbdTermListScreen extends StatelessWidget {
  const EbdTermListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => EbdBloc(
        repository: EbdRepository(apiClient: apiClient),
      )..add(const EbdTermsLoadRequested()),
      child: const _TermListView(),
    );
  }
}

class _TermListView extends StatelessWidget {
  const _TermListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Trimestres EBD')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Trimestre'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<EbdBloc, EbdState>(
        listener: (context, state) {
          if (state is EbdSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<EbdBloc>().add(const EbdTermsLoadRequested());
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
          if (state is EbdTermsLoaded) {
            if (state.terms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range_outlined,
                        size: 64,
                        color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.md),
                    Text('Nenhum trimestre cadastrado',
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
              itemCount: state.terms.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) => _TermTile(term: state.terms[i]),
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
                        .add(const EbdTermsLoadRequested()),
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
    final themeCtrl = TextEditingController();
    final magazineCtrl = TextEditingController();
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
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: themeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tema',
                    hintText: 'Tema do trimestre (opcional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: magazineCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Revista',
                    hintText: 'Título da revista (opcional)',
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
                context.read<EbdBloc>().add(EbdTermCreateRequested(
                      data: {
                        'name': nameCtrl.text.trim(),
                        'start_date':
                            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                        'end_date':
                            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                        if (themeCtrl.text.trim().isNotEmpty)
                          'theme': themeCtrl.text.trim(),
                        if (magazineCtrl.text.trim().isNotEmpty)
                          'magazine_title': magazineCtrl.text.trim(),
                      },
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

class _TermTile extends StatelessWidget {
  final EbdTerm term;
  const _TermTile({required this.term});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor:
              term.isActive ? AppColors.accent.withValues(alpha: 0.15) : AppColors.border,
          child: Icon(
            Icons.date_range_outlined,
            color: term.isActive ? AppColors.accent : AppColors.textMuted,
            size: 20,
          ),
        ),
        title: Text(term.name,
            style: AppTypography.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${term.startDate} → ${term.endDate}',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            if (term.theme != null)
              Text(
                'Tema: ${term.theme}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (term.isActive ? AppColors.success : AppColors.textMuted)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                term.statusLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: term.isActive ? AppColors.success : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    _showEditTermDialog(context);
                    break;
                  case 'clone':
                    _showCloneDialog(context);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: ListTile(
                  leading: Icon(Icons.edit_outlined, size: 20),
                  title: Text('Editar'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
                const PopupMenuItem(value: 'clone', child: ListTile(
                  leading: Icon(Icons.copy_outlined, size: 20),
                  title: Text('Clonar Turmas'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
                const PopupMenuItem(value: 'delete', child: ListTile(
                  leading: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  title: Text('Excluir', style: TextStyle(color: AppColors.error)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTermDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: term.name);
    final themeCtrl = TextEditingController(text: term.theme ?? '');
    final magazineCtrl = TextEditingController(text: term.magazineTitle ?? '');
    DateTime startDate = DateTime.tryParse(term.startDate) ?? DateTime.now();
    DateTime endDate = DateTime.tryParse(term.endDate) ??
        DateTime.now().add(const Duration(days: 90));
    bool isActive = term.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Trimestre'),
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
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: themeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tema',
                    hintText: 'Tema do trimestre (opcional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: magazineCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Revista',
                    hintText: 'Título da revista (opcional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  title: const Text('Trimestre Ativo'),
                  subtitle: Text(
                    isActive
                        ? 'Ativar este trimestre desativará os demais'
                        : 'Trimestre encerrado',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
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
                context.read<EbdBloc>().add(EbdTermUpdateRequested(
                      termId: term.id,
                      data: {
                        'name': nameCtrl.text.trim(),
                        'start_date':
                            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                        'end_date':
                            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                        'is_active': isActive,
                        if (themeCtrl.text.trim().isNotEmpty)
                          'theme': themeCtrl.text.trim(),
                        if (magazineCtrl.text.trim().isNotEmpty)
                          'magazine_title': magazineCtrl.text.trim(),
                      },
                    ));
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloneDialog(BuildContext context) {
    // Clone turmas de outro trimestre para este
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final repo = EbdRepository(apiClient: apiClient);
    bool includeEnrollments = false;
    String? selectedSourceTermId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Clonar Turmas'),
            content: FutureBuilder<List<EbdTerm>>(
              future: repo.getTerms(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final otherTerms = snapshot.data!
                    .where((t) => t.id != term.id)
                    .toList();
                if (otherTerms.isEmpty) {
                  return const Text(
                      'Não há outros trimestres para clonar turmas.');
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Copiar turmas de outro trimestre para "${term.name}"',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: selectedSourceTermId,
                      decoration: const InputDecoration(
                          labelText: 'Trimestre de Origem'),
                      items: otherTerms
                          .map((t) => DropdownMenuItem(
                              value: t.id, child: Text(t.name)))
                          .toList(),
                      onChanged: (v) => setDialogState(
                          () => selectedSourceTermId = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      title: const Text('Incluir matrículas'),
                      subtitle: Text(
                        includeEnrollments
                            ? 'Alunos serão copiados para as novas turmas'
                            : 'Apenas turmas serão criadas, sem alunos',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      value: includeEnrollments,
                      onChanged: (v) =>
                          setDialogState(() => includeEnrollments = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (selectedSourceTermId == null) return;
                  context.read<EbdBloc>().add(EbdCloneClassesRequested(
                    termId: term.id,
                    sourceTermId: selectedSourceTermId!,
                    includeEnrollments: includeEnrollments,
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('Clonar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Trimestre'),
        content: Text(
          'Tem certeza que deseja excluir o trimestre "${term.name}"?\n\n'
          'Todas as turmas, aulas e frequências vinculadas serão removidas. '
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
                    EbdTermDeleteRequested(termId: term.id),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
