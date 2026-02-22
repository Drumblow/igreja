import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../bloc/financial_bloc.dart';
import '../bloc/financial_event_state.dart';
import '../data/financial_repository.dart';
import '../data/models/financial_models.dart';
import 'format_utils.dart';

class MonthlyClosingListScreen extends StatelessWidget {
  const MonthlyClosingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final congCubit = context.read<CongregationContextCubit>();
    return BlocProvider(
      create: (_) => FinancialBloc(
        repository: FinancialRepository(apiClient: apiClient),
        congregationCubit: congCubit,
      )..add(const MonthlyClosingsLoadRequested()),
      child: const _MonthlyClosingListView(),
    );
  }
}

class _MonthlyClosingListView extends StatelessWidget {
  const _MonthlyClosingListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/financial'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fechamentos Mensais', style: AppTypography.headingLarge),
                      const SizedBox(height: AppSpacing.xs),
                      BlocBuilder<FinancialBloc, FinancialState>(
                        builder: (context, state) {
                          final count = state is MonthlyClosingsLoaded
                              ? state.totalCount
                              : 0;
                          return Text(
                            '$count fechamento${count != 1 ? 's' : ''}',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── List ──
          Expanded(
            child: BlocConsumer<FinancialBloc, FinancialState>(
              listener: (context, state) {
                if (state is FinancialSaved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.read<FinancialBloc>().add(
                        const MonthlyClosingsLoadRequested(),
                      );
                }
                if (state is FinancialError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is FinancialLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is FinancialError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 56,
                            color: AppColors.error.withValues(alpha: 0.5)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Erro ao carregar fechamentos',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: () => context
                              .read<FinancialBloc>()
                              .add(const MonthlyClosingsLoadRequested()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is MonthlyClosingsLoaded) {
                  if (state.closings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note_outlined,
                              size: 64,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Nenhum fechamento realizado',
                            style: AppTypography.headingSmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Realize o fechamento mensal para consolidar as finanças',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: state.closings.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        _ClosingTile(closing: state.closings[index]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        icon: const Icon(Icons.lock_clock_outlined),
        label: const Text('Novo Fechamento'),
      ),
    );
  }

  void _showCreateDialog(BuildContext outerContext) {
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month > 1 ? now.month - 1 : 12;
    if (now.month == 1) selectedYear = now.year - 1;
    final notesController = TextEditingController();

    showDialog(
      context: outerContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo Fechamento Mensal'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'O fechamento consolida todas as receitas e despesas do mês, '
                  'impedindo alterações nos lançamentos desse período.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Month selector
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Mês *',
                        ),
                        value: selectedMonth,
                        items: List.generate(12, (i) {
                          final m = i + 1;
                          return DropdownMenuItem(
                            value: m,
                            child: Text(_monthName(m)),
                          );
                        }),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => selectedMonth = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Ano *',
                        ),
                        value: selectedYear,
                        items: List.generate(5, (i) {
                          final y = now.year - 2 + i;
                          return DropdownMenuItem(
                            value: y,
                            child: Text('$y'),
                          );
                        }),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => selectedYear = v);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    hintText: 'Notas sobre o fechamento (opcional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                final referenceMonth =
                    '${selectedYear.toString().padLeft(4, '0')}-${selectedMonth.toString().padLeft(2, '0')}';
                final data = <String, dynamic>{
                  'reference_month': referenceMonth,
                  if (notesController.text.trim().isNotEmpty)
                    'notes': notesController.text.trim(),
                };
                outerContext
                    .read<FinancialBloc>()
                    .add(MonthlyClosingCreateRequested(data: data));
                Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Fechar Mês'),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return months[month - 1];
  }
}

// ── Closing Tile ──

class _ClosingTile extends StatelessWidget {
  final MonthlyClosing closing;

  const _ClosingTile({required this.closing});

  @override
  Widget build(BuildContext context) {
    final parts = closing.referenceMonth.split('-');
    final year = parts.isNotEmpty ? parts[0] : '';
    final monthNum =
        parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final monthLabel =
        monthNum >= 1 && monthNum <= 12
            ? _MonthlyClosingListView._monthName(monthNum)
            : closing.referenceMonth;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.event_available_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$monthLabel $year',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      if (closing.closedByName != null)
                        Text(
                          'Fechado por ${closing.closedByName}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Fechado',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            // Financial summary
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Receitas',
                    value: formatCurrency(closing.totalIncome),
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Despesas',
                    value: formatCurrency(closing.totalExpense),
                    color: AppColors.error,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Saldo',
                    value: formatCurrency(closing.balance),
                    color: closing.balance >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),

            if (closing.accumulatedBalance != 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo Anterior: ${formatCurrency(closing.previousBalance)}',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                  Text(
                    'Acumulado: ${formatCurrency(closing.accumulatedBalance)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            if (closing.notes != null && closing.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                closing.notes!,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (closing.createdAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Realizado em ${_formatDate(closing.createdAt!)}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}'
        ' às ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
