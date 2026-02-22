import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/congregation_dropdown_field.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../bloc/member_bloc.dart';
import '../bloc/member_event_state.dart';
import '../data/member_repository.dart';
import '../data/models/church_role_model.dart';
import '../data/models/member_models.dart';

/// Screen for creating or editing a member.
/// Pass [existingMember] to enter edit mode; omit for creation.
/// If [memberId] is provided and [existingMember] is null, fetches the member by ID.
class MemberFormScreen extends StatelessWidget {
  final Member? existingMember;
  final String? memberId;

  const MemberFormScreen({super.key, this.existingMember, this.memberId});

  bool get isEditing => existingMember != null || memberId != null;

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final repo = MemberRepository(apiClient: apiClient);

    // If we already have the entity, show form immediately
    if (existingMember != null || memberId == null) {
      return BlocProvider(
        create: (_) => MemberBloc(
          repository: repo,
          congregationCubit: context.read<CongregationContextCubit>(),
        ),
        child: _MemberFormView(existingMember: existingMember),
      );
    }

    // Fetch by ID (deep link / browser refresh scenario)
    return FutureBuilder<Member>(
      future: repo.getMember(memberId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Editar Membro')),
            body: Center(
              child: Text('Erro ao carregar membro: ${snapshot.error}'),
            ),
          );
        }
        return BlocProvider(
          create: (_) => MemberBloc(
            repository: repo,
            congregationCubit: context.read<CongregationContextCubit>(),
          ),
          child: _MemberFormView(existingMember: snapshot.data),
        );
      },
    );
  }
}

class _MemberFormView extends StatefulWidget {
  final Member? existingMember;

  const _MemberFormView({this.existingMember});

  @override
  State<_MemberFormView> createState() => _MemberFormViewState();
}

class _MemberFormViewState extends State<_MemberFormView> {
  final _formKey = GlobalKey<FormState>();
  late final bool _isEditing = widget.existingMember != null;

  // Personal
  late final _fullNameCtrl = TextEditingController(text: widget.existingMember?.fullName);
  late final _socialNameCtrl = TextEditingController(text: widget.existingMember?.socialName);
  late final _cpfCtrl = TextEditingController(text: widget.existingMember?.cpf);
  late final _emailCtrl = TextEditingController(text: widget.existingMember?.email);
  late final _phonePrimaryCtrl = TextEditingController(text: widget.existingMember?.phonePrimary);
  late final _phoneSecondaryCtrl = TextEditingController(text: widget.existingMember?.phoneSecondary);

  // Address
  late final _zipCodeCtrl = TextEditingController(text: widget.existingMember?.zipCode);
  late final _streetCtrl = TextEditingController(text: widget.existingMember?.street);
  late final _numberCtrl = TextEditingController(text: widget.existingMember?.number);
  late final _complementCtrl = TextEditingController(text: widget.existingMember?.complement);
  late final _neighborhoodCtrl = TextEditingController(text: widget.existingMember?.neighborhood);
  late final _cityCtrl = TextEditingController(text: widget.existingMember?.city);

  // Additional
  late final _professionCtrl = TextEditingController(text: widget.existingMember?.profession);
  late final _workplaceCtrl = TextEditingController(text: widget.existingMember?.workplace);
  late final _birthplaceCityCtrl = TextEditingController(text: widget.existingMember?.birthplaceCity);
  late final _originChurchCtrl = TextEditingController(text: widget.existingMember?.originChurch);
  late final _notesCtrl = TextEditingController(text: widget.existingMember?.notes);

  // Dropdowns
  late String? _gender = widget.existingMember?.gender;
  late String? _maritalStatus = widget.existingMember?.maritalStatus;
  late String? _state = widget.existingMember?.state;
  late String? _birthplaceState = widget.existingMember?.birthplaceState;
  late String? _nationality = widget.existingMember?.nationality ?? 'brasileira';
  late String? _educationLevel = widget.existingMember?.educationLevel;
  late String? _bloodType = widget.existingMember?.bloodType;
  late String? _entryType = widget.existingMember?.entryType;
  late String? _rolePosition = widget.existingMember?.rolePosition;
  late String? _status = widget.existingMember?.status ?? 'ativo';

  // Dates
  late DateTime? _birthDate = widget.existingMember?.birthDate;
  late DateTime? _conversionDate = widget.existingMember?.conversionDate;
  late DateTime? _waterBaptismDate = widget.existingMember?.waterBaptismDate;
  late DateTime? _spiritBaptismDate = widget.existingMember?.spiritBaptismDate;
  late DateTime? _entryDate = widget.existingMember?.entryDate;
  late DateTime? _ordinationDate = widget.existingMember?.ordinationDate;
  late DateTime? _marriageDate = widget.existingMember?.marriageDate;

  // Dynamic church roles
  List<ChurchRole> _churchRoles = [];
  bool _rolesLoading = true;

  // Congregation
  String? _selectedCongregationId;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _selectedCongregationId = widget.existingMember?.congregationId
        ?? context.read<CongregationContextCubit>().state.activeCongregationId;
    _loadChurchRoles();
  }

  Future<void> _loadChurchRoles() async {
    try {
      final repo = MemberRepository(
        apiClient: RepositoryProvider.of<ApiClient>(context),
      );
      final roles = await repo.getChurchRoles();
      if (mounted) {
        setState(() {
          _churchRoles = roles;
          _rolesLoading = false;
        });
      }
    } catch (_) {
      // Fallback: use empty list, dropdown will show nothing
      if (mounted) setState(() => _rolesLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _socialNameCtrl.dispose();
    _cpfCtrl.dispose();
    _emailCtrl.dispose();
    _phonePrimaryCtrl.dispose();
    _phoneSecondaryCtrl.dispose();
    _zipCodeCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _professionCtrl.dispose();
    _workplaceCtrl.dispose();
    _birthplaceCityCtrl.dispose();
    _originChurchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final data = <String, dynamic>{
      'full_name': _fullNameCtrl.text.trim(),
      'gender': _gender ?? 'masculino',
      'status': _status ?? 'ativo',
    };

    void addIfNotEmpty(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) data[key] = value.trim();
    }

    void addDate(String key, DateTime? value) {
      if (value != null) {
        data[key] = '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      }
    }

    addIfNotEmpty('social_name', _socialNameCtrl.text);
    addDate('birth_date', _birthDate);
    addIfNotEmpty('marital_status', _maritalStatus);
    addIfNotEmpty('cpf', _cpfCtrl.text);
    addIfNotEmpty('email', _emailCtrl.text);
    addIfNotEmpty('phone_primary', _phonePrimaryCtrl.text);
    addIfNotEmpty('phone_secondary', _phoneSecondaryCtrl.text);
    addIfNotEmpty('zip_code', _zipCodeCtrl.text);
    addIfNotEmpty('street', _streetCtrl.text);
    addIfNotEmpty('number', _numberCtrl.text);
    addIfNotEmpty('complement', _complementCtrl.text);
    addIfNotEmpty('neighborhood', _neighborhoodCtrl.text);
    addIfNotEmpty('city', _cityCtrl.text);
    addIfNotEmpty('state', _state);
    addIfNotEmpty('profession', _professionCtrl.text);
    addIfNotEmpty('workplace', _workplaceCtrl.text);
    addIfNotEmpty('birthplace_city', _birthplaceCityCtrl.text);
    addIfNotEmpty('birthplace_state', _birthplaceState);
    addIfNotEmpty('nationality', _nationality);
    addIfNotEmpty('education_level', _educationLevel);
    addIfNotEmpty('blood_type', _bloodType);
    addDate('conversion_date', _conversionDate);
    addDate('water_baptism_date', _waterBaptismDate);
    addDate('spirit_baptism_date', _spiritBaptismDate);
    addIfNotEmpty('origin_church', _originChurchCtrl.text);
    addDate('entry_date', _entryDate);
    addIfNotEmpty('entry_type', _entryType);
    addIfNotEmpty('role_position', _rolePosition);
    addDate('ordination_date', _ordinationDate);
    addDate('marriage_date', _marriageDate);
    addIfNotEmpty('notes', _notesCtrl.text);
    data['congregation_id'] = _selectedCongregationId;

    if (_isEditing) {
      context.read<MemberBloc>().add(MemberUpdateRequested(
            memberId: widget.existingMember!.id,
            data: data,
          ));
    } else {
      context.read<MemberBloc>().add(MemberCreateRequested(data: data));
    }
  }

  Future<DateTime?> _pickDate(DateTime? initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.surface,
              ),
        ),
        child: child!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Membro' : 'Novo Membro'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: BlocBuilder<MemberBloc, MemberState>(
              builder: (context, state) {
                final isLoading = state is MemberLoading;
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
      body: BlocListener<MemberBloc, MemberState>(
        listener: (context, state) {
          if (state is MemberSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('/members/${state.member.id}');
          } else if (state is MemberError) {
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
              _sectionTitle('Dados Pessoais', Icons.person_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildPersonalSection(isWide),
              const SizedBox(height: AppSpacing.xxl),

              _sectionTitle('Endereço', Icons.location_on_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildAddressSection(isWide),
              const SizedBox(height: AppSpacing.xxl),

              _sectionTitle('Informações Adicionais', Icons.info_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildAdditionalSection(isWide),
              const SizedBox(height: AppSpacing.xxl),

              _sectionTitle('Informações Eclesiásticas', Icons.church_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildEcclesiasticalSection(isWide),
              const SizedBox(height: AppSpacing.xxl),

              _sectionTitle('Observações', Icons.note_outlined),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Observações gerais sobre o membro...',
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              _sectionTitle('Congregação', Icons.church_outlined),
              const SizedBox(height: AppSpacing.md),
              CongregationDropdownField(
                value: _selectedCongregationId,
                onChanged: (v) => setState(() => _selectedCongregationId = v),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Submit button (mobile)
              if (!isWide)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: BlocBuilder<MemberBloc, MemberState>(
                    builder: (context, state) {
                      final isLoading = state is MemberLoading;
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
                        label: Text(_isEditing ? 'Salvar Alterações' : 'Cadastrar Membro'),
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

  Widget _buildPersonalSection(bool isWide) {
    return _card(
      child: Column(
        children: [
          _fieldRow(isWide, [
            _textField(
              controller: _fullNameCtrl,
              label: 'Nome Completo *',
              hint: 'Nome completo do membro',
              validator: (v) {
                if (v == null || v.trim().length < 3) {
                  return 'Nome deve ter pelo menos 3 caracteres';
                }
                return null;
              },
            ),
            _textField(
              controller: _socialNameCtrl,
              label: 'Nome Social',
              hint: 'Nome social (opcional)',
            ),
          ]),
          _fieldRow(isWide, [
            _dateField(
              label: 'Data de Nascimento',
              value: _birthDate,
              onChanged: (d) => setState(() => _birthDate = d),
            ),
            _dropdown<String>(
              label: 'Sexo *',
              value: _gender,
              items: const {
                'masculino': 'Masculino',
                'feminino': 'Feminino',
              },
              onChanged: (v) => setState(() => _gender = v),
            ),
          ]),
          _fieldRow(isWide, [
            _dropdown<String>(
              label: 'Estado Civil',
              value: _maritalStatus,
              items: const {
                'solteiro': 'Solteiro(a)',
                'casado': 'Casado(a)',
                'divorciado': 'Divorciado(a)',
                'viuvo': 'Viúvo(a)',
                'uniao_estavel': 'União Estável',
              },
              onChanged: (v) => setState(() {
                _maritalStatus = v;
                if (v != 'casado') _marriageDate = null;
              }),
            ),
            _textField(controller: _cpfCtrl, label: 'CPF', hint: '000.000.000-00'),
          ]),
          if (_maritalStatus == 'casado')
            _fieldRow(isWide, [
              _dateField(
                label: 'Data de Casamento',
                value: _marriageDate,
                onChanged: (d) => setState(() => _marriageDate = d),
              ),
              const Expanded(child: SizedBox.shrink()),
            ]),
          _fieldRow(isWide, [
            _textField(
              controller: _emailCtrl,
              label: 'E-mail',
              hint: 'email@exemplo.com',
              keyboardType: TextInputType.emailAddress,
            ),
          ]),
          _fieldRow(isWide, [
            _textField(
              controller: _phonePrimaryCtrl,
              label: 'Telefone Principal',
              hint: '(00) 00000-0000',
              keyboardType: TextInputType.phone,
            ),
            _textField(
              controller: _phoneSecondaryCtrl,
              label: 'Telefone Secundário',
              hint: '(00) 00000-0000',
              keyboardType: TextInputType.phone,
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
            _textField(controller: _zipCodeCtrl, label: 'CEP', hint: '00000-000'),
            _textField(controller: _streetCtrl, label: 'Logradouro', hint: 'Rua, Av., etc.'),
          ]),
          _fieldRow(isWide, [
            _textField(controller: _numberCtrl, label: 'Número', hint: '000'),
            _textField(controller: _complementCtrl, label: 'Complemento', hint: 'Apto, Bloco, etc.'),
          ]),
          _fieldRow(isWide, [
            _textField(controller: _neighborhoodCtrl, label: 'Bairro', hint: 'Bairro'),
            _textField(controller: _cityCtrl, label: 'Cidade', hint: 'Cidade'),
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

  Widget _buildAdditionalSection(bool isWide) {
    return _card(
      child: Column(
        children: [
          _fieldRow(isWide, [
            _textField(controller: _professionCtrl, label: 'Profissão', hint: 'Profissão'),
            _textField(controller: _workplaceCtrl, label: 'Local de Trabalho', hint: 'Empresa / Local'),
          ]),
          _fieldRow(isWide, [
            _textField(controller: _birthplaceCityCtrl, label: 'Naturalidade (Cidade)', hint: 'Cidade'),
            _dropdown<String>(
              label: 'Naturalidade (UF)',
              value: _birthplaceState,
              items: _ufMap,
              onChanged: (v) => setState(() => _birthplaceState = v),
            ),
          ]),
          _fieldRow(isWide, [
            _textField(
              controller: TextEditingController(text: _nationality),
              label: 'Nacionalidade',
              hint: 'ex: brasileira',
              onChanged: (v) => _nationality = v,
            ),
            _dropdown<String>(
              label: 'Escolaridade',
              value: _educationLevel,
              items: const {
                'fundamental_incompleto': 'Fundamental Incompleto',
                'fundamental_completo': 'Fundamental Completo',
                'medio_incompleto': 'Médio Incompleto',
                'medio_completo': 'Médio Completo',
                'superior_incompleto': 'Superior Incompleto',
                'superior_completo': 'Superior Completo',
                'pos_graduacao': 'Pós-Graduação',
                'mestrado': 'Mestrado',
                'doutorado': 'Doutorado',
              },
              onChanged: (v) => setState(() => _educationLevel = v),
            ),
          ]),
          _fieldRow(isWide, [
            _dropdown<String>(
              label: 'Tipo Sanguíneo',
              value: _bloodType,
              items: const {
                'A+': 'A+',
                'A-': 'A-',
                'B+': 'B+',
                'B-': 'B-',
                'AB+': 'AB+',
                'AB-': 'AB-',
                'O+': 'O+',
                'O-': 'O-',
              },
              onChanged: (v) => setState(() => _bloodType = v),
            ),
            const Expanded(child: SizedBox.shrink()),
          ]),
        ],
      ),
    );
  }

  Widget _buildEcclesiasticalSection(bool isWide) {
    return _card(
      child: Column(
        children: [
          _fieldRow(isWide, [
            _dateField(
              label: 'Data de Conversão',
              value: _conversionDate,
              onChanged: (d) => setState(() => _conversionDate = d),
            ),
            _dateField(
              label: 'Batismo nas Águas',
              value: _waterBaptismDate,
              onChanged: (d) => setState(() => _waterBaptismDate = d),
            ),
          ]),
          _fieldRow(isWide, [
            _dateField(
              label: 'Batismo no Espírito Santo',
              value: _spiritBaptismDate,
              onChanged: (d) => setState(() => _spiritBaptismDate = d),
            ),
            _textField(
              controller: _originChurchCtrl,
              label: 'Igreja de Origem',
              hint: 'Nome da igreja anterior',
            ),
          ]),
          _fieldRow(isWide, [
            _dateField(
              label: 'Data de Ingresso',
              value: _entryDate,
              onChanged: (d) => setState(() => _entryDate = d),
            ),
            _dropdown<String>(
              label: 'Forma de Ingresso',
              value: _entryType,
              items: const {
                'batismo': 'Batismo',
                'transferencia': 'Transferência',
                'aclamacao': 'Aclamação',
                'reconciliacao': 'Reconciliação',
              },
              onChanged: (v) => setState(() => _entryType = v),
            ),
          ]),
          _fieldRow(isWide, [
            _buildRoleDropdownWithAdd(),
            _dateField(
              label: _getInvestitureLabel(),
              value: _ordinationDate,
              onChanged: (d) => setState(() => _ordinationDate = d),
            ),
          ]),
          _fieldRow(isWide, [
            _dropdown<String>(
              label: 'Status',
              value: _status,
              items: const {
                'ativo': 'Ativo',
                'inativo': 'Inativo',
                'transferido': 'Transferido',
                'desligado': 'Desligado',
                'falecido': 'Falecido',
                'visitante': 'Visitante',
              },
              onChanged: (v) => setState(() => _status = v),
            ),
            const Expanded(child: SizedBox.shrink()),
          ]),
        ],
      ),
    );
  }

  // ── Role dropdown with "+" button ──

  /// Returns the investiture date label based on the selected role.
  String _getInvestitureLabel() {
    if (_rolePosition == null || _churchRoles.isEmpty) {
      return 'Data de Investidura';
    }
    try {
      final role = _churchRoles.firstWhere((r) => r.key == _rolePosition);
      return role.investitureLabel;
    } catch (_) {
      return 'Data de Investidura';
    }
  }

  /// Builds the Cargo / Função dropdown with a "+" button to add new roles.
  Widget _buildRoleDropdownWithAdd() {
    // Build items from loaded church roles
    final Map<String, String> roleItems = _rolesLoading
        ? const {'membro': 'Membro'}
        : {for (final r in _churchRoles) r.key: r.displayName};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CARGO / FUNÇÃO',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              height: 20,
              width: 20,
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Adicionar cargo',
                onPressed: _showAddRoleDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          value: roleItems.containsKey(_rolePosition) ? _rolePosition : null,
          isExpanded: true,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            hintText: 'Selecione',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
          items: roleItems.entries
              .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => setState(() => _rolePosition = v),
        ),
      ],
    );
  }

  Future<void> _showAddRoleDialog() async {
    final nameCtrl = TextEditingController();
    String investitureType = 'nomeacao';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Novo Cargo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome do Cargo *',
                  hintText: 'Ex: Líder de Louvor',
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: investitureType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Investidura',
                ),
                items: const [
                  DropdownMenuItem(value: 'consagracao', child: Text('Consagração')),
                  DropdownMenuItem(value: 'ordenacao', child: Text('Ordenação')),
                  DropdownMenuItem(value: 'eleicao', child: Text('Eleição')),
                  DropdownMenuItem(value: 'nomeacao', child: Text('Nomeação')),
                ],
                onChanged: (v) => setDialogState(() => investitureType = v ?? 'nomeacao'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty && mounted) {
      try {
        final repo = MemberRepository(
          apiClient: RepositoryProvider.of<ApiClient>(context),
        );
        final newRole = await repo.createChurchRole(
          key: nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_'),
          displayName: nameCtrl.text.trim(),
          investitureType: investitureType,
        );
        if (mounted) {
          setState(() {
            _churchRoles.add(newRole);
            _rolePosition = newRole.key;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cargo "${newRole.displayName}" criado com sucesso'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao criar cargo: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    nameCtrl.dispose();
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
              .expand((w) => [Expanded(child: w), const SizedBox(width: AppSpacing.md)])
              .toList()
            ..removeLast(),
        ),
      );
    }
    // On mobile, filter out Expanded placeholders (used for spacing in wide mode)
    final filtered = children.where((w) => w is! Expanded).toList();
    return Column(
      children: filtered.map((w) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: w,
      )).toList(),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
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
          onChanged: onChanged,
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
          value: items.containsKey(value) ? value : null,
          isExpanded: true,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            hintText: 'Selecione',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
          items: items.entries
              .map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
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
        InkWell(
          onTap: () async {
            final picked = await _pickDate(value);
            if (picked != null) onChanged(picked);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => onChanged(null),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  const Icon(Icons.calendar_today_outlined, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
            ),
            child: Text(
              value != null ? _dateFormat.format(value) : 'Selecione',
              style: AppTypography.bodyMedium.copyWith(
                color: value != null ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
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
