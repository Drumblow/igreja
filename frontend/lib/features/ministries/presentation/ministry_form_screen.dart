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

/// Screen for creating or editing a ministry.
/// Pass [existingMinistry] to enter edit mode; omit for creation.
class MinistryFormScreen extends StatelessWidget {
  final Ministry? existingMinistry;

  const MinistryFormScreen({super.key, this.existingMinistry});

  bool get isEditing => existingMinistry != null;

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => MinistryBloc(
        repository: MinistryRepository(apiClient: apiClient),
      ),
      child: _MinistryFormView(existingMinistry: existingMinistry),
    );
  }
}

class _MinistryFormView extends StatefulWidget {
  final Ministry? existingMinistry;

  const _MinistryFormView({this.existingMinistry});

  @override
  State<_MinistryFormView> createState() => _MinistryFormViewState();
}

class _MinistryFormViewState extends State<_MinistryFormView> {
  final _formKey = GlobalKey<FormState>();
  late final bool _isEditing = widget.existingMinistry != null;

  late final _nameCtrl =
      TextEditingController(text: widget.existingMinistry?.name);
  late final _descriptionCtrl =
      TextEditingController(text: widget.existingMinistry?.description);
  late bool _isActive = widget.existingMinistry?.isActive ?? true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
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

    addIfNotEmpty('description', _descriptionCtrl.text);

    if (_isEditing) {
      data['is_active'] = _isActive;
      context.read<MinistryBloc>().add(MinistryUpdateRequested(
            ministryId: widget.existingMinistry!.id,
            data: data,
          ));
    } else {
      context.read<MinistryBloc>().add(MinistryCreateRequested(data: data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Ministério' : 'Novo Ministério'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: BlocBuilder<MinistryBloc, MinistryState>(
              builder: (context, state) {
                final isLoading = state is MinistryLoading;
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
      body: BlocListener<MinistryBloc, MinistryState>(
        listener: (context, state) {
          if (state is MinistrySaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('/ministries/${state.ministry.id}');
          } else if (state is MinistryError) {
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
                  'Dados do Ministério', Icons.groups_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildMinistrySection(isWide),
              const SizedBox(height: AppSpacing.xxl),

              _sectionTitle('Descrição', Icons.description_outlined),
              const SizedBox(height: AppSpacing.md),
              _card(
                child: TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Descrição do ministério...',
                  ),
                ),
              ),

              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.xxl),
                _sectionTitle('Status', Icons.toggle_on_outlined),
                const SizedBox(height: AppSpacing.md),
                _card(
                  child: SwitchListTile(
                    title: Text(
                      'Ministério Ativo',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'O ministério está ativo e visível'
                          : 'O ministério está inativo',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeThumbColor: AppColors.accent,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxxl),

              // Submit button (mobile)
              if (!isWide)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: BlocBuilder<MinistryBloc, MinistryState>(
                    builder: (context, state) {
                      final isLoading = state is MinistryLoading;
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
                            : 'Cadastrar Ministério'),
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

  Widget _buildMinistrySection(bool isWide) {
    return _card(
      child: Column(
        children: [
          _textField(
            controller: _nameCtrl,
            label: 'Nome do Ministério *',
            hint: 'Ex: Louvor e Adoração',
            validator: (v) {
              if (v == null || v.trim().length < 2) {
                return 'Nome deve ter pelo menos 2 caracteres';
              }
              return null;
            },
          ),
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
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
}
