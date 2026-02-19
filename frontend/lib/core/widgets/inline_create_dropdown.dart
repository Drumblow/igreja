import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A dropdown with an optional "+" button beside it for creating new items inline.
///
/// Wraps a [DropdownButtonFormField] with a trailing icon button.
/// When the "+" is tapped, [onCreatePressed] is called — typically opening
/// a dialog that creates and returns the new item id so the dropdown can be refreshed.
///
/// Usage:
/// ```dart
/// InlineCreateDropdown<String>(
///   labelText: 'Categoria *',
///   value: _selectedCategoryId,
///   items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
///   onChanged: (v) => setState(() => _selectedCategoryId = v),
///   onCreatePressed: () => _showCreateCategoryDialog(),
///   validator: (v) => v == null ? 'Selecione uma categoria' : null,
/// )
/// ```
class InlineCreateDropdown<T> extends StatelessWidget {
  /// Label text for the dropdown.
  final String labelText;

  /// Currently selected value.
  final T? value;

  /// Dropdown items.
  final List<DropdownMenuItem<T>> items;

  /// Called when selection changes.
  final ValueChanged<T?>? onChanged;

  /// Called when the "+" button is pressed. Should open
  /// a create dialog/inline form and refresh the items list.
  final VoidCallback? onCreatePressed;

  /// Optional validator.
  final String? Function(T?)? validator;

  /// Tooltip for the "+" button.
  final String createTooltip;

  /// Hint widget shown when nothing is selected.
  final Widget? hint;

  const InlineCreateDropdown({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    this.onChanged,
    this.onCreatePressed,
    this.validator,
    this.createTooltip = 'Criar novo',
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<T>(
            initialValue: value,
            decoration: InputDecoration(labelText: labelText),
            items: items,
            onChanged: onChanged,
            validator: validator,
            hint: hint,
            isExpanded: true,
          ),
        ),
        if (onCreatePressed != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: IconButton(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: createTooltip,
              color: AppColors.accent,
              iconSize: 28,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
