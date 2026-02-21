import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/congregation_repository.dart';
import '../../data/models/congregation_models.dart';

class CongregationDetailPage extends StatefulWidget {
  final String congregationId;

  const CongregationDetailPage({super.key, required this.congregationId});

  @override
  State<CongregationDetailPage> createState() =>
      _CongregationDetailPageState();
}

class _CongregationDetailPageState extends State<CongregationDetailPage> {
  late final CongregationRepository _repo;
  Congregation? _congregation;
  CongregationStats? _stats;
  List<CongregationUser>? _users;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = CongregationRepository(
      apiClient: RepositoryProvider.of<ApiClient>(context),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getCongregation(widget.congregationId),
        _repo.getCongregationStats(widget.congregationId),
        _repo.getCongregationUsers(widget.congregationId),
      ]);
      setState(() {
        _congregation = results[0] as Congregation;
        _stats = results[1] as CongregationStats;
        _users = results[2] as List<CongregationUser>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deactivateCongregation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar Congregação'),
        content: Text(
            'Deseja desativar "${_congregation?.name}"? Os membros permanecerão sem congregação vinculada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _repo.deactivateCongregation(widget.congregationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Congregação desativada com sucesso'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/settings/congregations');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao desativar: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_congregation?.name ?? 'Congregação'),
        actions: _congregation != null
            ? [
                IconButton(
                  icon: const Icon(Icons.group_add_outlined),
                  tooltip: 'Atribuir Membros',
                  onPressed: () => context.go(
                      '/settings/congregations/${widget.congregationId}/assign-members'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => context.go(
                      '/settings/congregations/${widget.congregationId}/edit',
                      extra: _congregation),
                ),
                if (_congregation!.type != 'sede')
                  IconButton(
                    icon: const Icon(Icons.block_outlined,
                        color: AppColors.error),
                    tooltip: 'Desativar',
                    onPressed: _deactivateCongregation,
                  ),
                const SizedBox(width: AppSpacing.sm),
              ]
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final congregation = _congregation!;
    final stats = _stats;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isWide = MediaQuery.of(context).size.width >= 800;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? AppSpacing.huge : AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ──
            _buildHeaderCard(congregation),
            const SizedBox(height: AppSpacing.lg),

            // ── Stats ──
            if (stats != null) ...[
              _sectionTitle('Estatísticas', Icons.analytics_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildStatsGrid(stats),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── Info ──
            _sectionTitle('Informações', Icons.info_outlined),
            const SizedBox(height: AppSpacing.md),
            _buildInfoCard(congregation),
            const SizedBox(height: AppSpacing.lg),

            // ── Address ──
            if (_hasAddress(congregation)) ...[
              _sectionTitle('Endereço', Icons.location_on_outlined),
              const SizedBox(height: AppSpacing.md),
              _buildAddressCard(congregation),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── Users (access) ──
            _sectionTitle('Usuários com Acesso', Icons.admin_panel_settings_outlined),
            const SizedBox(height: AppSpacing.md),
            _buildUsersSection(),
            const SizedBox(height: AppSpacing.lg),

            // ── Metadata ──
            if (congregation.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Text(
                  'Cadastrada em ${dateFormat.format(congregation.createdAt!)}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Congregation congregation) {
    IconData typeIcon;
    Color typeColor;
    switch (congregation.type) {
      case 'sede':
        typeIcon = Icons.account_balance_rounded;
        typeColor = AppColors.accent;
        break;
      case 'ponto_de_pregacao':
        typeIcon = Icons.pin_drop_rounded;
        typeColor = AppColors.info;
        break;
      default:
        typeIcon = Icons.church_rounded;
        typeColor = AppColors.primary;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: congregation.isActive
                  ? typeColor.withValues(alpha: 0.12)
                  : AppColors.textMuted.withValues(alpha: 0.12),
              child: Icon(
                typeIcon,
                color: congregation.isActive ? typeColor : AppColors.textMuted,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(congregation.name,
                            style: AppTypography.headingMedium),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: congregation.isActive
                              ? typeColor.withValues(alpha: 0.1)
                              : AppColors.textMuted.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          congregation.isActive
                              ? congregation.typeLabel
                              : 'Inativa',
                          style: AppTypography.labelSmall.copyWith(
                            color: congregation.isActive
                                ? typeColor
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (congregation.shortName != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      congregation.shortName!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${congregation.activeMembers} membros ativos',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(CongregationStats stats) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _StatCard(
          icon: Icons.people_rounded,
          label: 'Membros Ativos',
          value: '${stats.activeMembers}',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.group_add_rounded,
          label: 'Novos no Mês',
          value: '${stats.newThisMonth}',
          color: AppColors.success,
        ),
        _StatCard(
          icon: Icons.trending_up_rounded,
          label: 'Receitas (Mês)',
          value: _formatCurrency(stats.incomeThisMonth),
          color: AppColors.success,
        ),
        _StatCard(
          icon: Icons.trending_down_rounded,
          label: 'Despesas (Mês)',
          value: _formatCurrency(stats.expenseThisMonth),
          color: AppColors.error,
        ),
        _StatCard(
          icon: Icons.school_rounded,
          label: 'Classes EBD',
          value: '${stats.ebdClasses}',
          color: AppColors.info,
        ),
        _StatCard(
          icon: Icons.inventory_2_rounded,
          label: 'Patrimônios',
          value: '${stats.totalAssets}',
          color: AppColors.accentDark,
        ),
      ],
    );
  }

  Widget _buildInfoCard(Congregation congregation) {
    return _infoCard([
      if (congregation.leaderName != null)
        _infoRow(Icons.person_outlined, 'Dirigente', congregation.leaderName),
      if (congregation.phone != null && congregation.phone!.isNotEmpty)
        _infoRow(Icons.phone_outlined, 'Telefone', congregation.phone),
      if (congregation.email != null && congregation.email!.isNotEmpty)
        _infoRow(Icons.email_outlined, 'E-mail', congregation.email),
      _infoRow(
        Icons.toggle_on_outlined,
        'Status',
        congregation.isActive ? 'Ativa' : 'Inativa',
      ),
      _infoRow(Icons.tag_rounded, 'Tipo', congregation.typeLabel),
    ]);
  }

  bool _hasAddress(Congregation c) {
    return (c.street != null && c.street!.isNotEmpty) ||
        (c.city != null && c.city!.isNotEmpty) ||
        (c.neighborhood != null && c.neighborhood!.isNotEmpty);
  }

  Widget _buildAddressCard(Congregation c) {
    final parts = <String>[];
    if (c.street != null && c.street!.isNotEmpty) {
      var line = c.street!;
      if (c.number != null && c.number!.isNotEmpty) line += ', ${c.number}';
      if (c.complement != null && c.complement!.isNotEmpty) {
        line += ' - ${c.complement}';
      }
      parts.add(line);
    }
    if (c.neighborhood != null && c.neighborhood!.isNotEmpty) {
      parts.add(c.neighborhood!);
    }
    final cityState = <String>[];
    if (c.city != null && c.city!.isNotEmpty) cityState.add(c.city!);
    if (c.state != null && c.state!.isNotEmpty) cityState.add(c.state!);
    if (cityState.isNotEmpty) parts.add(cityState.join(' - '));
    if (c.zipCode != null && c.zipCode!.isNotEmpty) {
      parts.add('CEP: ${c.zipCode}');
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined,
                size: 20, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                parts.join('\n'),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersSection() {
    if (_users == null || _users!.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Text(
              'Nenhum usuário com acesso específico',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _users!.map((user) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: const BorderSide(color: AppColors.border, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      user.email[0].toUpperCase(),
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              user.roleLabel,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (user.isPrimary) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                                child: Text(
                                  'Principal',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.success,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
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

  Widget _infoCard(List<Widget> rows) {
    final validRows = rows.whereType<Widget>().toList();
    if (validRows.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: _intersperse(
            validRows,
            const Divider(height: AppSpacing.lg),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 100,
          child: Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value ?? '—',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: value != null
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return fmt.format(value);
  }

  List<Widget> _intersperse(List<Widget> list, Widget separator) {
    if (list.isEmpty) return [];
    final result = <Widget>[list.first];
    for (int i = 1; i < list.length; i++) {
      result.add(separator);
      result.add(list[i]);
    }
    return result;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
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
              Icon(icon, size: 22, color: color),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: AppTypography.headingSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
