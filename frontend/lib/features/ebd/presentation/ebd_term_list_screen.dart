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
        trailing: Container(
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
      ),
    );
  }
}
