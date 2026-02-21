import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../bloc/congregation_context_cubit.dart';

/// Global congregation selector widget for the AppBar.
/// Shows a dropdown with available congregations.
/// If no congregations exist, this widget is hidden.
class CongregationSelector extends StatelessWidget {
  const CongregationSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CongregationContextCubit, CongregationContextState>(
      builder: (context, state) {
        if (!state.hasLoaded || !state.hasCongregations) {
          return const SizedBox.shrink();
        }

        return InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => _showSelector(context, state),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.isAllSelected
                      ? Icons.public_rounded
                      : Icons.church_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    state.activeLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSelector(BuildContext context, CongregationContextState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Selecionar Congregação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // "All" option (for admin/pastor)
              _SelectorItem(
                icon: Icons.public_rounded,
                label: 'Todas (Geral)',
                isSelected: state.isAllSelected,
                onTap: () {
                  context
                      .read<CongregationContextCubit>()
                      .selectCongregation(null);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              // Individual congregations
              ...state.availableCongregations.map((congregation) {
                final isSelected =
                    state.activeCongregation?.id == congregation.id;
                return _SelectorItem(
                  icon: congregation.type == 'sede'
                      ? Icons.account_balance_rounded
                      : Icons.church_rounded,
                  label: congregation.shortName ?? congregation.name,
                  subtitle: congregation.typeLabel,
                  isSelected: isSelected,
                  onTap: () {
                    context
                        .read<CongregationContextCubit>()
                        .selectCongregation(congregation);
                    Navigator.pop(ctx);
                  },
                );
              }),
              SizedBox(
                  height: MediaQuery.of(ctx).padding.bottom + AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

class _SelectorItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectorItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
