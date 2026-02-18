import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/member_bloc.dart';
import '../bloc/member_event_state.dart';
import '../data/member_repository.dart';
import '../data/models/member_models.dart';

class MemberListScreen extends StatelessWidget {
  const MemberListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => MemberBloc(
        repository: MemberRepository(apiClient: apiClient),
      )..add(const MembersLoadRequested()),
      child: const _MemberListView(),
    );
  }
}

class _MemberListView extends StatefulWidget {
  const _MemberListView();

  @override
  State<_MemberListView> createState() => _MemberListViewState();
}

class _MemberListViewState extends State<_MemberListView> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    context.read<MemberBloc>().add(MembersLoadRequested(
          search: _searchController.text.isEmpty
              ? null
              : _searchController.text,
          status: _selectedStatus,
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
        onPressed: () => context.go('/members/new'),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Novo Membro'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Membros', style: AppTypography.headingLarge),
                const SizedBox(height: AppSpacing.xs),
                BlocBuilder<MemberBloc, MemberState>(
                  builder: (context, state) {
                    final count =
                        state is MemberLoaded ? state.totalCount : 0;
                    return Text(
                      '$count membros cadastrados',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _search(),
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _search();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Status filter
          SizedBox(
            height: 42,
            child: DropdownButtonHideUnderline(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: DropdownButton<String?>(
                  value: _selectedStatus,
                  hint: Text(
                    'Status',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'ativo', child: Text('Ativo')),
                    DropdownMenuItem(
                        value: 'inativo', child: Text('Inativo')),
                    DropdownMenuItem(
                        value: 'transferido', child: Text('Transferido')),
                    DropdownMenuItem(
                        value: 'desligado', child: Text('Desligado')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _search();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return BlocBuilder<MemberBloc, MemberState>(
      builder: (context, state) {
        if (state is MemberLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (state is MemberError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<MemberBloc>()
                      .add(const MembersLoadRequested()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (state is MemberLoaded) {
          if (state.members.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Nenhum membro encontrado',
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Adicione o primeiro membro da sua igreja.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.members.length,
            separatorBuilder: (context2, index2) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _MemberTile(member: state.members[index]);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.go('/members/${member.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  _initials(member.fullName),
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
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
                      member.phonePrimary ?? member.email ?? '—',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              _StatusBadge(status: member.status),

              const SizedBox(width: AppSpacing.sm),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.substring(0, 1).toUpperCase();
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'ativo' => ('Ativo', AppColors.active),
      'inativo' => ('Inativo', AppColors.inactive),
      'transferido' => ('Transf.', AppColors.transferred),
      'desligado' => ('Desligado', AppColors.dismissed),
      'falecido' => ('Falecido', AppColors.textMuted),
      'visitante' => ('Visitante', AppColors.info),
      _ => (status, AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
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
          fontSize: 11,
        ),
      ),
    );
  }
}
