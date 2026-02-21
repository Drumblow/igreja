import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/congregation_repository.dart';
import '../../data/models/congregation_models.dart';

/// Reports page: Overview + Compare congregations
class CongregationReportPage extends StatefulWidget {
  const CongregationReportPage({super.key});

  @override
  State<CongregationReportPage> createState() => _CongregationReportPageState();
}

class _CongregationReportPageState extends State<CongregationReportPage>
    with SingleTickerProviderStateMixin {
  late final CongregationRepository _repo;
  late final TabController _tabController;

  CongregationsOverview? _overview;
  CongregationCompareReport? _compareReport;
  String _selectedMetric = 'members';
  bool _isLoadingOverview = true;
  bool _isLoadingCompare = false;
  String? _error;

  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _repo = CongregationRepository(apiClient: apiClient);
    _tabController = TabController(length: 2, vsync: this);
    _loadOverview();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isLoadingOverview = true;
      _error = null;
    });
    try {
      _overview = await _repo.getOverviewReport();
      setState(() => _isLoadingOverview = false);
    } catch (e) {
      setState(() {
        _isLoadingOverview = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadCompare() async {
    setState(() {
      _isLoadingCompare = true;
      _error = null;
    });
    try {
      _compareReport = await _repo.getCompareReport(metric: _selectedMetric);
      setState(() => _isLoadingCompare = false);
    } catch (e) {
      setState(() {
        _isLoadingCompare = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Relatórios — Congregações'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Visão Geral'),
            Tab(text: 'Comparativo'),
          ],
          onTap: (index) {
            if (index == 1 && _compareReport == null && !_isLoadingCompare) {
              _loadCompare();
            }
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCompareTab(),
        ],
      ),
    );
  }

  // ── Overview Tab ──

  Widget _buildOverviewTab() {
    if (_isLoadingOverview) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _loadOverview,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final o = _overview!;
    return RefreshIndicator(
      onRefresh: _loadOverview,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Summary cards
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _summaryCard(
                'Congregações',
                o.totalCongregations.toString(),
                Icons.church_outlined,
                AppColors.accent,
              ),
              _summaryCard(
                'Membros Ativos',
                o.totalMembersAll.toString(),
                Icons.people_outlined,
                AppColors.success,
              ),
              _summaryCard(
                'Receita do Mês',
                _currencyFormat.format(o.totalIncomeMonth),
                Icons.trending_up_outlined,
                AppColors.success,
              ),
              _summaryCard(
                'Despesa do Mês',
                _currencyFormat.format(o.totalExpenseMonth),
                Icons.trending_down_outlined,
                AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Por Congregação', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          ...o.congregations.map(_overviewItemCard),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 170,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: AppTypography.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewItemCard(CongregationOverviewItem item) {
    final balance = item.incomeMonth - item.expenseMonth;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.type == 'sede' ? Icons.home_outlined : Icons.church_outlined,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${item.activeMembers} membros',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _miniStat(
                    'Receitas',
                    _currencyFormat.format(item.incomeMonth),
                    AppColors.success,
                  ),
                ),
                Expanded(
                  child: _miniStat(
                    'Despesas',
                    _currencyFormat.format(item.expenseMonth),
                    AppColors.error,
                  ),
                ),
                Expanded(
                  child: _miniStat(
                    'Saldo',
                    _currencyFormat.format(balance),
                    balance >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Compare Tab ──

  Widget _buildCompareTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'members',
                      label: Text('Membros'),
                      icon: Icon(Icons.people_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: 'financial',
                      label: Text('Finanças'),
                      icon: Icon(Icons.attach_money, size: 16),
                    ),
                    ButtonSegment(
                      value: 'ebd',
                      label: Text('EBD'),
                      icon: Icon(Icons.school_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: 'assets',
                      label: Text('Patrimônio'),
                      icon: Icon(Icons.inventory_2_outlined, size: 16),
                    ),
                  ],
                  selected: {_selectedMetric},
                  onSelectionChanged: (set) {
                    setState(() => _selectedMetric = set.first);
                    _loadCompare();
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingCompare
              ? const Center(child: CircularProgressIndicator())
              : _compareReport == null
                  ? Center(
                      child: Text(
                        'Selecione uma métrica para comparar',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                      ),
                    )
                  : _buildCompareContent(),
        ),
      ],
    );
  }

  Widget _buildCompareContent() {
    final items = _compareReport!.congregations;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma congregação encontrada',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return _compareItemCard(item, index + 1);
      },
    );
  }

  Widget _compareItemCard(CongregationCompareItem item, int rank) {
    final isFinancial = _selectedMetric == 'financial';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: rank <= 3
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.border,
                  child: Text(
                    '#$rank',
                    style: AppTypography.labelSmall.copyWith(
                      color: rank <= 3 ? AppColors.accent : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (item.label1 != null)
                  Expanded(
                    child: _compareValue(
                      item.label1!,
                      isFinancial
                          ? _currencyFormat.format(item.value1)
                          : item.value1.toStringAsFixed(0),
                    ),
                  ),
                if (item.label2 != null)
                  Expanded(
                    child: _compareValue(
                      item.label2!,
                      isFinancial
                          ? _currencyFormat.format(item.value2)
                          : item.value2.toStringAsFixed(0),
                    ),
                  ),
                if (item.label3 != null)
                  Expanded(
                    child: _compareValue(
                      item.label3!,
                      isFinancial
                          ? _currencyFormat.format(item.value3)
                          : _selectedMetric == 'ebd' && item.label3!.contains('%')
                              ? '${item.value3.toStringAsFixed(1)}%'
                              : item.value3.toStringAsFixed(0),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _compareValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
