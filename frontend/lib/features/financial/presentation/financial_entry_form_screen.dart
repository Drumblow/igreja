import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/inline_create_dropdown.dart';
import '../bloc/financial_bloc.dart';
import '../bloc/financial_event_state.dart';
import '../data/financial_repository.dart';
import '../data/models/financial_models.dart';

class FinancialEntryFormScreen extends StatelessWidget {
  final String? initialType; // "receita" or "despesa"
  final String? entryId; // if editing an existing entry

  const FinancialEntryFormScreen({super.key, this.initialType, this.entryId});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final repo = FinancialRepository(apiClient: apiClient);
    return BlocProvider(
      create: (_) => FinancialBloc(repository: repo),
      child: _EntryFormView(initialType: initialType, entryId: entryId, repository: repo),
    );
  }
}

class _EntryFormView extends StatefulWidget {
  final String? initialType;
  final String? entryId;
  final FinancialRepository repository;

  const _EntryFormView({this.initialType, this.entryId, required this.repository});

  @override
  State<_EntryFormView> createState() => _EntryFormViewState();
}

class _EntryFormViewState extends State<_EntryFormView> {
  final _formKey = GlobalKey<FormState>();

  late String _type;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedAccountPlanId;
  String? _selectedBankAccountId;
  String? _selectedCampaignId;
  String? _selectedPaymentMethod;
  String _status = 'confirmado';
  DateTime _entryDate = DateTime.now();
  DateTime? _dueDate;
  DateTime? _paymentDate;

  List<AccountPlan> _accountPlans = [];
  List<BankAccount> _bankAccounts = [];
  List<Campaign> _campaigns = [];
  bool _loadingOptions = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'receita';
    _isEditing = widget.entryId != null;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final plans = await widget.repository.getAccountPlans(perPage: 100, type: _isEditing ? null : _type);
      final accounts = await widget.repository.getBankAccounts(perPage: 100);
      final campaigns = await widget.repository.getCampaigns(perPage: 100);

      if (mounted) {
        setState(() {
          _accountPlans = plans.items;
          _bankAccounts = accounts.items;
          _campaigns = campaigns.items.where((c) => c.status == 'ativa').toList();
        });
      }

      // Load existing entry data for editing
      if (_isEditing && widget.entryId != null) {
        final entry = await widget.repository.getEntry(widget.entryId!);
        if (mounted) {
          setState(() {
            _type = entry.type;
            _descriptionController.text = entry.description;
            _amountController.text = entry.amount.toStringAsFixed(2);
            _selectedAccountPlanId = entry.accountPlanId;
            _selectedBankAccountId = entry.bankAccountId;
            _selectedCampaignId = entry.campaignId;
            _selectedPaymentMethod = entry.paymentMethod;
            _status = entry.status;
            if (entry.entryDate.isNotEmpty) {
              _entryDate = DateTime.tryParse(entry.entryDate) ?? DateTime.now();
            }
            if (entry.dueDate != null) {
              _dueDate = DateTime.tryParse(entry.dueDate!);
            }
            if (entry.paymentDate != null) {
              _paymentDate = DateTime.tryParse(entry.paymentDate!);
            }
            if (entry.supplierName != null) {
              _supplierController.text = entry.supplierName!;
            }
            if (entry.notes != null) {
              _notesController.text = entry.notes!;
            }
          });
        }
      }

      if (mounted) setState(() => _loadingOptions = false);
    } catch (_) {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountPlanId == null || _selectedBankAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o plano de contas e a conta bancária'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final data = <String, dynamic>{
      'type': _type,
      'description': _descriptionController.text.trim(),
      'amount': double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0,
      'account_plan_id': _selectedAccountPlanId,
      'bank_account_id': _selectedBankAccountId,
      'entry_date': _formatDateISO(_entryDate),
      'status': _status,
      if (_selectedPaymentMethod != null) 'payment_method': _selectedPaymentMethod,
      if (_selectedCampaignId != null) 'campaign_id': _selectedCampaignId,
      if (_dueDate != null) 'due_date': _formatDateISO(_dueDate!),
      if (_paymentDate != null) 'payment_date': _formatDateISO(_paymentDate!),
      if (_supplierController.text.isNotEmpty) 'supplier_name': _supplierController.text.trim(),
      if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
    };

    context.read<FinancialBloc>().add(
      _isEditing
          ? FinancialEntryUpdateRequested(entryId: widget.entryId!, data: data)
          : FinancialEntryCreateRequested(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    final isIncome = _type == 'receita';

    return BlocListener<FinancialBloc, FinancialState>(
      listener: (context, state) {
        if (state is FinancialSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), behavior: SnackBarBehavior.floating),
          );
          context.go('/financial/entries');
        } else if (state is FinancialError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _loadingOptions
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => context.canPop() ? context.pop() : context.go('/financial/entries'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _isEditing
                                  ? 'Editar Lançamento'
                                  : (isIncome ? 'Nova Receita' : 'Nova Despesa'),
                              style: AppTypography.headingLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Form
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? AppSpacing.xxl : AppSpacing.lg),
                    sliver: SliverToBoxAdapter(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Type toggle
                            _buildTypeToggle(),
                            const SizedBox(height: AppSpacing.lg),

                            // Section: Informações Básicas
                            _buildSectionTitle('Informações Básicas'),
                            const SizedBox(height: AppSpacing.md),
                            if (isWide)
                              Row(children: [
                                Expanded(child: _buildDescriptionField()),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: _buildAmountField()),
                              ])
                            else ...[
                              _buildDescriptionField(),
                              const SizedBox(height: AppSpacing.md),
                              _buildAmountField(),
                            ],
                            const SizedBox(height: AppSpacing.md),

                            if (isWide)
                              Row(children: [
                                Expanded(child: _buildAccountPlanDropdown()),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: _buildBankAccountDropdown()),
                              ])
                            else ...[
                              _buildAccountPlanDropdown(),
                              const SizedBox(height: AppSpacing.md),
                              _buildBankAccountDropdown(),
                            ],
                            const SizedBox(height: AppSpacing.lg),

                            // Section: Datas e Pagamento
                            _buildSectionTitle('Datas e Pagamento'),
                            const SizedBox(height: AppSpacing.md),
                            if (isWide)
                              Row(children: [
                                Expanded(child: _buildDateField('Data do Lançamento *', _entryDate, (d) => setState(() => _entryDate = d))),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: _buildPaymentMethodDropdown()),
                              ])
                            else ...[
                              _buildDateField('Data do Lançamento *', _entryDate, (d) => setState(() => _entryDate = d)),
                              const SizedBox(height: AppSpacing.md),
                              _buildPaymentMethodDropdown(),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            if (isWide)
                              Row(children: [
                                Expanded(child: _buildOptionalDateField('Vencimento', _dueDate, (d) => setState(() => _dueDate = d))),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: _buildOptionalDateField('Data Pagamento', _paymentDate, (d) => setState(() => _paymentDate = d))),
                              ])
                            else ...[
                              _buildOptionalDateField('Vencimento', _dueDate, (d) => setState(() => _dueDate = d)),
                              const SizedBox(height: AppSpacing.md),
                              _buildOptionalDateField('Data Pagamento', _paymentDate, (d) => setState(() => _paymentDate = d)),
                            ],
                            const SizedBox(height: AppSpacing.lg),

                            // Section: Detalhes Adicionais
                            _buildSectionTitle('Detalhes Adicionais'),
                            const SizedBox(height: AppSpacing.md),
                            if (isWide)
                              Row(children: [
                                Expanded(child: _buildCampaignDropdown()),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(child: _buildStatusDropdown()),
                              ])
                            else ...[
                              _buildCampaignDropdown(),
                              const SizedBox(height: AppSpacing.md),
                              _buildStatusDropdown(),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            if (!isIncome) ...[
                              _buildSupplierField(),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            _buildNotesField(),
                            const SizedBox(height: AppSpacing.xl),

                            // Submit
                            BlocBuilder<FinancialBloc, FinancialState>(
                              builder: (context, state) {
                                final loading = state is FinancialLoading;
                                return SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: loading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                                    ),
                                    child: loading
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                        : Text(_isEditing ? 'Atualizar Lançamento' : 'Salvar Lançamento', style: AppTypography.buttonLarge),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ──────────── Form Field Builders ────────────

  Widget _buildTypeToggle() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'receita', label: Text('Receita'), icon: Icon(Icons.trending_up_rounded)),
        ButtonSegment(value: 'despesa', label: Text('Despesa'), icon: Icon(Icons.trending_down_rounded)),
      ],
      selected: {_type},
      onSelectionChanged: (selected) {
        setState(() => _type = selected.first);
        _selectedAccountPlanId = null;
        _loadOptions();
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _type == 'receita' ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15);
          }
          return null;
        }),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.headingSmall.copyWith(color: AppColors.textPrimary));
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Descrição *',
        hintText: 'Ex: Dízimo do mês, Conta de luz...',
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Descrição é obrigatória' : null,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Valor (R\$) *',
        hintText: '0,00',
        prefixText: 'R\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Valor é obrigatório';
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed == null || parsed <= 0) return 'Valor deve ser maior que zero';
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildAccountPlanDropdown() {
    return InlineCreateDropdown<String>(
      labelText: 'Plano de Contas *',
      value: _selectedAccountPlanId,
      items: _accountPlans.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.code} - ${p.name}'))).toList(),
      onChanged: (v) => setState(() => _selectedAccountPlanId = v),
      validator: (v) => v == null ? 'Selecione uma categoria' : null,
      createTooltip: 'Criar plano de contas',
      onCreatePressed: () => _showCreateAccountPlanDialog(),
    );
  }

  Widget _buildBankAccountDropdown() {
    return InlineCreateDropdown<String>(
      labelText: 'Conta Bancária *',
      value: _selectedBankAccountId,
      items: _bankAccounts.where((a) => a.isActive).map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
      onChanged: (v) => setState(() => _selectedBankAccountId = v),
      validator: (v) => v == null ? 'Selecione uma conta' : null,
      createTooltip: 'Criar conta bancária',
      onCreatePressed: () => _showCreateBankAccountDialog(),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPaymentMethod,
      decoration: const InputDecoration(labelText: 'Forma de Pagamento'),
      items: const [
        DropdownMenuItem(value: null, child: Text('— Selecione —')),
        DropdownMenuItem(value: 'dinheiro', child: Text('Dinheiro')),
        DropdownMenuItem(value: 'pix', child: Text('PIX')),
        DropdownMenuItem(value: 'transferencia', child: Text('Transferência')),
        DropdownMenuItem(value: 'cartao_debito', child: Text('Cartão Débito')),
        DropdownMenuItem(value: 'cartao_credito', child: Text('Cartão Crédito')),
        DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
        DropdownMenuItem(value: 'boleto', child: Text('Boleto')),
      ],
      onChanged: (v) => setState(() => _selectedPaymentMethod = v),
    );
  }

  Widget _buildCampaignDropdown() {
    return InlineCreateDropdown<String>(
      labelText: 'Campanha (opcional)',
      value: _selectedCampaignId,
      items: [
        const DropdownMenuItem(value: null, child: Text('— Nenhuma —')),
        ..._campaigns.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
      ],
      onChanged: (v) => setState(() => _selectedCampaignId = v),
      createTooltip: 'Criar campanha',
      onCreatePressed: () => _showCreateCampaignDialog(),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _status,
      decoration: const InputDecoration(labelText: 'Status'),
      items: const [
        DropdownMenuItem(value: 'confirmado', child: Text('Confirmado')),
        DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
      ],
      onChanged: (v) => setState(() => _status = v ?? 'confirmado'),
    );
  }

  Widget _buildSupplierField() {
    return TextFormField(
      controller: _supplierController,
      decoration: const InputDecoration(
        labelText: 'Fornecedor/Beneficiário',
        hintText: 'Nome do fornecedor ou beneficiário',
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Observações',
        hintText: 'Notas adicionais...',
      ),
      maxLines: 3,
      textInputAction: TextInputAction.done,
    );
  }

  // ──────────── Inline Create Dialogs ────────────

  void _showCreateAccountPlanDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Plano de Contas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Código *',
                hintText: 'Ex: 1.1.01',
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                hintText: 'Ex: Dízimos',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final created = await widget.repository.createAccountPlan({
                  'code': codeCtrl.text.trim(),
                  'name': nameCtrl.text.trim(),
                  'type': _type,
                });
                await _loadOptions();
                if (mounted) {
                  setState(() => _selectedAccountPlanId = created.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Plano "${created.name}" criado!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar plano: $e')),
                  );
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _showCreateBankAccountDialog() {
    final nameCtrl = TextEditingController();
    String accountType = 'conta_corrente';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nova Conta Bancária'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  hintText: 'Ex: Conta Principal',
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: accountType,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'caixa', child: Text('Caixa')),
                  DropdownMenuItem(value: 'conta_corrente', child: Text('Conta Corrente')),
                  DropdownMenuItem(value: 'poupanca', child: Text('Poupança')),
                  DropdownMenuItem(value: 'digital', child: Text('Digital')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => accountType = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final created = await widget.repository.createBankAccount({
                    'name': nameCtrl.text.trim(),
                    'type': accountType,
                    'initial_balance': 0,
                  });
                  await _loadOptions();
                  if (mounted) {
                    setState(() => _selectedBankAccountId = created.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Conta "${created.name}" criada!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao criar conta: $e')),
                    );
                  }
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCampaignDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Campanha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                hintText: 'Ex: Campanha Missionária 2025',
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Breve descrição (opcional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final now = DateTime.now();
                final created = await widget.repository.createCampaign({
                  'name': nameCtrl.text.trim(),
                  if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                  'start_date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                });
                await _loadOptions();
                if (mounted) {
                  setState(() => _selectedCampaignId = created.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Campanha "${created.name}" criada!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar campanha: $e')),
                  );
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime value, ValueChanged<DateTime> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today, size: 18)),
        child: Text(
          '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}',
          style: AppTypography.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildOptionalDateField(String label, DateTime? value, ValueChanged<DateTime> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today, size: 18)),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
              : '—',
          style: AppTypography.bodyMedium.copyWith(color: value == null ? AppColors.textMuted : null),
        ),
      ),
    );
  }

  String _formatDateISO(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
