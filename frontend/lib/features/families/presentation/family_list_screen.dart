import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event_state.dart';
import '../data/family_repository.dart';
import '../data/models/family_models.dart';

class FamilyListScreen extends StatelessWidget {
  const FamilyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => FamilyBloc(
        repository: FamilyRepository(apiClient: apiClient),
      )..add(const FamiliesLoadRequested()),
      child: const _FamilyListView(),
    );
  }
}

class _FamilyListView extends StatefulWidget {
  const _FamilyListView();

  @override
  State<_FamilyListView> createState() => _FamilyListViewState();
}

class _FamilyListViewState extends State<_FamilyListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    context.read<FamilyBloc>().add(FamiliesLoadRequested(
          search:
              _searchController.text.isEmpty ? null : _searchController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          const Divider(height: 1),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/families/new'),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Nova Família'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Famílias', style: AppTypography.headingLarge),
                const SizedBox(height: AppSpacing.xs),
                BlocBuilder<FamilyBloc, FamilyState>(
                  builder: (context, state) {
                    final count =
                        state is FamilyListLoaded ? state.totalCount : 0;
                    return Text(
                      '$count famílias cadastradas',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SizedBox(
        height: 42,
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => _search(),
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Buscar por nome da família...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _search();
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return BlocBuilder<FamilyBloc, FamilyState>(
      builder: (context, state) {
        if (state is FamilyLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (state is FamilyError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48,
                    color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<FamilyBloc>()
                      .add(const FamiliesLoadRequested()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (state is FamilyListLoaded) {
          if (state.families.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.family_restroom_outlined,
                      size: 64,
                      color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Nenhuma família encontrada',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Cadastre a primeira família da sua igreja.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.families.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == state.families.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<FamilyBloc>().add(
                        FamiliesLoadRequested(
                          page: state.currentPage + 1,
                          search: state.activeSearch,
                        ),
                      ),
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Carregar mais'),
                    ),
                  ),
                );
              }
              return _FamilyTile(family: state.families[index]);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _FamilyTile extends StatelessWidget {
  final Family family;

  const _FamilyTile({required this.family});

  @override
  Widget build(BuildContext context) {
    final memberCount = family.members?.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.go('/families/${family.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Icon
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.family_restroom_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family.name,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      family.cityState.isNotEmpty
                          ? family.cityState
                          : 'Endereço não informado',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Member count badge
              if (memberCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '$memberCount ${memberCount == 1 ? 'membro' : 'membros'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),

              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
