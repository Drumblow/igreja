import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/congregation_badge.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../bloc/asset_bloc.dart';
import '../bloc/asset_event_state.dart';
import '../data/asset_repository.dart';
import '../data/models/asset_models.dart';

class AssetListScreen extends StatelessWidget {
  const AssetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final congCubit = context.read<CongregationContextCubit>();
    return BlocProvider(
      create: (_) => AssetBloc(
        repository: AssetRepository(apiClient: apiClient),
        congregationCubit: congCubit,
      )..add(AssetsLoadRequested(
          congregationId: congCubit.state.activeCongregationId,
        )),
      child: const _AssetListView(),
    );
  }
}

class _AssetListView extends StatefulWidget {
  const _AssetListView();

  @override
  State<_AssetListView> createState() => _AssetListViewState();
}

class _AssetListViewState extends State<_AssetListView> {
  final _searchCtrl = TextEditingController();
  String? _statusFilter;
  String? _categoryFilter;
  List<AssetCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final repo = AssetRepository(apiClient: apiClient);
      final result = await repo.getCategories(page: 1, perPage: 100);
      if (mounted) {
        setState(() => _categories = result.items);
      }
    } catch (_) {
      // Categories are non-critical for filtering
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<AssetBloc>().add(AssetsLoadRequested(
          search: query.isEmpty ? null : query,
          status: _statusFilter,
          categoryId: _categoryFilter,
        ));
  }

  void _onStatusFilter(String? status) {
    setState(() => _statusFilter = status);
    context.read<AssetBloc>().add(AssetsLoadRequested(
          search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
          status: status,
          categoryId: _categoryFilter,
        ));
  }

  void _onCategoryFilter(String? categoryId) {
    setState(() => _categoryFilter = categoryId);
    context.read<AssetBloc>().add(AssetsLoadRequested(
          search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
          status: _statusFilter,
          categoryId: categoryId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bens Patrimoniais')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/assets/items/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Bem'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Buscar por código ou descrição...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String?>(
                  value: _statusFilter,
                  hint: const Text('Status'),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'ativo', child: Text('Ativo')),
                    DropdownMenuItem(value: 'em_manutencao', child: Text('Em Manutenção')),
                    DropdownMenuItem(value: 'baixado', child: Text('Baixado')),
                    DropdownMenuItem(value: 'cedido', child: Text('Cedido')),
                  ],
                  onChanged: _onStatusFilter,
                ),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String?>(
                  value: _categoryFilter,
                  hint: const Text('Categoria'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ..._categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: _onCategoryFilter,
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: BlocBuilder<AssetBloc, AssetState>(
              builder: (context, state) {
                if (state is AssetLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                if (state is AssetError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(state.message, style: AppTypography.bodyMedium),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: () => context
                              .read<AssetBloc>()
                              .add(const AssetsLoadRequested()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is AssetListLoaded) {
                  if (state.assets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64,
                              color: AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            state.activeSearch != null
                                ? 'Nenhum bem encontrado'
                                : 'Nenhum bem cadastrado',
                            style: AppTypography.bodyLarge
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100,
                    ),
                    itemCount: state.assets.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      if (i == state.assets.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: () => context.read<AssetBloc>().add(
                                AssetsLoadRequested(
                                  page: state.currentPage + 1,
                                  search: state.activeSearch,
                                  status: state.activeStatus,
                                  condition: state.activeCondition,
                                  categoryId: _categoryFilter,
                                ),
                              ),
                              icon: const Icon(Icons.expand_more),
                              label: const Text('Carregar mais'),
                            ),
                          ),
                        );
                      }
                      return _AssetTile(asset: state.assets[i]);
                    },
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
}

class _AssetTile extends StatelessWidget {
  final Asset asset;
  const _AssetTile({required this.asset});

  Color _statusColor() {
    switch (asset.status) {
      case 'ativo':
        return AppColors.success;
      case 'em_manutencao':
        return AppColors.warning;
      case 'baixado':
        return AppColors.error;
      case 'cedido':
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }

  Color _conditionColor() {
    switch (asset.condition) {
      case 'novo':
        return AppColors.success;
      case 'bom':
        return Colors.green.shade400;
      case 'regular':
        return AppColors.warning;
      case 'ruim':
        return Colors.orange;
      case 'inservivel':
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
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.go('/assets/items/${asset.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            asset.assetCode,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _BadgePill(
                          label: asset.statusLabel,
                          color: _statusColor(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      asset.description,
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CongregationBadge(congregationName: asset.congregationName),
                        if (asset.congregationName != null && asset.congregationName!.isNotEmpty)
                          const SizedBox(width: AppSpacing.xs),
                        if (asset.categoryName != null)
                          Text(
                            asset.categoryName!,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        if (asset.location != null) ...[
                          if (asset.categoryName != null)
                            Text(' • ',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textMuted)),
                          Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Text(
                            asset.location!,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                        const Spacer(),
                        _BadgePill(
                          label: asset.conditionLabel,
                          color: _conditionColor(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
