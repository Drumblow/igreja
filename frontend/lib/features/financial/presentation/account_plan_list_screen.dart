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

class AccountPlanListScreen extends StatelessWidget {
  const AccountPlanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final congCubit = context.read<CongregationContextCubit>();
    return BlocProvider(
      create: (_) => FinancialBloc(
        repository: FinancialRepository(apiClient: apiClient),
        congregationCubit: congCubit,
      )..add(const AccountPlansLoadRequested()),
      child: const _AccountPlanListView(),
    );
  }
}

class _AccountPlanListView extends StatelessWidget {
  const _AccountPlanListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/financial')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plano de Contas', style: AppTypography.headingLarge),
                      const SizedBox(height: AppSpacing.xs),
                      BlocBuilder<FinancialBloc, FinancialState>(
                        builder: (context, state) {
                          final count = state is AccountPlansLoaded ? state.totalCount : 0;
                          return Text('$count categorias', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: BlocBuilder<FinancialBloc, FinancialState>(
              builder: (context, state) {
                if (state is FinancialLoading) return const Center(child: CircularProgressIndicator());
                if (state is FinancialError) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.error_outline, size: 56, color: AppColors.error.withValues(alpha: 0.5)),
                      const SizedBox(height: AppSpacing.md),
                      Text('Erro ao carregar', style: AppTypography.headingSmall.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => context.read<FinancialBloc>().add(const AccountPlansLoadRequested()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ]),
                  );
                }
                if (state is AccountPlansLoaded) {
                  if (state.plans.isEmpty) {
                    return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.account_tree_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: AppSpacing.md),
                        Text('Nenhuma categoria cadastrada', style: AppTypography.headingSmall.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Crie categorias de receita e despesa', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                      ]),
                    );
                  }

                  final receitas = state.plans.where((p) => p.type == 'receita').toList();
                  final despesas = state.plans.where((p) => p.type == 'despesa').toList();

                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      if (receitas.isNotEmpty) ...[
                        _SectionHeader(title: 'Receitas', count: receitas.length, color: AppColors.success),
                        const SizedBox(height: AppSpacing.sm),
                        ...receitas.map((p) => _AccountPlanTile(plan: p)),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (despesas.isNotEmpty) ...[
                        _SectionHeader(title: 'Despesas', count: despesas.length, color: AppColors.error),
                        const SizedBox(height: AppSpacing.sm),
                        ...despesas.map((p) => _AccountPlanTile(plan: p)),
                      ],
                    ],
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
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
      ),
    );
  }

  void _showCreateDialog(BuildContext outerContext) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    String type = 'receita';

    showDialog(
      context: outerContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Categoria'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'receita', label: Text('Receita')),
                    ButtonSegment(value: 'despesa', label: Text('Despesa')),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setDialogState(() => type = s.first),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Código *', hintText: 'Ex: 1.01'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome *', hintText: 'Ex: Dízimos'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (codeController.text.isEmpty || nameController.text.isEmpty) return;
                outerContext.read<FinancialBloc>().add(AccountPlanCreateRequested(data: {
                  'code': codeController.text.trim(),
                  'name': nameController.text.trim(),
                  'type': type,
                }));
                Navigator.pop(dialogContext);
                // Reload after a short delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (!outerContext.mounted) return;
                  outerContext.read<FinancialBloc>().add(const AccountPlansLoadRequested());
                });
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.headingSmall.copyWith(color: color)),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _AccountPlanTile extends StatelessWidget {
  final AccountPlan plan;

  const _AccountPlanTile({required this.plan});

  @override
  Widget build(BuildContext context) {
    final isActive = plan.isActive;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: AppSpacing.md + (plan.level - 1) * 16.0),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (plan.type == 'receita' ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(
              child: Text(plan.code, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
            ),
          ),
          title: Text(
            plan.name,
            style: AppTypography.labelLarge.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textMuted,
              decoration: isActive ? null : TextDecoration.lineThrough,
            ),
          ),
          subtitle: plan.parentName != null
              ? Text('Subcategoria de ${plan.parentName}', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted))
              : null,
          trailing: isActive
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('Inativa', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                ),
        ),
      ),
    );
  }
}
