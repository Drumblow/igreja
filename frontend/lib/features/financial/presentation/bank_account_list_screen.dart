import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../bloc/financial_bloc.dart';
import '../bloc/financial_event_state.dart';
import '../data/financial_repository.dart';
import '../data/models/financial_models.dart';
import 'format_utils.dart';

class BankAccountListScreen extends StatelessWidget {
  const BankAccountListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final congCubit = context.read<CongregationContextCubit>();
    return BlocProvider(
      create: (_) => FinancialBloc(
        repository: FinancialRepository(apiClient: apiClient),
        congregationCubit: congCubit,
      )..add(const BankAccountsLoadRequested()),
      child: const _BankAccountListView(),
    );
  }
}

class _BankAccountListView extends StatelessWidget {
  const _BankAccountListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/financial')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contas Bancárias', style: AppTypography.headingLarge),
                      const SizedBox(height: AppSpacing.xs),
                      BlocBuilder<FinancialBloc, FinancialState>(
                        builder: (context, state) {
                          final count = state is BankAccountsLoaded ? state.totalCount : 0;
                          return Text('$count contas', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: BlocBuilder<FinancialBloc, FinancialState>(
              builder: (context, state) {
                if (state is FinancialLoading) return const Center(child: CircularProgressIndicator());
                if (state is FinancialError) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.error_outline, size: 56, color: AppColors.error.withValues(alpha: 0.5)),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => context.read<FinancialBloc>().add(const BankAccountsLoadRequested()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ]),
                  );
                }
                if (state is BankAccountsLoaded) {
                  if (state.accounts.isEmpty) {
                    return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.account_balance_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: AppSpacing.md),
                        Text('Nenhuma conta cadastrada', style: AppTypography.headingSmall.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Cadastre contas bancárias e caixas', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                      ]),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: state.accounts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _BankAccountTile(account: state.accounts[index]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nova Conta'),
      ),
    );
  }

  void _showCreateDialog(BuildContext outerContext) {
    final nameController = TextEditingController();
    final bankNameController = TextEditingController();
    final agencyController = TextEditingController();
    final accountNumberController = TextEditingController();
    final initialBalanceController = TextEditingController(text: '0');
    String type = 'conta_corrente';

    showDialog(
      context: outerContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Conta Bancária'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipo *'),
                    items: const [
                      DropdownMenuItem(value: 'caixa', child: Text('Caixa')),
                      DropdownMenuItem(value: 'conta_corrente', child: Text('Conta Corrente')),
                      DropdownMenuItem(value: 'poupanca', child: Text('Poupança')),
                      DropdownMenuItem(value: 'digital', child: Text('Conta Digital')),
                    ],
                    onChanged: (v) => setDialogState(() => type = v ?? type),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome da Conta *', hintText: 'Ex: Caixa Principal')),
                  const SizedBox(height: AppSpacing.md),
                  TextField(controller: bankNameController, decoration: const InputDecoration(labelText: 'Banco', hintText: 'Ex: Banco do Brasil')),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    Expanded(child: TextField(controller: agencyController, decoration: const InputDecoration(labelText: 'Agência'))),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: TextField(controller: accountNumberController, decoration: const InputDecoration(labelText: 'Número da Conta'))),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: initialBalanceController,
                    decoration: const InputDecoration(labelText: 'Saldo Inicial (R\$)', prefixText: 'R\$ '),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                outerContext.read<FinancialBloc>().add(BankAccountCreateRequested(data: {
                  'name': nameController.text.trim(),
                  'type': type,
                  if (bankNameController.text.isNotEmpty) 'bank_name': bankNameController.text.trim(),
                  if (agencyController.text.isNotEmpty) 'agency': agencyController.text.trim(),
                  if (accountNumberController.text.isNotEmpty) 'account_number': accountNumberController.text.trim(),
                  'initial_balance': double.tryParse(initialBalanceController.text.replaceAll(',', '.')) ?? 0,
                }));
                Navigator.pop(dialogContext);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (!outerContext.mounted) return;
                  outerContext.read<FinancialBloc>().add(const BankAccountsLoadRequested());
                });
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankAccountTile extends StatelessWidget {
  final BankAccount account;

  const _BankAccountTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final balanceColor = account.currentBalance >= 0 ? AppColors.success : AppColors.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                account.type == 'caixa' ? Icons.point_of_sale_rounded : Icons.account_balance_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    [account.typeLabel, if (account.bankName != null) account.bankName!].join(' · '),
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  if (account.agency != null || account.accountNumber != null)
                    Text(
                      [if (account.agency != null) 'Ag: ${account.agency}', if (account.accountNumber != null) 'CC: ${account.accountNumber}'].join(' · '),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(account.currentBalance),
                  style: AppTypography.headingSmall.copyWith(color: balanceColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text('Saldo atual', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
