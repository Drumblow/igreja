import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/ministry_bloc.dart';
import '../bloc/ministry_event_state.dart';
import '../data/ministry_repository.dart';
import '../data/models/ministry_models.dart';

class MinistryListScreen extends StatelessWidget {
  const MinistryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => MinistryBloc(
        repository: MinistryRepository(apiClient: apiClient),
      )..add(const MinistriesLoadRequested()),
      child: const _MinistryListView(),
    );
  }
}

class _MinistryListView extends StatefulWidget {
  const _MinistryListView();

  @override
  State<_MinistryListView> createState() => _MinistryListViewState();
}

class _MinistryListViewState extends State<_MinistryListView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<MinistryBloc>().add(MinistriesLoadRequested(
          search: query.isEmpty ? null : query,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/ministries/new'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Ministério'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header
          Padding(
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
                      Text('Ministérios', style: AppTypography.headingLarge),
                      const SizedBox(height: AppSpacing.xs),
                      BlocBuilder<MinistryBloc, MinistryState>(
                        builder: (context, state) {
                          final count = state is MinistryListLoaded ? state.ministries.length : 0;
                          return Text(
                            '$count ministérios cadastrados',
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
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar ministério...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textMuted),
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

          // List
          Expanded(
            child: BlocBuilder<MinistryBloc, MinistryState>(
              builder: (context, state) {
                if (state is MinistryLoading) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                if (state is MinistryError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(state.message,
                            style: AppTypography.bodyMedium),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: () => context
                              .read<MinistryBloc>()
                              .add(const MinistriesLoadRequested()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is MinistryListLoaded) {
                  if (state.ministries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups_outlined,
                              size: 64,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            state.activeSearch != null
                                ? 'Nenhum ministério encontrado'
                                : 'Nenhum ministério cadastrado',
                            style: AppTypography.bodyLarge
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Clique em "Novo Ministério" para cadastrar',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    itemCount: state.ministries.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == state.ministries.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: () => context.read<MinistryBloc>().add(
                                MinistriesLoadRequested(
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
                      final ministry = state.ministries[index];
                      return _MinistryTile(
                        ministry: ministry,
                        onTap: () =>
                            context.go('/ministries/${ministry.id}'),
                      );
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

class _MinistryTile extends StatelessWidget {
  final Ministry ministry;
  final VoidCallback onTap;

  const _MinistryTile({required this.ministry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ministry.isActive
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.textMuted.withValues(alpha: 0.12),
                child: Icon(
                  Icons.groups_rounded,
                  color: ministry.isActive
                      ? AppColors.accent
                      : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ministry.name,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!ministry.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                            ),
                            child: Text(
                              'Inativo',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (ministry.description != null &&
                        ministry.description!.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 2),
                        child: Text(
                          ministry.description!,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Row(
                      children: [
                        if (ministry.leaderName != null) ...[
                          Icon(Icons.person_outlined,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            ministry.leaderName!,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Icon(Icons.people_outline,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${ministry.memberCount}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
