import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event_state.dart';
import '../../financial/data/financial_repository.dart';
import '../../financial/data/models/financial_models.dart';
import '../../financial/presentation/format_utils.dart';
import '../../members/data/member_repository.dart';
import '../../members/data/models/member_models.dart';

/// Dashboard stats from Assets API
class AssetStats {
  final int totalAssets;
  final int totalActive;
  final int inMaintenance;
  final int onLoan;
  final double totalValue;

  const AssetStats({
    this.totalAssets = 0,
    this.totalActive = 0,
    this.inMaintenance = 0,
    this.onLoan = 0,
    this.totalValue = 0,
  });

  factory AssetStats.fromJson(Map<String, dynamic> json) {
    return AssetStats(
      totalAssets: json['total_assets'] as int? ?? 0,
      totalActive: json['total_active'] as int? ?? 0,
      inMaintenance: json['in_maintenance'] as int? ?? 0,
      onLoan: json['on_loan'] as int? ?? 0,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Dashboard stats from EBD API
class EbdStats {
  final int totalClasses;
  final int totalEnrolled;
  final int activeTerms;
  final double avgAttendanceRate;

  const EbdStats({
    this.totalClasses = 0,
    this.totalEnrolled = 0,
    this.activeTerms = 0,
    this.avgAttendanceRate = 0,
  });

  factory EbdStats.fromJson(Map<String, dynamic> json) {
    return EbdStats(
      totalClasses: json['total_classes'] as int? ?? 0,
      totalEnrolled: json['total_enrolled'] as int? ?? 0,
      activeTerms: json['active_terms'] as int? ?? 0,
      avgAttendanceRate: (json['avg_attendance_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MemberStats? _stats;
  FinancialBalance? _financialBalance;
  AssetStats? _assetStats;
  EbdStats? _ebdStats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final memberRepo = MemberRepository(apiClient: apiClient);
      final financialRepo = FinancialRepository(apiClient: apiClient);

      // Load all stats in parallel
      final results = await Future.wait([
        memberRepo.getStats(),
        financialRepo.getBalanceReport().catchError((_) => const FinancialBalance(
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
        setState(() {
          _stats = results[0] as MemberStats;
          _financialBalance = results[1] as FinancialBalance;
          _assetStats = results[2] as AssetStats?;
          _ebdStats = results[3] as EbdStats?;
        });
      }
    } catch (_) {
      // Silently ignore – dashboard stats are non-critical
    }
  }

  Future<AssetStats?> _loadAssetStats(ApiClient apiClient) async {
    try {
      final response = await apiClient.dio.get('/v1/assets/stats');
      return AssetStats.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<EbdStats?> _loadEbdStats(ApiClient apiClient) async {
    try {
      final response = await apiClient.dio.get('/v1/ebd/stats');
      return EbdStats.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.email.split('@').first
        : 'Usuário';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: _buildHeader(context, userName),
          ),

          // ── Stats Cards ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            sliver: SliverGrid.count(
              crossAxisCount: _crossAxisCount(context),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.65,
              children: [
                _StatCard(
                  icon: Icons.people_rounded,
                  label: 'Membros Ativos',
                  value: _stats != null
                      ? '${_stats!.totalActive}'
                      : '—',
                  trend: _stats != null && _stats!.newMembersThisMonth > 0
                      ? '+${_stats!.newMembersThisMonth} este mês'
                      : null,
                  color: AppColors.primary,
                ),
                _StatCard(
                  icon: Icons.attach_money_rounded,
                  label: 'Saldo Financeiro',
                  value: _financialBalance != null
                      ? formatCurrency(_financialBalance!.balance)
                      : '—',
                  trend: _financialBalance != null && _financialBalance!.totalIncome > 0
                      ? 'Receitas: ${formatCurrency(_financialBalance!.totalIncome)}'
                      : null,
                  color: AppColors.success,
                ),
                _StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Patrimônio',
                  value: _assetStats != null
                      ? '${_assetStats!.totalActive}'
                      : '—',
                  trend: _assetStats != null && _assetStats!.inMaintenance > 0
                      ? '${_assetStats!.inMaintenance} em manutenção'
                      : null,
                  color: AppColors.info,
                ),
                _StatCard(
                  icon: Icons.school_outlined,
                  label: 'Alunos EBD',
                  value: _ebdStats != null
                      ? '${_ebdStats!.totalEnrolled}'
                      : '—',
                  trend: _ebdStats != null && _ebdStats!.totalClasses > 0
                      ? '${_ebdStats!.totalClasses} turmas ativas'
                      : null,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),

          // ── Quick Actions ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Ações Rápidas',
                style: AppTypography.headingSmall,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid.count(
              crossAxisCount: _crossAxisCount(context),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.2,
              children: [
                _QuickAction(
                  icon: Icons.person_add_outlined,
                  label: 'Novo Membro',
                  onTap: () => context.go('/members/new'),
                ),
                _QuickAction(
                  icon: Icons.family_restroom_outlined,
                  label: 'Nova Família',
                  onTap: () => context.go('/families/new'),
                ),
                _QuickAction(
                  icon: Icons.groups_outlined,
                  label: 'Novo Ministério',
                  onTap: () => context.go('/ministries/new'),
                ),
                _QuickAction(
                  icon: Icons.bar_chart_rounded,
                  label: 'Relatórios',
                  onTap: () => context.go('/reports'),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxl),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $userName',
                  style: AppTypography.headingLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Bem-vindo ao painel de gestão.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Profile / Logout
          PopupMenuButton(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            icon: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              child: Text(
                userName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              }
            },
          ),
        ],
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;
    if (width >= 800) return 2;
    return 2;
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trend;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trend,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                if (trend != null)
                  Text(
                    trend!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.textPrimary,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action ──
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: AppColors.border.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
