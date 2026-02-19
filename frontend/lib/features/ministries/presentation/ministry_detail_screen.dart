import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/ministry_repository.dart';
import '../data/models/ministry_models.dart';

class MinistryDetailScreen extends StatefulWidget {
  final String ministryId;

  const MinistryDetailScreen({super.key, required this.ministryId});

  @override
  State<MinistryDetailScreen> createState() => _MinistryDetailScreenState();
}

class _MinistryDetailScreenState extends State<MinistryDetailScreen> {
  late final MinistryRepository _repo;
  Ministry? _ministry;
  List<MinistryMember>? _members;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = MinistryRepository(
      apiClient: RepositoryProvider.of<ApiClient>(context),
    );
    _loadMinistry();
  }

  Future<void> _loadMinistry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ministry = await _repo.getMinistry(widget.ministryId);
      final members = await _repo.getMinistryMembers(widget.ministryId);
      setState(() {
        _ministry = ministry.copyWith(members: members);
        _members = members;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteMinistry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
            'Deseja remover o ministério "${_ministry?.name}"? Os membros serão desvinculados.'),
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

    if (confirmed == true && mounted) {
      try {
        await _repo.deleteMinistry(widget.ministryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ministério removido com sucesso'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/ministries');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeMember(MinistryMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover membro'),
        content: Text(
            'Deseja remover "${member.fullName}" deste ministério?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _repo.removeMember(
          ministryId: widget.ministryId,
          memberId: member.memberId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Membro removido do ministério'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadMinistry();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover membro: $e'),
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
        title: Text(_ministry?.name ?? 'Ministério'),
        actions: _ministry != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () =>
                      context.go('/ministries/${widget.ministryId}/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  tooltip: 'Excluir',
                  onPressed: _deleteMinistry,
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
              onPressed: _loadMinistry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final ministry = _ministry!;
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
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: ministry.isActive
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : AppColors.textMuted
                              .withValues(alpha: 0.12),
                      child: Icon(
                        Icons.groups_rounded,
                        color: ministry.isActive
                            ? AppColors.accent
                            : AppColors.textMuted,
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
                                child: Text(ministry.name,
                                    style: AppTypography.headingMedium),
                              ),
                              if (!ministry.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    'Inativo',
                                    style:
                                        AppTypography.labelSmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${_members?.length ?? ministry.memberCount} membros',
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
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Info ──
            _sectionTitle('Informações', Icons.info_outlined),
            const SizedBox(height: AppSpacing.md),
            _infoCard([
              if (ministry.description != null &&
                  ministry.description!.isNotEmpty)
                _infoRow(Icons.description_outlined, 'Descrição',
                    ministry.description),
              if (ministry.leaderName != null)
                _infoRow(
                    Icons.person_outlined, 'Líder', ministry.leaderName),
              _infoRow(
                Icons.toggle_on_outlined,
                'Status',
                ministry.isActive ? 'Ativo' : 'Inativo',
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // ── Members ──
            _sectionTitle('Membros do Ministério', Icons.people_outlined),
            const SizedBox(height: AppSpacing.md),
            if (_members == null || _members!.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'Nenhum membro vinculado',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ),
              )
            else
              ..._members!.map((member) => _MinistryMemberCard(
                    member: member,
                    onTap: () =>
                        context.go('/members/${member.memberId}'),
                    onRemove: () => _removeMember(member),
                  )),

            const SizedBox(height: AppSpacing.xxl),

            // ── Metadata ──
            if (ministry.createdAt != null)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Text(
                  'Cadastrado em ${dateFormat.format(ministry.createdAt!)}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

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

class _MinistryMemberCard extends StatelessWidget {
  final MinistryMember member;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _MinistryMemberCard({
    required this.member,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    _initials(member.fullName),
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
                        member.fullName,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            member.formattedRole,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (member.joinedAt != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '· desde ${dateFormat.format(member.joinedAt!)}',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textMuted,
                  tooltip: 'Remover do ministério',
                  onPressed: onRemove,
                ),
              ],
            ),
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
}
