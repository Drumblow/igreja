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

class CampaignListScreen extends StatelessWidget {
  const CampaignListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final congCubit = context.read<CongregationContextCubit>();
    return BlocProvider(
      create: (_) => FinancialBloc(
        repository: FinancialRepository(apiClient: apiClient),
        congregationCubit: congCubit,
      )..add(const CampaignsLoadRequested()),
      child: const _CampaignListView(),
    );
  }
}

class _CampaignListView extends StatelessWidget {
  const _CampaignListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
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
                      Text('Campanhas', style: AppTypography.headingLarge),
                      const SizedBox(height: AppSpacing.xs),
                      BlocBuilder<FinancialBloc, FinancialState>(
                        builder: (context, state) {
                          final count = state is CampaignsLoaded ? state.totalCount : 0;
                          return Text('$count campanhas', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary));
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
                      OutlinedButton.icon(
                        onPressed: () => context.read<FinancialBloc>().add(const CampaignsLoadRequested()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ]),
                  );
                }
                if (state is CampaignsLoaded) {
                  if (state.campaigns.isEmpty) {
                    return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.campaign_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: AppSpacing.md),
                        Text('Nenhuma campanha cadastrada', style: AppTypography.headingSmall.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Crie campanhas para arrecadações especiais', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                      ]),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: state.campaigns.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _CampaignTile(campaign: state.campaigns[index]),
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
        label: const Text('Nova Campanha'),
      ),
    );
  }

  void _showCreateDialog(BuildContext outerContext) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final goalController = TextEditingController();
    DateTime startDate = DateTime.now();

    showDialog(
      context: outerContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Campanha'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome *', hintText: 'Ex: Construção do templo')),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 2),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: goalController,
                  decoration: const InputDecoration(labelText: 'Meta (R\$)', prefixText: 'R\$ ', hintText: 'Opcional'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => startDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Data de Início *', suffixIcon: Icon(Icons.calendar_today, size: 18)),
                    child: Text('${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                final data = <String, dynamic>{
                  'name': nameController.text.trim(),
                  'start_date': '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                  if (descriptionController.text.isNotEmpty) 'description': descriptionController.text.trim(),
                  if (goalController.text.isNotEmpty) 'goal_amount': double.tryParse(goalController.text.replaceAll(',', '.')) ?? 0,
                };
                outerContext.read<FinancialBloc>().add(CampaignCreateRequested(data: data));
                Navigator.pop(dialogContext);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (!outerContext.mounted) return;
                  outerContext.read<FinancialBloc>().add(const CampaignsLoadRequested());
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

class _CampaignTile extends StatelessWidget {
  final Campaign campaign;

  const _CampaignTile({required this.campaign});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (campaign.status) {
      case 'ativa':
        statusColor = AppColors.success;
        break;
      case 'encerrada':
        statusColor = AppColors.info;
        break;
      default:
        statusColor = AppColors.textMuted;
    }

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
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.campaign_outlined, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(campaign.name, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                      if (campaign.description != null)
                        Text(campaign.description!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(campaign.statusLabel, style: AppTypography.bodySmall.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            // Progress
            if (campaign.goalAmount != null && campaign.goalAmount! > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Arrecadado: ${formatCurrency(campaign.raisedAmount)}', style: AppTypography.bodySmall.copyWith(color: AppColors.success)),
                  Text('Meta: ${formatCurrency(campaign.goalAmount!)}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: campaign.progressPercent,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(campaign.progressPercent >= 1.0 ? AppColors.success : AppColors.accent),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${(campaign.progressPercent * 100).toStringAsFixed(1)}% da meta',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
