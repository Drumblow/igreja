import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/congregations/bloc/congregation_context_cubit.dart';
import '../theme/app_colors.dart';

/// Reusable dropdown form field for selecting a congregation.
///
/// Shows all available congregations from [CongregationContextCubit].
/// Hidden when there are no congregations registered.
///
/// **Behaviour:**
/// - Pre-selects the currently active congregation (or the entity's existing
///   `congregationId` when editing).
/// - `null` value represents "Sede / Geral" (headquarters / no congregation).
/// - Field is placed **after** the module's required fields.
class CongregationDropdownField extends StatelessWidget {
  /// Currently selected congregation id (nullable → Sede/Geral).
  final String? value;

  /// Called when the user picks a different congregation.
  final ValueChanged<String?> onChanged;

  const CongregationDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final congState = context.watch<CongregationContextCubit>().state;

    // Don't render if there are no congregations available.
    if (!congState.hasCongregations) return const SizedBox.shrink();

    return DropdownButtonFormField<String?>(
      decoration: const InputDecoration(
        labelText: 'Congregação',
        prefixIcon: Icon(Icons.church_outlined),
      ),
      initialValue: value,
      isExpanded: true,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Sede / Geral'),
        ),
        ...congState.availableCongregations.map(
          (c) => DropdownMenuItem<String?>(
            value: c.id,
            child: Text(
              c.displayName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
      dropdownColor: Theme.of(context).cardColor,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
    );
  }
}
