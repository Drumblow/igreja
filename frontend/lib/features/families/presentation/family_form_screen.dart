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

/// Screen for creating or editing a family.
/// Pass [existingFamily] to enter edit mode; omit for creation.
class FamilyFormScreen extends StatelessWidget {
  final Family? existingFamily;

  const FamilyFormScreen({super.key, this.existingFamily});

  bool get isEditing => existingFamily != null;

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => FamilyBloc(
        repository: FamilyRepository(apiClient: apiClient),
      ),
      child: _FamilyFormView(existingFamily: existingFamily),
    );
  }
}

class _FamilyFormView extends StatefulWidget {
  final Family? existingFamily;

  const _FamilyFormView({this.existingFamily});

  @override
  State<_FamilyFormView> createState() => _FamilyFormViewState();
}

class _FamilyFormViewState extends State<_FamilyFormView> {
  final _formKey = GlobalKey<FormState>();
  late final bool _isEditing = widget.existingFamily != null;

  // Name
  late final _nameCtrl =
      TextEditingController(text: widget.existingFamily?.name);

  // Address
  late final _zipCodeCtrl =
      TextEditingController(text: widget.existingFamily?.zipCode);
  late final _streetCtrl =
      TextEditingController(text: widget.existingFamily?.street);
  late final _numberCtrl =
      TextEditingController(text: widget.existingFamily?.number);
  late final _complementCtrl =
      TextEditingController(text: widget.existingFamily?.complement);
  late final _neighborhoodCtrl =
      TextEditingController(text: widget.existingFamily?.neighborhood);
  late final _cityCtrl =
      TextEditingController(text: widget.existingFamily?.city);
  late final _notesCtrl =
      TextEditingController(text: widget.existingFamily?.notes);

  // State dropdown
  late String? _state = widget.existingFamily?.state;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _zipCodeCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
    };

    void addIfNotEmpty(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) data[key] = value.trim();
    }

    addIfNotEmpty('zip_code', _zipCodeCtrl.text);
    addIfNotEmpty('street', _streetCtrl.text);
    addIfNotEmpty('number', _numberCtrl.text);
    addIfNotEmpty('complement', _complementCtrl.text);
    addIfNotEmpty('neighborhood', _neighborhoodCtrl.text);
    addIfNotEmpty('city', _cityCtrl.text);
    addIfNotEmpty('state', _state);
    addIfNotEmpty('notes', _notesCtrl.text);

    if (_isEditing) {
      context.read<FamilyBloc>().add(FamilyUpdateRequested(
            familyId: widget.existingFamily!.id,
            data: data,
          ));
    } else {
      context.read<FamilyBloc>().add(FamilyCreateRequested(data: data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Família' : 'Nova Família'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: BlocBuilder<FamilyBloc, FamilyState>(
              builder: (context, state) {
                final isLoading = state is FamilyLoading;
                return FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_isEditing ? 'Salvar' : 'Cadastrar'),
                );
              },
            ),
          ),
        ],
      ),
      body: BlocListener<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilySaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('/families/${state.family.id}');
          } else if (state is FamilyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? AppSpacing.huge : AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                  'Dados da Família', Icons.family_restroom_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildFamilySection(isWide),
              const SizedBox(height: AppSpacing.xxl),

              _sectionTitle('Endereço', Icons.location_on_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildAddressSection(isWide),
              const SizedBox(height: AppSpacing.xxl),

              _sectionTitle('Observações', Icons.note_outlined),
              const SizedBox(height: AppSpacing.md),
              _card(
                child: TextFormField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Observações gerais sobre a família...',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Submit button (mobile)
              if (!isWide)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: BlocBuilder<FamilyBloc, FamilyState>(
                    builder: (context, state) {
                      final isLoading = state is FamilyLoading;
                      return ElevatedButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isEditing
                            ? 'Salvar Alterações'
                            : 'Cadastrar Família'),
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sections ──

  Widget _buildFamilySection(bool isWide) {
    return _card(
      child: Column(
        children: [
          _fieldRow(isWide, [
            _textField(
              controller: _nameCtrl,
              label: 'Nome da Família *',
              hint: 'Ex: Família Silva',
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Nome deve ter pelo menos 2 caracteres';
                }
                return null;
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAddressSection(bool isWide) {
    return _card(
      child: Column(
        children: [
          _fieldRow(isWide, [
            _textField(
              controller: _zipCodeCtrl,
              label: 'CEP',
              hint: '00000-000',
            ),
            _textField(
              controller: _streetCtrl,
              label: 'Logradouro',
              hint: 'Rua, Av., etc.',
            ),
          ]),
          _fieldRow(isWide, [
            _textField(
              controller: _numberCtrl,
              label: 'Número',
              hint: '000',
            ),
            _textField(
              controller: _complementCtrl,
              label: 'Complemento',
              hint: 'Apto, Bloco, etc.',
            ),
          ]),
          _fieldRow(isWide, [
            _textField(
              controller: _neighborhoodCtrl,
              label: 'Bairro',
              hint: 'Bairro',
            ),
            _textField(
              controller: _cityCtrl,
              label: 'Cidade',
              hint: 'Cidade',
            ),
          ]),
          _fieldRow(isWide, [
            _dropdown<String>(
              label: 'UF',
              value: _state,
              items: _ufMap,
              onChanged: (v) => setState(() => _state = v),
            ),
            const Expanded(child: SizedBox.shrink()),
          ]),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.headingSmall),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }

  Widget _fieldRow(bool isWide, List<Widget> children) {
    if (isWide) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children
              .expand((w) => [
                    Expanded(child: w),
                    const SizedBox(width: AppSpacing.md),
                  ])
              .toList()
            ..removeLast(),
        ),
      );
    }
    return Column(
      children: children
          .map((w) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: w,
              ))
          .toList(),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<T>(
          initialValue: items.containsKey(value) ? value : null,
          isExpanded: true,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            hintText: 'Selecione',
            hintStyle: AppTypography.bodyMedium
                .copyWith(color: AppColors.textMuted),
          ),
          items: items.entries
              .map((e) =>
                  DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static const Map<String, String> _ufMap = {
    'AC': 'AC',
    'AL': 'AL',
    'AP': 'AP',
    'AM': 'AM',
    'BA': 'BA',
    'CE': 'CE',
    'DF': 'DF',
    'ES': 'ES',
    'GO': 'GO',
    'MA': 'MA',
    'MT': 'MT',
    'MS': 'MS',
    'MG': 'MG',
    'PA': 'PA',
    'PB': 'PB',
    'PR': 'PR',
    'PE': 'PE',
    'PI': 'PI',
    'RJ': 'RJ',
    'RN': 'RN',
    'RS': 'RS',
    'RO': 'RO',
    'RR': 'RR',
    'SC': 'SC',
    'SP': 'SP',
    'SE': 'SE',
    'TO': 'TO',
  };
}
