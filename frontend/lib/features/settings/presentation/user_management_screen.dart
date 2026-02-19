import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event_state.dart';
import '../data/models/settings_models.dart';
import '../data/settings_repository.dart';

/// User management screen — list, create and edit users/roles.
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => SettingsBloc(
        repository: SettingsRepository(apiClient: apiClient),
      )..add(const UsersLoadRequested()),
      child: const _UserManagementBody(),
    );
  }
}

class _UserManagementBody extends StatefulWidget {
  const _UserManagementBody();

  @override
  State<_UserManagementBody> createState() => _UserManagementBodyState();
}

class _UserManagementBodyState extends State<_UserManagementBody> {
  final _searchController = TextEditingController();
  List<AppRole> _cachedRoles = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Novo Usuário'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? AppSpacing.huge : AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gestão de Usuários', style: AppTypography.headingLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Gerencie os acessos ao sistema',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por e-mail...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<SettingsBloc>()
                            .add(const UsersLoadRequested());
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  onSubmitted: (value) {
                    context.read<SettingsBloc>().add(
                          UsersLoadRequested(
                              search: value.isNotEmpty ? value : null),
                        );
                  },
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: BlocConsumer<SettingsBloc, SettingsState>(
              listener: (context, state) {
                if (state is SettingsSaved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context
                      .read<SettingsBloc>()
                      .add(const UsersLoadRequested());
                } else if (state is SettingsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } else if (state is UsersLoaded) {
                  _cachedRoles = state.roles;
                }
              },
              builder: (context, state) {
                if (state is SettingsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                if (state is UsersLoaded) {
                  if (state.users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: AppSpacing.md),
                          Text('Nenhum usuário encontrado',
                              style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? AppSpacing.huge : AppSpacing.lg,
                    ),
                    itemCount: state.users.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final user = state.users[index];
                      return _UserCard(
                        user: user,
                        roles: state.roles,
                        onEdit: () =>
                            _showEditUserDialog(context, user, state.roles),
                      );
                    },
                  );
                }

                if (state is SettingsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: AppSpacing.md),
                        Text(state.message,
                            style: AppTypography.bodyMedium),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () => context
                              .read<SettingsBloc>()
                              .add(const UsersLoadRequested()),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? selectedRoleId;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Novo Usuário'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'E-mail *',
                    hintText: 'usuario@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Senha *',
                    hintText: 'Mínimo 8 caracteres',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Papel *'),
                  value: selectedRoleId,
                  items: _cachedRoles
                      .map((r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.displayName),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedRoleId = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (emailCtrl.text.trim().isEmpty ||
                    passwordCtrl.text.trim().isEmpty ||
                    selectedRoleId == null) {
                  return;
                }
                bloc.add(UserCreateRequested(data: {
                  'email': emailCtrl.text.trim(),
                  'password': passwordCtrl.text.trim(),
                  'role_id': selectedRoleId,
                }));
                Navigator.pop(dialogCtx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(
      BuildContext context, AppUser user, List<AppRole> roles) {
    final bloc = context.read<SettingsBloc>();
    final emailCtrl = TextEditingController(text: user.email);
    String? selectedRoleId = roles
        .where((r) => r.name == user.roleName)
        .map((r) => r.id)
        .firstOrNull;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text('Editar Usuário'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Papel'),
                  value: selectedRoleId,
                  items: roles
                      .map((r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.displayName),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedRoleId = val);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  title: const Text('Ativo'),
                  subtitle: Text(isActive ? 'Acesso liberado' : 'Acesso bloqueado'),
                  value: isActive,
                  onChanged: (val) {
                    setDialogState(() => isActive = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final data = <String, dynamic>{};
                if (emailCtrl.text.trim() != user.email) {
                  data['email'] = emailCtrl.text.trim();
                }
                if (selectedRoleId != null) {
                  data['role_id'] = selectedRoleId;
                }
                data['is_active'] = isActive;

                bloc.add(UserUpdateRequested(userId: user.id, data: data));
                Navigator.pop(dialogCtx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final List<AppRole> roles;
  final VoidCallback onEdit;

  const _UserCard({
    required this.user,
    required this.roles,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: user.isActive
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.textMuted.withValues(alpha: 0.12),
                child: Icon(
                  Icons.person_outlined,
                  color: user.isActive ? AppColors.accent : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email, style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (user.roleDisplayName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              user.roleDisplayName!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: user.isActive
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            user.isActive ? 'Ativo' : 'Inativo',
                            style: AppTypography.bodySmall.copyWith(
                              color: user.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user.lastLoginAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Último acesso: ${dateFormat.format(user.lastLoginAt!.toLocal())}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),

              // Edit icon
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
