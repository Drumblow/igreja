import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/searchable_entity_dropdown.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../../members/data/member_repository.dart';
import '../bloc/asset_bloc.dart';
import '../bloc/asset_event_state.dart';
import '../data/asset_repository.dart';
import '../data/models/asset_models.dart';

class AssetLoanListScreen extends StatelessWidget {
  const AssetLoanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final congCubit = context.read<CongregationContextCubit>();
    return BlocProvider(
      create: (_) => AssetBloc(
        repository: AssetRepository(apiClient: apiClient),
        congregationCubit: congCubit,
      )..add(const AssetLoansLoadRequested()),
      child: const _LoanListView(),
    );
  }
}

class _LoanListView extends StatefulWidget {
  const _LoanListView();

  @override
  State<_LoanListView> createState() => _LoanListViewState();
}

class _LoanListViewState extends State<_LoanListView> {
  String? _statusFilter;

  void _onStatusFilter(String? status) {
    setState(() => _statusFilter = status);
    context.read<AssetBloc>().add(AssetLoansLoadRequested(status: status));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Empréstimos de Bens')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Empréstimo'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text('Filtrar:', style: AppTypography.bodyMedium),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String?>(
                  value: _statusFilter,
                  hint: const Text('Status'),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'active', child: Text('Em Andamento')),
                    DropdownMenuItem(value: 'returned', child: Text('Devolvidos')),
                    DropdownMenuItem(value: 'overdue', child: Text('Atrasados')),
                  ],
                  onChanged: _onStatusFilter,
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<AssetBloc, AssetState>(
              listener: (context, state) {
                if (state is AssetSaved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  context
                      .read<AssetBloc>()
                      .add(const AssetLoansLoadRequested());
                }
                if (state is AssetError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is AssetLoading) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                if (state is AssetLoansLoaded) {
                  if (state.loans.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded,
                              size: 64,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: AppSpacing.md),
                          Text('Nenhum empréstimo registrado',
                              style: AppTypography.bodyLarge
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100,
                    ),
                    itemCount: state.loans.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) =>
                        _LoanTile(loan: state.loans[i]),
                  );
                }
                if (state is AssetError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(state.message, style: AppTypography.bodyMedium),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: () => context
                              .read<AssetBloc>()
                              .add(const AssetLoansLoadRequested()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final assetRepo = AssetRepository(apiClient: apiClient);
    final memberRepo = MemberRepository(apiClient: apiClient);

    EntityOption? selectedAsset;
    EntityOption? selectedMember;
    String conditionOut = 'bom';
    DateTime expectedReturn = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Novo Empréstimo'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableEntityDropdown(
                    label: 'Bem *',
                    hint: 'Busque pelo código ou descrição...',
                    onSelected: (entity) => selectedAsset = entity,
                    searchCallback: (query) async {
                      final result = await assetRepo.getAssets(
                        search: query,
                        perPage: 20,
                        status: 'ativo',
                      );
                      return result.items
                          .map((a) => EntityOption(
                                id: a.id,
                                label: '${a.assetCode} - ${a.description}',
                              ))
                          .toList();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SearchableEntityDropdown(
                    label: 'Membro *',
                    hint: 'Busque pelo nome...',
                    onSelected: (entity) => selectedMember = entity,
                    searchCallback: (query) async {
                      final result = await memberRepo.getMembers(
                        search: query,
                        perPage: 20,
                        status: 'ativo',
                      );
                      return result.members
                          .map((m) => EntityOption(id: m.id, label: m.fullName))
                          .toList();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: conditionOut,
                    decoration:
                        const InputDecoration(labelText: 'Condição de Saída'),
                    items: const [
                      DropdownMenuItem(value: 'novo', child: Text('Novo')),
                      DropdownMenuItem(value: 'bom', child: Text('Bom')),
                      DropdownMenuItem(
                          value: 'regular', child: Text('Regular')),
                      DropdownMenuItem(value: 'ruim', child: Text('Ruim')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => conditionOut = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: expectedReturn,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) {
                        setDialogState(() => expectedReturn = d);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Devolução Prevista',
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        '${expectedReturn.day.toString().padLeft(2, '0')}/${expectedReturn.month.toString().padLeft(2, '0')}/${expectedReturn.year}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedAsset == null || selectedMember == null) return;
                final now = DateTime.now();
                context.read<AssetBloc>().add(AssetLoanCreateRequested(
                      data: {
                        'asset_id': selectedAsset!.id,
                        'borrower_member_id': selectedMember!.id,
                        'loan_date':
                            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                        'expected_return_date':
                            '${expectedReturn.year}-${expectedReturn.month.toString().padLeft(2, '0')}-${expectedReturn.day.toString().padLeft(2, '0')}',
                        'condition_out': conditionOut,
                      },
                    ));
                Navigator.pop(ctx);
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanTile extends StatelessWidget {
  final AssetLoan loan;
  const _LoanTile({required this.loan});

  Color _statusColor() {
    if (loan.isReturned) return AppColors.success;
    if (loan.isOverdue) return AppColors.error;
    return AppColors.info;
  }

  IconData _statusIcon() {
    if (loan.isReturned) return Icons.check_circle_outline;
    if (loan.isOverdue) return Icons.warning_amber_rounded;
    return Icons.swap_horiz_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(), color: _statusColor(), size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    loan.assetDescription ?? loan.assetCode ?? 'Bem',
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loan.statusLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: _statusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (loan.borrowerName != null)
              Text(
                'Emprestado para: ${loan.borrowerName}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            Text(
              'Empréstimo: ${loan.loanDate} — Devolução prevista: ${loan.expectedReturnDate}',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            if (loan.actualReturnDate != null)
              Text(
                'Devolvido em: ${loan.actualReturnDate}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.success),
              ),
            if (!loan.isReturned) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _showReturnDialog(context),
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Registrar Devolução'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReturnDialog(BuildContext context) {
    String conditionIn = 'bom';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Registrar Devolução'),
          content: DropdownButtonFormField<String>(
            value: conditionIn,
            decoration:
                const InputDecoration(labelText: 'Condição de Devolução'),
            items: const [
              DropdownMenuItem(value: 'novo', child: Text('Novo')),
              DropdownMenuItem(value: 'bom', child: Text('Bom')),
              DropdownMenuItem(value: 'regular', child: Text('Regular')),
              DropdownMenuItem(value: 'ruim', child: Text('Ruim')),
            ],
            onChanged: (v) {
              if (v != null) setDialogState(() => conditionIn = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final now = DateTime.now();
                context.read<AssetBloc>().add(AssetLoanReturnRequested(
                      loanId: loan.id,
                      data: {
                        'actual_return_date':
                            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                        'condition_in': conditionIn,
                      },
                    ));
                Navigator.pop(ctx);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
