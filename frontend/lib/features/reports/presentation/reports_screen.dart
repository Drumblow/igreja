import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../financial/data/financial_repository.dart';
import '../../financial/data/models/financial_models.dart';
import '../../financial/presentation/format_utils.dart';
import '../../members/data/member_repository.dart';
import '../../members/data/models/member_models.dart';

/// Asset stats for reports
class _AssetReportStats {
  final int totalAssets;
  final int totalActive;
  final int inMaintenance;
  final int onLoan;
  final double totalValue;

  const _AssetReportStats({
    this.totalAssets = 0,
    this.totalActive = 0,
    this.inMaintenance = 0,
    this.onLoan = 0,
    this.totalValue = 0,
  });

  factory _AssetReportStats.fromJson(Map<String, dynamic> json) {
    return _AssetReportStats(
      totalAssets: json['total_assets'] as int? ?? 0,
      totalActive: json['total_active'] as int? ?? 0,
      inMaintenance: json['in_maintenance'] as int? ?? 0,
      onLoan: json['on_loan'] as int? ?? 0,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// EBD stats for reports
class _EbdReportStats {
  final int totalClasses;
  final int totalEnrolled;
  final int activeTerms;
  final double avgAttendanceRate;

  const _EbdReportStats({
    this.totalClasses = 0,
    this.totalEnrolled = 0,
    this.activeTerms = 0,
    this.avgAttendanceRate = 0,
  });

  factory _EbdReportStats.fromJson(Map<String, dynamic> json) {
    return _EbdReportStats(
      totalClasses: json['total_classes'] as int? ?? 0,
      totalEnrolled: json['total_enrolled'] as int? ?? 0,
      activeTerms: json['active_terms'] as int? ?? 0,
      avgAttendanceRate: (json['avg_attendance_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Central reports screen — aggregates key metrics across all modules.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;

  // Members
  MemberStats? _memberStats;
  List<Member>? _birthdayMembers;

  // Financial
  FinancialBalance? _balance;

  // Assets
  _AssetReportStats? _assetStats;

  // EBD
  _EbdReportStats? _ebdStats;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _loading = true);

    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final memberRepo = MemberRepository(apiClient: apiClient);
      final financialRepo = FinancialRepository(apiClient: apiClient);

      final now = DateTime.now();

      final results = await Future.wait([
        memberRepo.getStats(),
        memberRepo.getMembers(
          perPage: 50,
          status: 'ativo',
        ),
        financialRepo.getBalanceReport().catchError(
            (_) => const FinancialBalance(
                  totalIncome: 0,
                  totalExpense: 0,
                  balance: 0,
                  incomeByCategory: [],
                  expenseByCategory: [],
                )),
        _loadAssetStats(apiClient),
        _loadEbdStats(apiClient),
      ]);

      if (mounted) {
        final memberResult =
            results[1] as ({List<Member> members, int total});

        // Filter birthday members for this month
        final birthdayMembers = memberResult.members
            .where((m) => m.birthDate != null && m.birthDate!.month == now.month)
            .toList()
          ..sort((a, b) => a.birthDate!.day.compareTo(b.birthDate!.day));

        setState(() {
          _memberStats = results[0] as MemberStats;
          _birthdayMembers = birthdayMembers;
          _balance = results[2] as FinancialBalance;
          _assetStats = results[3] as _AssetReportStats?;
          _ebdStats = results[4] as _EbdReportStats?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<_AssetReportStats?> _loadAssetStats(ApiClient apiClient) async {
    try {
      final response = await apiClient.dio.get('/v1/assets/stats');
      return _AssetReportStats.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<_EbdReportStats?> _loadEbdStats(ApiClient apiClient) async {
    try {
      final response = await apiClient.dio.get('/v1/ebd/stats');
      return _EbdReportStats.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? AppSpacing.huge : AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Members Overview ──
                      _sectionTitle('Membros', Icons.people_outlined),
                      const SizedBox(height: AppSpacing.md),
                      _buildMembersReport(isWide),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Birthday Members ──
                      _sectionTitle(
                        'Aniversariantes do Mês (${DateFormat('MMMM', 'pt_BR').format(DateTime.now())})',
                        Icons.cake_outlined,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildBirthdayList(),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Financial Overview ──
                      _sectionTitle('Financeiro', Icons.attach_money_outlined),
                      const SizedBox(height: AppSpacing.md),
                      _buildFinancialReport(isWide),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Assets Overview ──
                      _sectionTitle('Patrimônio', Icons.inventory_2_outlined),
                      const SizedBox(height: AppSpacing.md),
                      _buildAssetReport(isWide),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── EBD Overview ──
                      _sectionTitle('Escola Bíblica Dominical', Icons.school_outlined),
                      const SizedBox(height: AppSpacing.md),
                      _buildEbdReport(isWide),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Quick Navigation ──
                      _sectionTitle('Relatórios por Módulo', Icons.description_outlined),
                      const SizedBox(height: AppSpacing.md),
                      _buildModuleNavigationCards(isWide),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.accent),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.headingSmall),
      ],
    );
  }

  Widget _buildMembersReport(bool isWide) {
    if (_memberStats == null) {
      return _emptyCard('Sem dados de membros');
    }
    final stats = _memberStats!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Wrap(
          spacing: AppSpacing.xxl,
          runSpacing: AppSpacing.lg,
          children: [
            _metricTile('Total de Membros', '${stats.total}', AppColors.primary),
            _metricTile('Ativos', '${stats.totalActive}', AppColors.success),
            _metricTile('Inativos', '${stats.totalInactive}', AppColors.error),
            _metricTile('Novos (Mês)', '${stats.newMembersThisMonth}', AppColors.info),
            _metricTile('Novos (Ano)', '${stats.newMembersThisYear}', AppColors.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayList() {
    if (_birthdayMembers == null || _birthdayMembers!.isEmpty) {
      return _emptyCard('Nenhum aniversariante encontrado neste mês');
    }

    final dateFormat = DateFormat('dd/MM');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _birthdayMembers!.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final member = _birthdayMembers![index];
          final age = _calculateAge(member.birthDate!);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accent.withValues(alpha: 0.12),
              child: Text(
                _initials(member.fullName),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(member.fullName, style: AppTypography.bodyMedium),
            subtitle: Text(
              'Dia ${dateFormat.format(member.birthDate!)} · $age anos',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.cake, size: 18, color: AppColors.accent),
            onTap: () => context.go('/members/${member.id}'),
          );
        },
      ),
    );
  }

  Widget _buildFinancialReport(bool isWide) {
    if (_balance == null) {
      return _emptyCard('Sem dados financeiros');
    }
    final bal = _balance!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xxl,
              runSpacing: AppSpacing.lg,
              children: [
                _metricTile(
                  'Saldo Atual',
                  formatCurrency(bal.balance),
                  bal.balance >= 0 ? AppColors.success : AppColors.error,
                ),
                _metricTile('Total Receitas', formatCurrency(bal.totalIncome), AppColors.success),
                _metricTile('Total Despesas', formatCurrency(bal.totalExpense), AppColors.error),
              ],
            ),
            if (bal.incomeByCategory.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text('Receitas por Categoria', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.md),
              ...bal.incomeByCategory.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat.categoryName,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                        Text(
                          formatCurrency(cat.amount),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (bal.expenseByCategory.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text('Despesas por Categoria', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.md),
              ...bal.expenseByCategory.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat.categoryName,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                        Text(
                          formatCurrency(cat.amount),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssetReport(bool isWide) {
    if (_assetStats == null) {
      return _emptyCard('Sem dados de patrimônio');
    }
    final stats = _assetStats!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Wrap(
          spacing: AppSpacing.xxl,
          runSpacing: AppSpacing.lg,
          children: [
            _metricTile('Total de Bens', '${stats.totalAssets}', AppColors.primary),
            _metricTile('Ativos', '${stats.totalActive}', AppColors.success),
            _metricTile('Em Manutenção', '${stats.inMaintenance}', AppColors.accent),
            _metricTile('Emprestados', '${stats.onLoan}', AppColors.info),
            _metricTile(
              'Valor Total',
              formatCurrency(stats.totalValue),
              AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEbdReport(bool isWide) {
    if (_ebdStats == null) {
      return _emptyCard('Sem dados da EBD');
    }
    final stats = _ebdStats!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Wrap(
          spacing: AppSpacing.xxl,
          runSpacing: AppSpacing.lg,
          children: [
            _metricTile('Trimestres Ativos', '${stats.activeTerms}', AppColors.accent),
            _metricTile('Turmas', '${stats.totalClasses}', AppColors.info),
            _metricTile('Alunos Matriculados', '${stats.totalEnrolled}', AppColors.success),
            _metricTile(
              'Frequência Média',
              '${stats.avgAttendanceRate.toStringAsFixed(1)}%',
              AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleNavigationCards(bool isWide) {
    final modules = [
      (
        'Membros',
        'Listagem completa, filtros e estatísticas',
        Icons.people_outlined,
        '/members',
      ),
      (
        'Financeiro',
        'Lançamentos, balancete e fechamento mensal',
        Icons.attach_money_outlined,
        '/financial',
      ),
      (
        'Patrimônio',
        'Bens, manutenções, inventários e empréstimos',
        Icons.inventory_2_outlined,
        '/assets',
      ),
      (
        'EBD',
        'Turmas, aulas, frequência e relatórios',
        Icons.school_outlined,
        '/ebd',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 2 : 1,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 88,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final (label, description, icon, path) = modules[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: () => context.go(path),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(icon, size: 22, color: AppColors.accent),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.headingLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
