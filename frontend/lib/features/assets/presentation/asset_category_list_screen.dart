import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/asset_bloc.dart';
import '../bloc/asset_event_state.dart';
import '../data/asset_repository.dart';
import '../data/models/asset_models.dart';

class AssetCategoryListScreen extends StatelessWidget {
  const AssetCategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => AssetBloc(
        repository: AssetRepository(apiClient: apiClient),
      )..add(const AssetCategoriesLoadRequested()),
      child: const _CategoryListView(),
    );
  }
}

class _CategoryListView extends StatelessWidget {
  const _CategoryListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Categorias de Patrimônio')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Categoria'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<AssetBloc, AssetState>(
        listener: (context, state) {
          if (state is AssetSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context
                .read<AssetBloc>()
                .add(const AssetCategoriesLoadRequested());
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
          if (state is AssetCategoriesLoaded) {
            if (state.categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_outlined,
                        size: 64,
                        color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.md),
                    Text('Nenhuma categoria cadastrada',
                        style: AppTypography.bodyLarge
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) =>
                  _CategoryTile(category: state.categories[i]),
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
                        .add(const AssetCategoriesLoadRequested()),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Categoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome *'),
              autofocus: true,
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
              context.read<AssetBloc>().add(AssetCategoryCreateRequested(
                    data: {'name': nameCtrl.text.trim()},
                  ));
              Navigator.pop(ctx);
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final AssetCategory category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Icon(Icons.category_outlined,
              color: AppColors.accent, size: 20),
        ),
        title: Text(category.name,
            style: AppTypography.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: category.assetsCount != null
            ? Text('${category.assetsCount} bens',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary))
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      ),
    );
  }
}
