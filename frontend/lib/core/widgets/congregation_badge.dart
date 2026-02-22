import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/congregations/bloc/congregation_context_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Small chip that shows the congregation name.
///
/// Only renders when the user is viewing **all congregations**
/// (i.e. no specific congregation is selected in [CongregationContextCubit]).
/// When a single congregation is active the badge is hidden because
/// every item already belongs to that congregation.
class CongregationBadge extends StatelessWidget {
  /// The congregation name to display (comes from the entity model).
  final String? congregationName;

  const CongregationBadge({super.key, required this.congregationName});

  @override
  Widget build(BuildContext context) {
    if (congregationName == null || congregationName!.isEmpty) {
      return const SizedBox.shrink();
    }

    final congState = context.watch<CongregationContextCubit>().state;
    if (!congState.isAllSelected) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.church_outlined, size: 11, color: AppColors.accent),
          const SizedBox(width: 3),
          Text(
            congregationName!,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
