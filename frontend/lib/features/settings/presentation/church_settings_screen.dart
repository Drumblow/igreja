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

/// Church profile / settings screen.
/// For super_admin: lists all churches. For other roles: shows own church.
class ChurchSettingsScreen extends StatelessWidget {
  const ChurchSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => SettingsBloc(
        repository: SettingsRepository(apiClient: apiClient),
      )..add(const ChurchLoadRequested()),
      child: const _ChurchSettingsBody(),
    );
  }
}

class _ChurchSettingsBody extends StatelessWidget {
  const _ChurchSettingsBody();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<SettingsBloc>().add(const ChurchLoadRequested());
          } else if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (state is ChurchLoaded) {
            return _ChurchDetailView(
              church: state.church,
              isWide: isWide,
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
                  Text(state.message, style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => context
                        .read<SettingsBloc>()
                        .add(const ChurchLoadRequested()),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        },
      ),
    );
  }
}

class _ChurchDetailView extends StatelessWidget {
  final Church church;
  final bool isWide;

  const _ChurchDetailView({required this.church, required this.isWide});

  @override
  Widget build(BuildContext context) {
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
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.church_outlined,
                      color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(church.name, style: AppTypography.headingLarge),
                      if (church.denomination != null)
                        Text(
                          church.denomination!,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showEditDialog(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Info cards
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _infoCard(context)),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: _addressCard(context)),
                ],
              )
            else ...[
              _infoCard(context),
              const SizedBox(height: AppSpacing.lg),
              _addressCard(context),
            ],
            const SizedBox(height: AppSpacing.lg),
            _contactCard(context),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    return _SectionCard(
      title: 'Informações Gerais',
      icon: Icons.info_outlined,
      children: [
        _InfoRow(label: 'Nome', value: church.name),
        if (church.legalName != null)
          _InfoRow(label: 'Razão Social', value: church.legalName!),
        if (church.cnpj != null) _InfoRow(label: 'CNPJ', value: church.cnpj!),
        if (church.denomination != null)
          _InfoRow(label: 'Denominação', value: church.denomination!),
        if (church.pastorName != null)
          _InfoRow(label: 'Pastor', value: church.pastorName!),
        if (church.foundedAt != null)
          _InfoRow(label: 'Fundação', value: church.foundedAt!),
        _InfoRow(
          label: 'Status',
          value: church.isActive ? 'Ativa' : 'Inativa',
          valueColor: church.isActive ? AppColors.success : AppColors.error,
        ),
      ],
    );
  }

  Widget _addressCard(BuildContext context) {
    final hasAddress = church.street != null || church.city != null;
    return _SectionCard(
      title: 'Endereço',
      icon: Icons.location_on_outlined,
      children: hasAddress
          ? [
              if (church.street != null)
                _InfoRow(
                  label: 'Logradouro',
                  value:
                      '${church.street}${church.number != null ? ', ${church.number}' : ''}'
                      '${church.complement != null ? ' - ${church.complement}' : ''}',
                ),
              if (church.neighborhood != null)
                _InfoRow(label: 'Bairro', value: church.neighborhood!),
              if (church.city != null)
                _InfoRow(
                  label: 'Cidade/UF',
                  value:
                      '${church.city}${church.state != null ? '/${church.state}' : ''}',
                ),
              if (church.zipCode != null)
                _InfoRow(label: 'CEP', value: church.zipCode!),
            ]
          : [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Endereço não cadastrado',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
    );
  }

  Widget _contactCard(BuildContext context) {
    return _SectionCard(
      title: 'Contato',
      icon: Icons.contact_phone_outlined,
      children: [
        if (church.email != null)
          _InfoRow(label: 'E-mail', value: church.email!),
        if (church.phone != null)
          _InfoRow(label: 'Telefone', value: church.phone!),
        if (church.website != null)
          _InfoRow(label: 'Website', value: church.website!),
        if (church.email == null &&
            church.phone == null &&
            church.website == null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Nenhum contato cadastrado',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    final bloc = context.read<SettingsBloc>();
    final nameCtrl = TextEditingController(text: church.name);
    final legalNameCtrl = TextEditingController(text: church.legalName ?? '');
    final cnpjCtrl = TextEditingController(text: church.cnpj ?? '');
    final emailCtrl = TextEditingController(text: church.email ?? '');
    final phoneCtrl = TextEditingController(text: church.phone ?? '');
    final websiteCtrl = TextEditingController(text: church.website ?? '');
    final denominationCtrl =
        TextEditingController(text: church.denomination ?? '');
    final pastorCtrl = TextEditingController(text: church.pastorName ?? '');
    final zipCtrl = TextEditingController(text: church.zipCode ?? '');
    final streetCtrl = TextEditingController(text: church.street ?? '');
    final numberCtrl = TextEditingController(text: church.number ?? '');
    final complementCtrl =
        TextEditingController(text: church.complement ?? '');
    final neighborhoodCtrl =
        TextEditingController(text: church.neighborhood ?? '');
    final cityCtrl = TextEditingController(text: church.city ?? '');
    final stateCtrl = TextEditingController(text: church.state ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Editar Igreja'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: legalNameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Razão Social'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: cnpjCtrl,
                  decoration: const InputDecoration(labelText: 'CNPJ'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: denominationCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Denominação'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: pastorCtrl,
                  decoration: const InputDecoration(labelText: 'Pastor'),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: websiteCtrl,
                  decoration: const InputDecoration(labelText: 'Website'),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: zipCtrl,
                  decoration: const InputDecoration(labelText: 'CEP'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: streetCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Logradouro'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: numberCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Número'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: complementCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Complemento'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: neighborhoodCtrl,
                  decoration: const InputDecoration(labelText: 'Bairro'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: cityCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Cidade'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: stateCtrl,
                        decoration:
                            const InputDecoration(labelText: 'UF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final data = <String, dynamic>{
                'name': nameCtrl.text.trim(),
              };
              void addIfNotEmpty(String key, String val) {
                if (val.isNotEmpty) data[key] = val;
              }

              addIfNotEmpty('legal_name', legalNameCtrl.text.trim());
              addIfNotEmpty('cnpj', cnpjCtrl.text.trim());
              addIfNotEmpty('email', emailCtrl.text.trim());
              addIfNotEmpty('phone', phoneCtrl.text.trim());
              addIfNotEmpty('website', websiteCtrl.text.trim());
              addIfNotEmpty('denomination', denominationCtrl.text.trim());
              addIfNotEmpty('pastor_name', pastorCtrl.text.trim());
              addIfNotEmpty('zip_code', zipCtrl.text.trim());
              addIfNotEmpty('street', streetCtrl.text.trim());
              addIfNotEmpty('number', numberCtrl.text.trim());
              addIfNotEmpty('complement', complementCtrl.text.trim());
              addIfNotEmpty('neighborhood', neighborhoodCtrl.text.trim());
              addIfNotEmpty('city', cityCtrl.text.trim());
              addIfNotEmpty('state', stateCtrl.text.trim());

              bloc.add(ChurchUpdateRequested(
                  churchId: church.id, data: data));
              Navigator.pop(dialogCtx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// Shared Widgets
// ══════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTypography.labelLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
