import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/member_repository.dart';
import '../data/models/member_models.dart';

class MemberDetailScreen extends StatefulWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late final MemberRepository _repo;
  Member? _member;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = MemberRepository(
      apiClient: RepositoryProvider.of<ApiClient>(context),
    );
    _loadMember();
  }

  Future<void> _loadMember() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final member = await _repo.getMember(widget.memberId);
      setState(() {
        _member = member;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteMember() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja remover "${_member?.fullName}" da lista de membros?'),
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
        await _repo.deleteMember(widget.memberId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Membro removido com sucesso'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/members');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_member?.fullName ?? 'Membro'),
        actions: _member != null
            ? [
                IconButton(
                  icon: const Icon(Icons.history_outlined),
                  tooltip: 'Histórico',
                  onPressed: () => context.go(
                    Uri(
                      path: '/members/${widget.memberId}/history',
                      queryParameters: {'name': _member!.fullName},
                    ).toString(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => context.go('/members/${widget.memberId}/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  tooltip: 'Excluir',
                  onPressed: _deleteMember,
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
              onPressed: _loadMember,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final member = _member!;
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
            // ── Profile card ──
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
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        _initials(member.fullName),
                        style: AppTypography.headingMedium.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.fullName, style: AppTypography.headingMedium),
                          if (member.socialName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              member.socialName!,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              _StatusChip(status: member.status),
                              if (member.rolePosition != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Chip(
                                  label: Text(
                                    _formatRole(member.rolePosition!) ?? member.rolePosition!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                                  side: BorderSide.none,
                                  visualDensity: VisualDensity.compact,
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
            const SizedBox(height: AppSpacing.lg),

            // ── Personal Info ──
            _sectionTitle('Informações Pessoais', Icons.person_outlined),
            const SizedBox(height: AppSpacing.md),
            _infoCard([
              _infoRow(Icons.email_outlined, 'E-mail', member.email),
              _infoRow(Icons.phone_outlined, 'Telefone', member.phonePrimary),
              if (member.phoneSecondary != null)
                _infoRow(Icons.phone_outlined, 'Tel. Secundário', member.phoneSecondary),
              _infoRow(Icons.cake_outlined, 'Nascimento',
                  member.birthDate != null ? dateFormat.format(member.birthDate!) : null),
              _infoRow(Icons.wc_outlined, 'Sexo', _formatGender(member.gender)),
              _infoRow(Icons.favorite_border, 'Estado Civil', _formatMaritalStatus(member.maritalStatus)),
              _infoRow(Icons.badge_outlined, 'CPF', member.cpf),
              _infoRow(Icons.credit_card_outlined, 'RG', member.rg),
              _infoRow(Icons.bloodtype_outlined, 'Tipo Sanguíneo', member.bloodType),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // ── Address ──
            _sectionTitle('Endereço', Icons.location_on_outlined),
            const SizedBox(height: AppSpacing.md),
            _infoCard([
              _infoRow(Icons.map_outlined, 'Logradouro', _formatAddress(member)),
              _infoRow(Icons.location_city_outlined, 'Bairro', member.neighborhood),
              _infoRow(Icons.apartment_outlined, 'Cidade/UF',
                  _joinNotNull([member.city, member.state])),
              _infoRow(Icons.markunread_mailbox_outlined, 'CEP', member.zipCode),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // ── Additional Info ──
            _sectionTitle('Informações Adicionais', Icons.info_outlined),
            const SizedBox(height: AppSpacing.md),
            _infoCard([
              _infoRow(Icons.work_outlined, 'Profissão', member.profession),
              _infoRow(Icons.business_outlined, 'Local de Trabalho', member.workplace),
              _infoRow(Icons.public_outlined, 'Naturalidade',
                  _joinNotNull([member.birthplaceCity, member.birthplaceState])),
              _infoRow(Icons.flag_outlined, 'Nacionalidade', member.nationality),
              _infoRow(Icons.school_outlined, 'Escolaridade',
                  _formatEducation(member.educationLevel)),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // ── Ecclesiastical Info ──
            _sectionTitle('Informações Eclesiásticas', Icons.church_outlined),
            const SizedBox(height: AppSpacing.md),
            _infoCard([
              _infoRow(Icons.auto_awesome_outlined, 'Conversão',
                  member.conversionDate != null ? dateFormat.format(member.conversionDate!) : null),
              _infoRow(Icons.water_drop_outlined, 'Batismo nas Águas',
                  member.waterBaptismDate != null ? dateFormat.format(member.waterBaptismDate!) : null),
              _infoRow(Icons.local_fire_department_outlined, 'Batismo no Espírito',
                  member.spiritBaptismDate != null ? dateFormat.format(member.spiritBaptismDate!) : null),
              _infoRow(Icons.church_outlined, 'Igreja de Origem', member.originChurch),
              _infoRow(Icons.calendar_today_outlined, 'Data de Ingresso',
                  member.entryDate != null ? dateFormat.format(member.entryDate!) : null),
              _infoRow(Icons.login_outlined, 'Forma de Ingresso',
                  _formatEntryType(member.entryType)),
              _infoRow(Icons.badge_outlined, 'Cargo / Função',
                  _formatRole(member.rolePosition)),
              _infoRow(Icons.star_outline, 'Consagração',
                  member.ordinationDate != null ? dateFormat.format(member.ordinationDate!) : null),
            ]),

            if (member.notes != null && member.notes!.isNotEmpty) ...[
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
                    member.notes!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),

            // ── Metadata footer ──
            if (member.createdAt != null || member.updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Text(
                  [
                    if (member.createdAt != null) 'Cadastrado em ${dateFormat.format(member.createdAt!)}',
                    if (member.updatedAt != null) 'Atualizado em ${dateFormat.format(member.updatedAt!)}',
                  ].join(' · '),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
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
    // Filter out null-valued rows
    final validRows = rows.whereType<Widget>().toList();
    if (validRows.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Nenhuma informação cadastrada',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

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
          width: 140,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value ?? '—',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: value != null ? AppColors.textPrimary : AppColors.textMuted,
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  String _formatAddress(Member m) {
    final parts = <String>[];
    if (m.street != null) parts.add(m.street!);
    if (m.number != null) parts.add('nº ${m.number}');
    if (m.complement != null) parts.add(m.complement!);
    return parts.isNotEmpty ? parts.join(', ') : '—';
  }

  String? _joinNotNull(List<String?> parts) {
    final valid = parts.where((p) => p != null && p.isNotEmpty).toList();
    return valid.isNotEmpty ? valid.join(' - ') : null;
  }

  String _formatGender(String? gender) {
    return switch (gender) {
      'masculino' => 'Masculino',
      'feminino' => 'Feminino',
      _ => gender ?? '—',
    };
  }

  String? _formatMaritalStatus(String? ms) {
    return switch (ms) {
      'solteiro' => 'Solteiro(a)',
      'casado' => 'Casado(a)',
      'divorciado' => 'Divorciado(a)',
      'viuvo' => 'Viúvo(a)',
      'uniao_estavel' => 'União Estável',
      null => null,
      _ => ms,
    };
  }

  String? _formatEntryType(String? et) {
    return switch (et) {
      'batismo' => 'Batismo',
      'transferencia' => 'Transferência',
      'aclamacao' => 'Aclamação',
      'reconciliacao' => 'Reconciliação',
      null => null,
      _ => et,
    };
  }

  String? _formatRole(String? role) {
    return switch (role) {
      'membro' => 'Membro',
      'cooperador' => 'Cooperador(a)',
      'diacono' => 'Diácono/Diaconisa',
      'presbitero' => 'Presbítero',
      'evangelista' => 'Evangelista',
      'pastor' => 'Pastor(a)',
      null => null,
      _ => role,
    };
  }

  String? _formatEducation(String? edu) {
    return switch (edu) {
      'fundamental_incompleto' => 'Fundamental Incompleto',
      'fundamental_completo' => 'Fundamental Completo',
      'medio_incompleto' => 'Médio Incompleto',
      'medio_completo' => 'Médio Completo',
      'superior_incompleto' => 'Superior Incompleto',
      'superior_completo' => 'Superior Completo',
      'pos_graduacao' => 'Pós-Graduação',
      'mestrado' => 'Mestrado',
      'doutorado' => 'Doutorado',
      null => null,
      _ => edu,
    };
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'ativo' => ('Ativo', AppColors.active),
      'inativo' => ('Inativo', AppColors.inactive),
      'transferido' => ('Transferido', AppColors.transferred),
      'desligado' => ('Desligado', AppColors.dismissed),
      'falecido' => ('Falecido', AppColors.textMuted),
      'visitante' => ('Visitante', AppColors.info),
      _ => (status, AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
