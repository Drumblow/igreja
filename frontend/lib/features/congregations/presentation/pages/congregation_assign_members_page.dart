import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../members/data/member_repository.dart';
import '../../../members/data/models/member_models.dart';
import '../../bloc/congregation_bloc.dart';
import '../../bloc/congregation_event_state.dart';
import '../../data/congregation_repository.dart';

/// Page for batch assignment of members to a congregation.
class CongregationAssignMembersPage extends StatelessWidget {
  final String congregationId;

  const CongregationAssignMembersPage({
    super.key,
    required this.congregationId,
  });

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => CongregationBloc(
        repository: CongregationRepository(apiClient: apiClient),
      ),
      child: _AssignMembersView(congregationId: congregationId),
    );
  }
}

class _AssignMembersView extends StatefulWidget {
  final String congregationId;

  const _AssignMembersView({required this.congregationId});

  @override
  State<_AssignMembersView> createState() => _AssignMembersViewState();
}

class _AssignMembersViewState extends State<_AssignMembersView> {
  final _searchCtrl = TextEditingController();
  late final MemberRepository _memberRepo;
  List<Member> _searchResults = [];
  final Set<String> _selectedMemberIds = {};
  final Map<String, String> _selectedMemberNames = {};
  bool _searching = false;
  bool _overwrite = false;

  @override
  void initState() {
    super.initState();
    _memberRepo = MemberRepository(
      apiClient: RepositoryProvider.of<ApiClient>(context),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final result = await _memberRepo.getMembers(
        page: 1,
        search: query.trim(),
      );
      setState(() {
        _searchResults = result.members;
        _searching = false;
      });
    } catch (_) {
      setState(() => _searching = false);
    }
  }

  void _toggleMember(Member member) {
    setState(() {
      if (_selectedMemberIds.contains(member.id)) {
        _selectedMemberIds.remove(member.id);
        _selectedMemberNames.remove(member.id);
      } else {
        _selectedMemberIds.add(member.id);
        _selectedMemberNames[member.id] = member.fullName;
      }
    });
  }

  void _removeMember(String memberId) {
    setState(() {
      _selectedMemberIds.remove(memberId);
      _selectedMemberNames.remove(memberId);
    });
  }

  void _submit() {
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um membro'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<CongregationBloc>().add(
          CongregationAssignMembersRequested(
            congregationId: widget.congregationId,
            memberIds: _selectedMemberIds.toList(),
            overwrite: _overwrite,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Atribuir Membros'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: BlocBuilder<CongregationBloc, CongregationState>(
              builder: (context, state) {
                final isLoading = state is CongregationLoading;
                return FilledButton.icon(
                  onPressed:
                      isLoading || _selectedMemberIds.isEmpty ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(
                      'Atribuir (${_selectedMemberIds.length})'),
                );
              },
            ),
          ),
        ],
      ),
      body: BlocListener<CongregationBloc, CongregationState>(
        listener: (context, state) {
          if (state is CongregationMembersAssigned) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go(
                '/settings/congregations/${widget.congregationId}');
          } else if (state is CongregationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? AppSpacing.huge : AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected members chips
                if (_selectedMemberIds.isNotEmpty) ...[
                  Text(
                    '${_selectedMemberIds.length} membro(s) selecionado(s)',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _selectedMemberNames.entries.map((entry) {
                      return Chip(
                        label: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeMember(entry.key),
                        backgroundColor:
                            AppColors.accent.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Overwrite toggle
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Sobrescrever congregação anterior',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _overwrite
                            ? 'Membros já vinculados a outra congregação serão transferidos'
                            : 'Membros já vinculados a outra congregação serão ignorados',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      value: _overwrite,
                      onChanged: (v) => setState(() => _overwrite = v),
                      activeThumbColor: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Search
                TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: 'Buscar membro por nome...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _search('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Results
                Expanded(
                  child: _buildSearchResults(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.accent, strokeWidth: 2),
      );
    }

    if (_searchResults.isEmpty && _searchCtrl.text.trim().length >= 2) {
      return Center(
        child: Text(
          'Nenhum membro encontrado',
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined,
                size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Digite o nome do membro para buscar',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (_, i) {
        final member = _searchResults[i];
        final isSelected = _selectedMemberIds.contains(member.id);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.04)
              : null,
          child: ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.primaryLight,
              child: isSelected
                  ? const Icon(Icons.check, color: AppColors.accent, size: 20)
                  : Text(
                      _initials(member.fullName),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            title: Text(
              member.fullName,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: member.phonePrimary != null
                ? Text(member.phonePrimary!,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted))
                : null,
            onTap: () => _toggleMember(member),
          ),
        );
      },
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
