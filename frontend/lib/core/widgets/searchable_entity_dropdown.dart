import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A generic entity with an id and a display label.
class EntityOption {
  final String id;
  final String label;

  const EntityOption({required this.id, required this.label});
}

/// Callback that searches entities by query string.
typedef EntitySearchCallback = Future<List<EntityOption>> Function(String query);

/// A searchable dropdown for selecting entities (members, assets, etc.)
/// instead of requiring the user to type a UUID manually.
///
/// Usage:
/// ```dart
/// SearchableEntityDropdown(
///   label: 'Membro *',
///   hint: 'Busque por nome...',
///   onSelected: (entity) => setState(() => _selectedMemberId = entity?.id),
///   searchCallback: (query) async {
///     final result = await memberRepo.getMembers(search: query, perPage: 20);
///     return result.members.map((m) => EntityOption(id: m.id, label: m.fullName)).toList();
///   },
/// )
/// ```
class SearchableEntityDropdown extends StatefulWidget {
  /// Label displayed above the field.
  final String label;

  /// Hint text shown when no value is selected.
  final String hint;

  /// Called when an entity is selected (or cleared).
  final ValueChanged<EntityOption?> onSelected;

  /// Async search callback. Receives a query string and returns matching entities.
  final EntitySearchCallback searchCallback;

  /// Optional initial value already selected.
  final EntityOption? initialValue;

  /// Optional validator for form integration.
  final String? Function(EntityOption?)? validator;

  const SearchableEntityDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.onSelected,
    required this.searchCallback,
    this.initialValue,
    this.validator,
  });

  @override
  State<SearchableEntityDropdown> createState() =>
      _SearchableEntityDropdownState();
}

class _SearchableEntityDropdownState extends State<SearchableEntityDropdown> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  EntityOption? _selected;
  List<EntityOption> _suggestions = [];
  bool _loading = false;
  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
    if (_selected != null) {
      _controller.text = _selected!.label;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(SearchableEntityDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _selected = widget.initialValue;
      _controller.text = _selected?.label ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _search(_controller.text);
    } else {
      // When losing focus, if text doesn't match, revert
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
          if (_selected == null) {
            _controller.clear();
          } else {
            _controller.text = _selected!.label;
          }
        }
      });
    }
  }

  void _onTextChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(text);
    });
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final results = await widget.searchCallback(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _loading = false;
        });
        _showSuggestions();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuggestions() {
    _removeOverlay();
    if (_suggestions.isEmpty && !_loading) {
      _overlayEntry = OverlayEntry(
        builder: (context) => _buildOverlayContent([]),
      );
    } else {
      _overlayEntry = OverlayEntry(
        builder: (context) => _buildOverlayContent(_suggestions),
      );
    }
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildOverlayContent(List<EntityOption> items) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 300;

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, renderBox?.size.height ?? 56),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: AppColors.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child:
                          SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          _controller.text.isEmpty ? 'Digite para buscar...' : 'Nenhum resultado encontrado',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          final isSelected = _selected?.id == item.id;
                          return InkWell(
                            onTap: () => _selectEntity(item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              color: isSelected ? AppColors.accent.withValues(alpha: 0.08) : null,
                              child: Text(
                                item.label,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  void _selectEntity(EntityOption entity) {
    setState(() {
      _selected = entity;
      _controller.text = entity.label;
      _errorText = null;
    });
    widget.onSelected(entity);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _clearSelection() {
    setState(() {
      _selected = null;
      _controller.clear();
    });
    widget.onSelected(null);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: FormField<EntityOption>(
        validator: (_) {
          if (widget.validator != null) {
            final error = widget.validator!(_selected);
            return error;
          }
          return null;
        },
        builder: (formFieldState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  errorText: formFieldState.errorText ?? _errorText,
                  suffixIcon: _selected != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _clearSelection,
                        )
                      : _loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : const Icon(Icons.search, size: 18),
                ),
              ),
              if (_selected != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Selecionado: ${_selected!.label}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
