import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../financial/presentation/format_utils.dart';
import '../data/asset_repository.dart';
import '../data/models/asset_models.dart';

class AssetDetailScreen extends StatefulWidget {
  final String assetId;
  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  Asset? _asset;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiClient = RepositoryProvider.of<ApiClient>(context);
      final repo = AssetRepository(apiClient: apiClient);
      final asset = await repo.getAsset(widget.assetId);
      setState(() {
        _asset = asset;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Baixa'),
        content: const Text(
          'Deseja realmente dar baixa neste bem? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmar Baixa'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        final apiClient = RepositoryProvider.of<ApiClient>(context);
        final repo = AssetRepository(apiClient: apiClient);
        await repo.deleteAsset(widget.assetId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bem baixado com sucesso')),
          );
          context.go('/assets/items');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao baixar bem: $e')),
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
        title: Text(_asset?.assetCode ?? 'Bem'),
        actions: [
          if (_asset != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.go('/assets/items/${widget.assetId}/edit', extra: _asset),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text(_error!, style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton.icon(
                        onPressed: _loadAsset,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final a = _asset!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.inventory_2_rounded,
                            color: AppColors.accent, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.assetCode,
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(a.description,
                                style: AppTypography.headingSmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _Badge(label: a.statusLabel, color: _statusColor(a.status)),
                      const SizedBox(width: AppSpacing.sm),
                      _Badge(
                          label: a.conditionLabel,
                          color: _conditionColor(a.condition)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Identification
          _SectionTitle(title: 'Identificação'),
          const SizedBox(height: AppSpacing.sm),
          _InfoCard(children: [
            _InfoRow(label: 'Código', value: a.assetCode),
            _InfoRow(label: 'Descrição', value: a.description),
            if (a.categoryName != null)
              _InfoRow(label: 'Categoria', value: a.categoryName!),
            if (a.brand != null) _InfoRow(label: 'Marca', value: a.brand!),
            if (a.model != null) _InfoRow(label: 'Modelo', value: a.model!),
            if (a.serialNumber != null)
              _InfoRow(label: 'Nº Série', value: a.serialNumber!),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // Acquisition
          _SectionTitle(title: 'Aquisição'),
          const SizedBox(height: AppSpacing.sm),
          _InfoCard(children: [
            if (a.acquisitionType != null)
              _InfoRow(label: 'Tipo', value: a.acquisitionTypeLabel),
            if (a.acquisitionDate != null)
              _InfoRow(label: 'Data', value: a.acquisitionDate!),
            if (a.acquisitionValue != null)
              _InfoRow(
                  label: 'Valor',
                  value: formatCurrency(a.acquisitionValue!)),
            if (a.currentValue != null)
              _InfoRow(
                  label: 'Valor Atual',
                  value: formatCurrency(a.currentValue!)),
            if (a.residualValue != null)
              _InfoRow(
                  label: 'Valor Residual',
                  value: formatCurrency(a.residualValue!)),
          ]),
          const SizedBox(height: AppSpacing.lg),

          // Location & Condition
          _SectionTitle(title: 'Localização e Estado'),
          const SizedBox(height: AppSpacing.sm),
          _InfoCard(children: [
            if (a.location != null)
              _InfoRow(label: 'Localização', value: a.location!),
            _InfoRow(label: 'Condição', value: a.conditionLabel),
            _InfoRow(label: 'Status', value: a.statusLabel),
            if (a.statusReason != null)
              _InfoRow(label: 'Motivo', value: a.statusReason!),
          ]),

          if (a.notes != null && a.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: 'Observações'),
            const SizedBox(height: AppSpacing.sm),
            _InfoCard(children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(a.notes!, style: AppTypography.bodyMedium),
              ),
            ]),
          ],

          const SizedBox(height: AppSpacing.lg),
          // Metadata
          if (a.createdAt != null || a.updatedAt != null) ...[
            _SectionTitle(title: 'Metadados'),
            const SizedBox(height: AppSpacing.sm),
            _InfoCard(children: [
              if (a.createdAt != null)
                _InfoRow(
                  label: 'Cadastrado em',
                  value: _formatDateTime(a.createdAt!),
                ),
              if (a.updatedAt != null)
                _InfoRow(
                  label: 'Atualizado em',
                  value: _formatDateTime(a.updatedAt!),
                ),
            ]),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ativo':
        return AppColors.success;
      case 'em_manutencao':
        return AppColors.warning;
      case 'baixado':
        return AppColors.error;
      case 'cedido':
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }

  Color _conditionColor(String condition) {
    switch (condition) {
      case 'novo':
        return AppColors.success;
      case 'bom':
        return Colors.green.shade400;
      case 'regular':
        return AppColors.warning;
      case 'ruim':
        return Colors.orange;
      case 'inservivel':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: AppTypography.headingSmall
            .copyWith(fontSize: 16, fontWeight: FontWeight.w700));
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
