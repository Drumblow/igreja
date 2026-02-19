import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/financial_bloc.dart';
import '../bloc/financial_event_state.dart';
import '../data/financial_repository.dart';
import 'format_utils.dart';

class FinancialOverviewScreen extends StatelessWidget {
  const FinancialOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => FinancialBloc(
        repository: FinancialRepository(apiClient: apiClient),
      )..add(const FinancialBalanceLoadRequested()),
      child: const _FinancialOverviewView(),
    );
  }
}

class _FinancialOverviewView extends StatefulWidget {
  const _FinancialOverviewView();

  @override
  State<_FinancialOverviewView> createState() => _FinancialOverviewViewState();
}

class _FinancialOverviewViewState extends State<_FinancialOverviewView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildBalanceSummary()),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Ações Rápidas', style: AppTypography.headingSmall),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid.count(
              crossAxisCount: _crossAxisCount(context),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.2,
              children: [
                _QuickAction(
                  icon: Icons.add_circle_outline,
                  label: 'Nova Receita',
                  onTap: () => context.go('/financial/entries/new?type=receita'),
                ),
                _QuickAction(
                  icon: Icons.remove_circle_outline,
                  label: 'Nova Despesa',
                  onTap: () => context.go('/financial/entries/new?type=despesa'),
                ),
                _QuickAction(
                  icon: Icons.list_alt_rounded,
                  label: 'Lançamentos',
                  onTap: () => context.go('/financial/entries'),
                ),
                _QuickAction(
                  icon: Icons.account_tree_outlined,
                  label: 'Plano de Contas',
                  onTap: () => context.go('/financial/account-plans'),
                ),
                _QuickAction(
                  icon: Icons.account_balance_outlined,
                  label: 'Contas Bancárias',
                  onTap: () => context.go('/financial/bank-accounts'),
                ),
                _QuickAction(
                  icon: Icons.campaign_outlined,
                  label: 'Campanhas',
                  onTap: () => context.go('/financial/campaigns'),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financeiro', style: AppTypography.headingLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Visão geral das finanças da igreja',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary() {
    return BlocBuilder<FinancialBloc, FinancialState>(
      builder: (context, state) {
        double totalIncome = 0;
        double totalExpense = 0;
        double balance = 0;

        if (state is FinancialBalanceLoaded) {
          totalIncome = state.balance.totalIncome;
          totalExpense = state.balance.totalExpense;
          balance = state.balance.balance;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              // Main balance card
              Card(
                elevation: 0,
                color: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Atual',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      state is FinancialLoading
                          ? const SizedBox(
                              height: 36,
                              width: 36,
                              child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                            )
                          : Text(
                              formatCurrency(balance),
                              style: AppTypography.displaySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                      if (state is FinancialError)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Text(
                            'Sem dados financeiros ainda',
                            style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.5)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Income & Expense row
              Row(
                children: [
                  Expanded(
                    child: _BalanceCard(
                      label: 'Receitas',
                      value: totalIncome,
                      icon: Icons.trending_up_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _BalanceCard(
                      label: 'Despesas',
                      value: totalExpense,
                      icon: Icons.trending_down_rounded,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 3;
    if (width >= 800) return 3;
    return 2;
  }
}

// ==========================================
// Shared Widgets
// ==========================================

class _BalanceCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _BalanceCard({
    required this.label,
    required this.value,
    required this.icon,
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
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              formatCurrency(value),
              style: AppTypography.headingSmall.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1),
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
                child: Icon(icon, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
