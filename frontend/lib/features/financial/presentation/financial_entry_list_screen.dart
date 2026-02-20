import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/financial_bloc.dart';
import '../bloc/financial_event_state.dart';
import '../data/financial_repository.dart';
import '../data/models/financial_models.dart';
import 'format_utils.dart';

class FinancialEntryListScreen extends StatelessWidget {
  const FinancialEntryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => FinancialBloc(
        repository: FinancialRepository(apiClient: apiClient),
      )..add(const FinancialEntriesLoadRequested()),
      child: const _EntryListView(),
    );
  }
}

class _EntryListView extends StatefulWidget {
  const _EntryListView();

  @override
  State<_EntryListView> createState() => _EntryListViewState();
}

class _EntryListViewState extends State<_EntryListView> {
  final _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedStatus;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    context.read<FinancialBloc>().add(FinancialEntriesLoadRequested(
          search: _searchController.text.isEmpty ? null : _searchController.text,
          type: _selectedType,
          status: _selectedStatus,
          dateFrom: _dateFrom != null ? dateFormat.format(_dateFrom!) : null,
          dateTo: _dateTo != null ? dateFormat.format(_dateTo!) : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          const Divider(height: 1),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/financial/entries/new'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Novo Lançamento'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/financial'),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lançamentos', style: AppTypography.headingLarge),
                const SizedBox(height: AppSpacing.xs),
                BlocBuilder<FinancialBloc, FinancialState>(
                  builder: (context, state) {
                    final count = state is FinancialEntriesLoaded ? state.totalCount : 0;
                    return Text(
                      '$count lançamentos',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Column(
        children: [
          if (isWide)
            Row(
              children: [
                Expanded(flex: 3, child: _buildSearchField()),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 1, child: _buildTypeFilter()),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 1, child: _buildStatusFilter()),
              ],
            )
          else
            Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _buildTypeFilter()),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _buildStatusFilter()),
                  ],
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _DateFilterChip(
                  label: _dateFrom != null
                      ? 'De: ${dateFmt.format(_dateFrom!)}'
                      : 'Data inicial',
                  hasValue: _dateFrom != null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateFrom ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _dateFrom = picked);
                      _search();
                    }
                  },
                  onClear: () {
                    setState(() => _dateFrom = null);
                    _search();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DateFilterChip(
                  label: _dateTo != null
                      ? 'Até: ${dateFmt.format(_dateTo!)}'
                      : 'Data final',
                  hasValue: _dateTo != null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateTo ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _dateTo = picked);
                      _search();
                    }
                  },
                  onClear: () {
                    setState(() => _dateTo = null);
                    _search();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar por descrição...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _search();
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      ),
      onSubmitted: (_) => _search(),
    );
  }

  Widget _buildTypeFilter() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedType,
      decoration: InputDecoration(
        hintText: 'Tipo',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Todos')),
        DropdownMenuItem(value: 'receita', child: Text('Receitas')),
        DropdownMenuItem(value: 'despesa', child: Text('Despesas')),
      ],
      onChanged: (value) {
        setState(() => _selectedType = value);
        _search();
      },
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      decoration: InputDecoration(
        hintText: 'Status',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Todos')),
        DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
        DropdownMenuItem(value: 'confirmado', child: Text('Confirmado')),
      ],
      onChanged: (value) {
        setState(() => _selectedStatus = value);
        _search();
      },
    );
  }

  Widget _buildList() {
    return BlocConsumer<FinancialBloc, FinancialState>(
      listener: (context, state) {
        if (state is FinancialSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), behavior: SnackBarBehavior.floating),
          );
        }
      },
      builder: (context, state) {
        if (state is FinancialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FinancialError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 56, color: AppColors.error.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpacing.md),
                  Text('Erro ao carregar lançamentos', style: AppTypography.headingSmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: () => context.read<FinancialBloc>().add(const FinancialEntriesLoadRequested()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is FinancialEntriesLoaded) {
          if (state.entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSpacing.md),
                  Text('Nenhum lançamento encontrado', style: AppTypography.headingSmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Comece registrando receitas e despesas', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.entries.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == state.entries.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () => context.read<FinancialBloc>().add(
                        FinancialEntriesLoadRequested(
                          page: state.currentPage + 1,
                          search: state.activeSearch,
                          type: state.activeType,
                          status: state.activeStatus,
                          dateFrom: state.activeDateFrom,
                          dateTo: state.activeDateTo,
                        ),
                      ),
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Carregar mais'),
                    ),
                  ),
                );
              }
              final entry = state.entries[index];
              return Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Excluir lançamento'),
                      content: Text('Remover "${entry.description}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  context.read<FinancialBloc>().add(
                    FinancialEntryDeleteRequested(entryId: entry.id),
                  );
                },
                child: _EntryTile(entry: entry),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  final FinancialEntry entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.isIncome;
    final typeColor = isIncome ? AppColors.success : AppColors.error;
    final typeIcon = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.go('/financial/entries/${entry.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              // Description & details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          entry.accountPlanName ?? '—',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        if (entry.memberName != null) ...[
                          Text(' · ', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                          Text(
                            entry.memberName!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _formatDateBR(entry.entryDate),
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                        if (entry.paymentMethod != null) ...[
                          Text(' · ', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                          Text(
                            entry.paymentMethodLabel,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Amount & status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} ${formatCurrency(entry.amount)}',
                    style: AppTypography.labelLarge.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(status: entry.status, isClosed: entry.isClosed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isClosed;

  const _StatusBadge({required this.status, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    if (isClosed) {
      bgColor = AppColors.textMuted.withValues(alpha: 0.1);
      textColor = AppColors.textMuted;
      label = 'Fechado';
    } else if (status == 'confirmado') {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      label = 'Confirmado';
    } else {
      bgColor = AppColors.accent.withValues(alpha: 0.1);
      textColor = AppColors.accent;
      label = 'Pendente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: AppTypography.bodySmall.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 10)),
    );
  }
}

String _formatDateBR(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  } catch (_) {
    return isoDate;
  }
}

class _DateFilterChip extends StatelessWidget {
  final String label;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateFilterChip({
    required this.label,
    required this.hasValue,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          suffixIcon: hasValue
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
