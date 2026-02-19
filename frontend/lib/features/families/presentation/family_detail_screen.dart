import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/family_repository.dart';
import '../data/models/family_models.dart';

class FamilyDetailScreen extends StatefulWidget {
  final String familyId;

  const FamilyDetailScreen({super.key, required this.familyId});

  @override
  State<FamilyDetailScreen> createState() => _FamilyDetailScreenState();
}

class _FamilyDetailScreenState extends State<FamilyDetailScreen> {
  late final FamilyRepository _repo;
  Family? _family;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = FamilyRepository(
      apiClient: RepositoryProvider.of<ApiClient>(context),
    );
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final family = await _repo.getFamily(widget.familyId);
      setState(() {
        _family = family;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
            'Deseja remover a "${_family?.name}"? Os membros serão desvinculados.'),
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
        await _repo.deleteFamily(widget.familyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Família removida com sucesso'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/families');
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

  Future<void> _removeMember(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover membro'),
        content:
            Text('Deseja remover "${member.fullName}" desta família?'),
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
          familyId: widget.familyId,
          memberId: member.memberId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Membro removido da família'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadFamily();
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
        title: Text(_family?.name ?? 'Família'),
        actions: _family != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () =>
                      context.go('/families/${widget.familyId}/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  tooltip: 'Excluir',
                  onPressed: _deleteFamily,
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _loadFamily,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final family = _family!;
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
            // ── Family header card ──
            Card(
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
                      backgroundColor:
                          AppColors.accent.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        color: AppColors.accent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(family.name,
                              style: AppTypography.headingMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${family.members?.length ?? 0} membros',
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

            // ── Address ──
            if (family.formattedAddress.isNotEmpty ||
                family.cityState.isNotEmpty) ...[
              _sectionTitle('Endereço', Icons.location_on_outlined),
              const SizedBox(height: AppSpacing.md),
              _infoCard([
                if (family.formattedAddress.isNotEmpty)
                  _infoRow(Icons.map_outlined, 'Logradouro',
                      family.formattedAddress),
                if (family.neighborhood != null)
                  _infoRow(Icons.location_city_outlined, 'Bairro',
                      family.neighborhood),
                if (family.cityState.isNotEmpty)
                  _infoRow(Icons.apartment_outlined, 'Cidade/UF',
                      family.cityState),
                if (family.zipCode != null)
                  _infoRow(Icons.markunread_mailbox_outlined, 'CEP',
                      family.zipCode),
              ]),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── Members ──
            _sectionTitle('Membros da Família', Icons.people_outlined),
            const SizedBox(height: AppSpacing.md),
            if (family.members == null || family.members!.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
              ...family.members!.map((member) => _MemberCard(
                    member: member,
                    onTap: () =>
                        context.go('/members/${member.memberId}'),
                    onRemove: () => _removeMember(member),
                  )),

            if (family.notes != null && family.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _sectionTitle('Observações', Icons.note_outlined),
              const SizedBox(height: AppSpacing.md),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    family.notes!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),

            // ── Metadata ──
            if (family.createdAt != null || family.updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Text(
                  [
                    if (family.createdAt != null)
                      'Cadastrada em ${dateFormat.format(family.createdAt!)}',
                    if (family.updatedAt != null)
                      'Atualizada em ${dateFormat.format(family.updatedAt!)}',
                  ].join(' · '),
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
              color:
                  value != null ? AppColors.textPrimary : AppColors.textMuted,
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

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.member,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
                      Text(
                        member.formattedRelationship,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (member.phonePrimary != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(right: AppSpacing.sm),
                    child: Text(
                      member.phonePrimary!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textMuted,
                  tooltip: 'Remover da família',
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
