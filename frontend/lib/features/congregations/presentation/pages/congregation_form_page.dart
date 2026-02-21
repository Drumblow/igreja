import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../members/data/member_repository.dart';
import '../../../members/data/models/member_models.dart';
import '../../bloc/congregation_bloc.dart';
import '../../bloc/congregation_event_state.dart';
import '../../data/congregation_repository.dart';
import '../../data/models/congregation_models.dart';

/// Screen for creating or editing a congregation.
/// Pass [existingCongregation] to enter edit mode; omit for creation.
/// If [congregationId] is provided and [existingCongregation] is null, fetches by ID.
class CongregationFormPage extends StatelessWidget {
  final Congregation? existingCongregation;
  final String? congregationId;

  const CongregationFormPage({
    super.key,
    this.existingCongregation,
    this.congregationId,
  });

  bool get isEditing => existingCongregation != null || congregationId != null;

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final repo = CongregationRepository(apiClient: apiClient);

    if (existingCongregation != null || congregationId == null) {
      return BlocProvider(
        create: (_) => CongregationBloc(repository: repo),
        child: _CongregationFormView(
            existingCongregation: existingCongregation),
      );
    }

    return FutureBuilder<Congregation>(
      future: repo.getCongregation(congregationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Editar Congregação')),
            body: Center(
              child: Text('Erro ao carregar congregação: ${snapshot.error}'),
            ),
          );
        }
        return BlocProvider(
          create: (_) => CongregationBloc(repository: repo),
          child:
              _CongregationFormView(existingCongregation: snapshot.data),
        );
      },
    );
  }
}

class _CongregationFormView extends StatefulWidget {
  final Congregation? existingCongregation;

  const _CongregationFormView({this.existingCongregation});

  @override
  State<_CongregationFormView> createState() => _CongregationFormViewState();
}

class _CongregationFormViewState extends State<_CongregationFormView> {
  final _formKey = GlobalKey<FormState>();
  late final bool _isEditing = widget.existingCongregation != null;

  late final _nameCtrl =
      TextEditingController(text: widget.existingCongregation?.name);
  late final _shortNameCtrl =
      TextEditingController(text: widget.existingCongregation?.shortName);
  late final _phoneCtrl =
      TextEditingController(text: widget.existingCongregation?.phone);
  late final _emailCtrl =
      TextEditingController(text: widget.existingCongregation?.email);
  late final _zipCodeCtrl =
      TextEditingController(text: widget.existingCongregation?.zipCode);
  late final _streetCtrl =
      TextEditingController(text: widget.existingCongregation?.street);
  late final _numberCtrl =
      TextEditingController(text: widget.existingCongregation?.number);
  late final _complementCtrl =
      TextEditingController(text: widget.existingCongregation?.complement);
  late final _neighborhoodCtrl =
      TextEditingController(text: widget.existingCongregation?.neighborhood);
  late final _cityCtrl =
      TextEditingController(text: widget.existingCongregation?.city);
  late final _stateCtrl =
      TextEditingController(text: widget.existingCongregation?.state);

  late String _congregationType =
      widget.existingCongregation?.type ?? 'congregacao';
  late bool _isActive = widget.existingCongregation?.isActive ?? true;

  String? _selectedLeaderId;
  String? _selectedLeaderName;

  @override
  void initState() {
    super.initState();
    _selectedLeaderId = widget.existingCongregation?.leaderId;
    _selectedLeaderName = widget.existingCongregation?.leaderName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _zipCodeCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'congregation_type': _congregationType,
    };

    void addIfNotEmpty(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) data[key] = value.trim();
    }

    addIfNotEmpty('short_name', _shortNameCtrl.text);
    addIfNotEmpty('phone', _phoneCtrl.text);
    addIfNotEmpty('email', _emailCtrl.text);
    addIfNotEmpty('zip_code', _zipCodeCtrl.text);
    addIfNotEmpty('street', _streetCtrl.text);
    addIfNotEmpty('number', _numberCtrl.text);
    addIfNotEmpty('complement', _complementCtrl.text);
    addIfNotEmpty('neighborhood', _neighborhoodCtrl.text);
    addIfNotEmpty('city', _cityCtrl.text);
    addIfNotEmpty('state', _stateCtrl.text);

    if (_selectedLeaderId != null) {
      data['leader_id'] = _selectedLeaderId;
    }

    if (_isEditing) {
      data['is_active'] = _isActive;
      context.read<CongregationBloc>().add(CongregationUpdateRequested(
            congregationId: widget.existingCongregation!.id,
            data: data,
          ));
    } else {
      context.read<CongregationBloc>().add(
            CongregationCreateRequested(data: data),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
            _isEditing ? 'Editar Congregação' : 'Nova Congregação'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: BlocBuilder<CongregationBloc, CongregationState>(
              builder: (context, state) {
                final isLoading = state is CongregationLoading;
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
      body: BlocListener<CongregationBloc, CongregationState>(
        listener: (context, state) {
          if (state is CongregationSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            final loc = GoRouterState.of(context).matchedLocation;
            final congBase = loc.contains('/settings/congregations') ? '/settings/congregations' : '/congregations';
            context.go('$congBase/${state.congregation.id}');
          } else if (state is CongregationError) {
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
                  'Dados da Congregação', Icons.church_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildBasicSection(isWide),
              const SizedBox(height: AppSpacing.xxl),

              _sectionTitle('Contato', Icons.contact_phone_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildContactSection(isWide),
              const SizedBox(height: AppSpacing.xxl),

              _sectionTitle('Endereço', Icons.location_on_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildAddressSection(isWide),

              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.xxl),
                _sectionTitle('Status', Icons.toggle_on_outlined),
                const SizedBox(height: AppSpacing.md),
                _card(
                  child: SwitchListTile(
                    title: Text(
                      'Congregação Ativa',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'A congregação está ativa e visível'
                          : 'A congregação está inativa',
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
                  child: BlocBuilder<CongregationBloc, CongregationState>(
                    builder: (context, state) {
                      final isLoading = state is CongregationLoading;
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
                            : 'Cadastrar Congregação'),
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

  Widget _buildBasicSection(bool isWide) {
    return _card(
      child: Column(
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _textField(
                    controller: _nameCtrl,
                    label: 'Nome da Congregação *',
                    hint: 'Ex: Congregação Filadélfia',
                    validator: (v) {
                      if (v == null || v.trim().length < 2) {
                        return 'Nome deve ter pelo menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _textField(
                    controller: _shortNameCtrl,
                    label: 'Nome Curto',
                    hint: 'Ex: Filadélfia',
                  ),
                ),
              ],
            )
          else ...[
            _textField(
              controller: _nameCtrl,
              label: 'Nome da Congregação *',
              hint: 'Ex: Congregação Filadélfia',
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Nome deve ter pelo menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _textField(
              controller: _shortNameCtrl,
              label: 'Nome Curto',
              hint: 'Ex: Filadélfia',
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _buildTypeDropdown(),
          const SizedBox(height: AppSpacing.lg),
          _buildLeaderField(),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIPO *',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: _congregationType,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'sede',
              child: Text('Sede'),
            ),
            DropdownMenuItem(
              value: 'congregacao',
              child: Text('Congregação'),
            ),
            DropdownMenuItem(
              value: 'ponto_de_pregacao',
              child: Text('Ponto de Pregação'),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _congregationType = v);
          },
        ),
      ],
    );
  }

  Widget _buildContactSection(bool isWide) {
    if (isWide) {
      return _card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _textField(
                controller: _phoneCtrl,
                label: 'Telefone',
                hint: '(99) 99999-9999',
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _textField(
                controller: _emailCtrl,
                label: 'E-mail',
                hint: 'contato@congregacao.com',
              ),
            ),
          ],
        ),
      );
    }
    return _card(
      child: Column(
        children: [
          _textField(
            controller: _phoneCtrl,
            label: 'Telefone',
            hint: '(99) 99999-9999',
          ),
          const SizedBox(height: AppSpacing.lg),
          _textField(
            controller: _emailCtrl,
            label: 'E-mail',
            hint: 'contato@congregacao.com',
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(bool isWide) {
    return _card(
      child: Column(
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 150,
                  child: _textField(
                    controller: _zipCodeCtrl,
                    label: 'CEP',
                    hint: '00000-000',
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _textField(
                    controller: _streetCtrl,
                    label: 'Rua',
                    hint: 'Nome da rua',
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 100,
                  child: _textField(
                    controller: _numberCtrl,
                    label: 'Número',
                    hint: '123',
                  ),
                ),
              ],
            )
          else ...[
            _textField(
              controller: _zipCodeCtrl,
              label: 'CEP',
              hint: '00000-000',
            ),
            const SizedBox(height: AppSpacing.lg),
            _textField(
              controller: _streetCtrl,
              label: 'Rua',
              hint: 'Nome da rua',
            ),
            const SizedBox(height: AppSpacing.lg),
            _textField(
              controller: _numberCtrl,
              label: 'Número',
              hint: '123',
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _textField(
            controller: _complementCtrl,
            label: 'Complemento',
            hint: 'Apto, bloco, etc.',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _textField(
                    controller: _neighborhoodCtrl,
                    label: 'Bairro',
                    hint: 'Nome do bairro',
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _textField(
                    controller: _cityCtrl,
                    label: 'Cidade',
                    hint: 'Nome da cidade',
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 80,
                  child: _textField(
                    controller: _stateCtrl,
                    label: 'UF',
                    hint: 'SP',
                  ),
                ),
              ],
            )
          else ...[
            _textField(
              controller: _neighborhoodCtrl,
              label: 'Bairro',
              hint: 'Nome do bairro',
            ),
            const SizedBox(height: AppSpacing.lg),
            _textField(
              controller: _cityCtrl,
              label: 'Cidade',
              hint: 'Nome da cidade',
            ),
            const SizedBox(height: AppSpacing.lg),
            _textField(
              controller: _stateCtrl,
              label: 'UF',
              hint: 'SP',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DIRIGENTE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          onTap: _showLeaderSearchDialog,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Selecionar dirigente...',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              suffixIcon: _selectedLeaderId != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _selectedLeaderId = null;
                        _selectedLeaderName = null;
                      }),
                    )
                  : const Icon(Icons.search, size: 18),
            ),
            child: Text(
              _selectedLeaderName ?? 'Selecionar dirigente...',
              style: _selectedLeaderName != null
                  ? AppTypography.bodyMedium
                  : AppTypography.bodyMedium
                      .copyWith(color: AppColors.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLeaderSearchDialog() async {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final memberRepo = MemberRepository(apiClient: apiClient);

    final result = await showDialog<Member>(
      context: context,
      builder: (ctx) => _LeaderSearchDialog(memberRepo: memberRepo),
    );

    if (result != null) {
      setState(() {
        _selectedLeaderId = result.id;
        _selectedLeaderName = result.fullName;
      });
    }
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

/// Dialog to search for a member to set as leader/dirigente
class _LeaderSearchDialog extends StatefulWidget {
  final MemberRepository memberRepo;

  const _LeaderSearchDialog({required this.memberRepo});

  @override
  State<_LeaderSearchDialog> createState() => _LeaderSearchDialogState();
}

class _LeaderSearchDialogState extends State<_LeaderSearchDialog> {
  final _searchCtrl = TextEditingController();
  List<Member> _results = [];
  bool _searching = false;

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final result = await widget.memberRepo.getMembers(
        page: 1,
        search: query.trim(),
      );
      setState(() {
        _results = result.members;
        _searching = false;
      });
    } catch (_) {
      setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecionar Dirigente'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar membro por nome...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: _search,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_results.isEmpty &&
                _searchCtrl.text.trim().length >= 2)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Nenhum membro encontrado',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final member = _results[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          member.fullName[0].toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(member.fullName,
                          style: AppTypography.bodyMedium),
                      onTap: () => Navigator.of(context).pop(member),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
