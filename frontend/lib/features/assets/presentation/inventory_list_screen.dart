import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../bloc/asset_bloc.dart';
import '../bloc/asset_event_state.dart';
import '../data/asset_repository.dart';
import '../data/models/asset_models.dart';

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final congCubit = context.read<CongregationContextCubit>();
    return BlocProvider(
      create: (_) => AssetBloc(
        repository: AssetRepository(apiClient: apiClient),
        congregationCubit: congCubit,
      )..add(const InventoriesLoadRequested()),
      child: const _InventoryListView(),
    );
  }
}

class _InventoryListView extends StatelessWidget {
  const _InventoryListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Inventários')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Inventário'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<AssetBloc, AssetState>(
        listener: (context, state) {
          if (state is AssetSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<AssetBloc>().add(const InventoriesLoadRequested());
          }
          if (state is AssetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AssetLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }
          if (state is InventoriesLoaded) {
            if (state.inventories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fact_check_outlined,
                        size: 64,
                        color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.md),
                    Text('Nenhum inventário realizado',
                        style: AppTypography.bodyLarge
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100,
              ),
              itemCount: state.inventories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) =>
                  _InventoryTile(inventory: state.inventories[i]),
            );
          }
          if (state is AssetError) {
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
                        .read<AssetBloc>()
                        .add(const InventoriesLoadRequested()),
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
    DateTime refDate = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Novo Inventário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: refDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setDialogState(() => refDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de Referência',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    '${refDate.day.toString().padLeft(2, '0')}/${refDate.month.toString().padLeft(2, '0')}/${refDate.year}',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().length < 2) return;
                context.read<AssetBloc>().add(InventoryCreateRequested(
                      data: {
                        'name': nameCtrl.text.trim(),
                        'reference_date':
                            '${refDate.year}-${refDate.month.toString().padLeft(2, '0')}-${refDate.day.toString().padLeft(2, '0')}',
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

class _InventoryTile extends StatelessWidget {
  final Inventory inventory;
  const _InventoryTile({required this.inventory});

  Color _statusColor() {
    switch (inventory.status) {
      case 'aberto':
        return AppColors.info;
      case 'em_andamento':
        return AppColors.warning;
      case 'fechado':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

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
                Expanded(
                  child: Text(inventory.name,
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    inventory.statusLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: _statusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Referência: ${inventory.referenceDate}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            if (inventory.totalItems != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _Chip(
                      label: 'Total: ${inventory.totalItems}',
                      color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  if (inventory.foundItems != null)
                    _Chip(
                        label: 'Encontrados: ${inventory.foundItems}',
                        color: AppColors.success),
                  const SizedBox(width: AppSpacing.xs),
                  if (inventory.missingItems != null &&
                      inventory.missingItems! > 0)
                    _Chip(
                        label: 'Faltando: ${inventory.missingItems}',
                        color: AppColors.error),
                ],
              ),
            ],
            if (inventory.status != 'fechado') ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AssetBloc>().add(
                          InventoryCloseRequested(inventoryId: inventory.id),
                        );
                  },
                  icon: const Icon(Icons.lock_outline, size: 16),
                  label: const Text('Fechar Inventário'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: AppTypography.bodySmall
              .copyWith(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
