import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../bloc/congregation_bloc.dart';
import '../../bloc/congregation_event_state.dart';
import '../../data/congregation_repository.dart';
import '../../data/models/congregation_models.dart';

class CongregationListPage extends StatelessWidget {
  const CongregationListPage({super.key});

  /// Returns the base path for congregation routes based on current location.
  static String basePath(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/settings/congregations')) {
      return '/settings/congregations';
    }
    return '/congregations';
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => CongregationBloc(
        repository: CongregationRepository(apiClient: apiClient),
      )..add(const CongregationsLoadRequested()),
      child: const _CongregationListView(),
    );
  }
}

class _CongregationListView extends StatefulWidget {
  const _CongregationListView();

  @override
  State<_CongregationListView> createState() => _CongregationListViewState();
}

class _CongregationListViewState extends State<_CongregationListView> {
  String? _filterType;

  void _onFilterChanged(String? type) {
    setState(() => _filterType = type);
    context.read<CongregationBloc>().add(CongregationsLoadRequested(
          type: type,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Congregações'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('${CongregationListPage.basePath(context)}/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nova Congregação'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todas',
                    isSelected: _filterType == null,
                    onSelected: () => _onFilterChanged(null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Sede',
                    isSelected: _filterType == 'sede',
                    onSelected: () => _onFilterChanged('sede'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Congregações',
                    isSelected: _filterType == 'congregacao',
                    onSelected: () => _onFilterChanged('congregacao'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: 'Pontos de Pregação',
                    isSelected: _filterType == 'ponto_de_pregacao',
                    onSelected: () => _onFilterChanged('ponto_de_pregacao'),
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: BlocBuilder<CongregationBloc, CongregationState>(
              builder: (context, state) {
                if (state is CongregationLoading) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                if (state is CongregationError) {
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
                              .read<CongregationBloc>()
                              .add(const CongregationsLoadRequested()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is CongregationListLoaded) {
                  if (state.congregations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.church_outlined,
                              size: 64,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _filterType != null
                                ? 'Nenhuma congregação encontrada'
                                : 'Nenhuma congregação cadastrada',
                            style: AppTypography.bodyLarge
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Clique em "Nova Congregação" para cadastrar',
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
                    itemCount: state.congregations.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final congregation = state.congregations[index];
                      return _CongregationTile(
                        congregation: congregation,
                        onTap: () => context.go(
                            '${CongregationListPage.basePath(context)}/${congregation.id}'),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.accent.withValues(alpha: 0.15),
      checkmarkColor: AppColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.accent : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.4)
            : AppColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
    );
  }
}

class _CongregationTile extends StatelessWidget {
  final Congregation congregation;
  final VoidCallback onTap;

  const _CongregationTile({
    required this.congregation,
    required this.onTap,
  });

  IconData get _typeIcon {
    switch (congregation.type) {
      case 'sede':
        return Icons.account_balance_rounded;
      case 'ponto_de_pregacao':
        return Icons.pin_drop_rounded;
      default:
        return Icons.church_rounded;
    }
  }

  Color get _typeColor {
    switch (congregation.type) {
      case 'sede':
        return AppColors.accent;
      case 'ponto_de_pregacao':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

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
                backgroundColor: congregation.isActive
                    ? _typeColor.withValues(alpha: 0.12)
                    : AppColors.textMuted.withValues(alpha: 0.12),
                child: Icon(
                  _typeIcon,
                  color: congregation.isActive
                      ? _typeColor
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
                            congregation.name,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!congregation.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              'Inativa',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _typeColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              congregation.typeLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: _typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (congregation.leaderName != null) ...[
                          Icon(Icons.person_outlined,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              congregation.leaderName!,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        Icon(Icons.people_outline,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${congregation.activeMembers}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    if (congregation.addressShort.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              congregation.addressShort,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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
