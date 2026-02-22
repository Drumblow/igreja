import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/searchable_entity_dropdown.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../../financial/presentation/format_utils.dart';
import '../bloc/asset_bloc.dart';
import '../bloc/asset_event_state.dart';
import '../data/asset_repository.dart';
import '../data/models/asset_models.dart';

class MaintenanceListScreen extends StatelessWidget {
  const MaintenanceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final congCubit = context.read<CongregationContextCubit>();
    return BlocProvider(
      create: (_) => AssetBloc(
        repository: AssetRepository(apiClient: apiClient),
        congregationCubit: congCubit,
      )..add(const MaintenancesLoadRequested()),
      child: const _MaintenanceListView(),
    );
  }
}

class _MaintenanceListView extends StatefulWidget {
  const _MaintenanceListView();

  @override
  State<_MaintenanceListView> createState() => _MaintenanceListViewState();
}

class _MaintenanceListViewState extends State<_MaintenanceListView> {
  String? _statusFilter;

  void _onStatusFilter(String? status) {
    setState(() => _statusFilter = status);
    context.read<AssetBloc>().add(MaintenancesLoadRequested(status: status));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Manutenções')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Manutenção'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text('Filtrar:', style: AppTypography.bodyMedium),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String?>(
                  value: _statusFilter,
                  hint: const Text('Status'),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'agendada', child: Text('Agendada')),
                    DropdownMenuItem(value: 'em_andamento', child: Text('Em Andamento')),
                    DropdownMenuItem(value: 'concluida', child: Text('Concluída')),
                    DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                  ],
                  onChanged: _onStatusFilter,
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<AssetBloc, AssetState>(
              listener: (context, state) {
                if (state is AssetSaved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  context
                      .read<AssetBloc>()
                      .add(const MaintenancesLoadRequested());
                }
              },
              builder: (context, state) {
                if (state is AssetLoading) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                if (state is MaintenancesLoaded) {
                  if (state.maintenances.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build_outlined,
                              size: 64,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: AppSpacing.md),
                          Text('Nenhuma manutenção registrada',
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
                    itemCount: state.maintenances.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) =>
                        _MaintenanceTile(maintenance: state.maintenances[i]),
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
                              .add(const MaintenancesLoadRequested()),
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
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final assetRepo = AssetRepository(apiClient: apiClient);

    final descCtrl = TextEditingController();
    EntityOption? selectedAsset;
    String type = 'preventiva';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nova Manutenção'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableEntityDropdown(
                    label: 'Bem *',
                    hint: 'Busque pelo código ou descrição...',
                    onSelected: (entity) => selectedAsset = entity,
                    searchCallback: (query) async {
                      final result = await assetRepo.getAssets(
                        search: query,
                        perPage: 20,
                      );
                      return result.items
                          .map((a) => EntityOption(
                                id: a.id,
                                label: '${a.assetCode} - ${a.description}',
                              ))
                          .toList();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                          value: 'preventiva', child: Text('Preventiva')),
                      DropdownMenuItem(
                          value: 'corretiva', child: Text('Corretiva')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => type = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descrição *'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedAsset == null ||
                    descCtrl.text.trim().length < 2) return;
                context.read<AssetBloc>().add(MaintenanceCreateRequested(
                      data: {
                        'asset_id': selectedAsset!.id,
                        'type': type,
                        'description': descCtrl.text.trim(),
                      },
                    ));
                Navigator.pop(ctx);
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceTile extends StatelessWidget {
  final Maintenance maintenance;
  const _MaintenanceTile({required this.maintenance});

  Color _statusColor() {
    switch (maintenance.status) {
      case 'agendada':
        return AppColors.info;
      case 'em_andamento':
        return AppColors.warning;
      case 'concluida':
        return AppColors.success;
      case 'cancelada':
        return AppColors.error;
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: maintenance.maintenanceType == 'preventiva'
                        ? AppColors.info.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    maintenance.typeLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: maintenance.maintenanceType == 'preventiva'
                          ? AppColors.info
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    maintenance.statusLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: _statusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(maintenance.description,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            if (maintenance.assetDescription != null) ...[
              const SizedBox(height: 4),
              Text(
                'Bem: ${maintenance.assetCode ?? ''} - ${maintenance.assetDescription}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (maintenance.cost != null) ...[
              const SizedBox(height: 4),
              Text(
                'Custo: ${formatCurrency(maintenance.cost!)}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
