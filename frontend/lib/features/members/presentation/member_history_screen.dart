import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/member_repository.dart';
import '../data/models/member_models.dart';

/// Screen that displays the full history timeline for a member
/// and allows registering new events.
class MemberHistoryScreen extends StatefulWidget {
  final String memberId;
  final String memberName;

  const MemberHistoryScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<MemberHistoryScreen> createState() => _MemberHistoryScreenState();
}

class _MemberHistoryScreenState extends State<MemberHistoryScreen> {
  late final MemberRepository _repo;
  List<MemberHistory>? _history;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = MemberRepository(
      apiClient: RepositoryProvider.of<ApiClient>(context),
    );
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await _repo.getMemberHistory(widget.memberId);
      if (mounted) {
        setState(() {
          _history = history;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar histórico: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _showAddEventDialog() async {
    final result = await showDialog<_NewEventData>(
      context: context,
      builder: (ctx) => _AddHistoryEventDialog(),
    );

    if (result != null && mounted) {
      try {
        await _repo.createMemberHistory(
          widget.memberId,
          eventType: result.eventType,
          eventDate: result.eventDate,
          description: result.description,
          previousValue: result.previousValue,
          newValue: result.newValue,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evento registrado com sucesso'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadHistory();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao registrar evento: $e'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Histórico'),
            Text(
              widget.memberName,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        icon: const Icon(Icons.add),
        label: const Text('Novo Evento'),
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
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final history = _history!;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhum evento registrado',
              style: AppTypography.headingSmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Use o botão abaixo para registrar o primeiro evento.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final isWide = MediaQuery.of(context).size.width >= 800;

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? AppSpacing.huge : AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final event = history[index];
          final isFirst = index == 0;
          final isLast = index == history.length - 1;

          return _TimelineItem(
            event: event,
            dateFormat: dateFormat,
            isFirst: isFirst,
            isLast: isLast,
          );
        },
      ),
    );
  }
}

// ── Timeline Item ──

class _TimelineItem extends StatelessWidget {
  final MemberHistory event;
  final DateFormat dateFormat;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.event,
    required this.dateFormat,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _iconForType(event.eventType);
    final color = _colorForType(event.eventType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + circle
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Line above
                if (!isFirst)
                  Container(width: 2, height: 12, color: AppColors.border)
                else
                  const SizedBox(height: 12),
                // Circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                // Line below
                if (!isLast) Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
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
                          Expanded(
                            child: Text(
                              event.eventTypeLabel,
                              style: AppTypography.labelLarge.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            dateFormat.format(event.eventDate),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        event.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      if (event.previousValue != null || event.newValue != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Row(
                            children: [
                              if (event.previousValue != null) ...[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Anterior',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        event.previousValue!,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.error,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (event.previousValue != null && event.newValue != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              if (event.newValue != null) ...[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Novo',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        event.newValue!,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) => switch (type) {
        'mudanca_cargo' => Icons.badge_outlined,
        'entrada_ministerio' => Icons.group_add_outlined,
        'saida_ministerio' => Icons.group_remove_outlined,
        'transferencia_entrada' => Icons.login_outlined,
        'transferencia_saida' => Icons.logout_outlined,
        'disciplina' => Icons.gavel_outlined,
        'reconciliacao' => Icons.handshake_outlined,
        'batismo_aguas' => Icons.water_drop_outlined,
        'batismo_espirito' => Icons.local_fire_department_outlined,
        'casamento' => Icons.favorite_outline,
        'falecimento' => Icons.sentiment_very_dissatisfied_outlined,
        'mudanca_status' => Icons.swap_horiz_outlined,
        'observacao' => Icons.note_outlined,
        _ => Icons.event_outlined,
      };

  Color _colorForType(String type) => switch (type) {
        'mudanca_cargo' => AppColors.accent,
        'entrada_ministerio' => AppColors.success,
        'saida_ministerio' => AppColors.error,
        'transferencia_entrada' => AppColors.info,
        'transferencia_saida' => AppColors.error,
        'disciplina' => AppColors.error,
        'reconciliacao' => AppColors.success,
        'batismo_aguas' => AppColors.info,
        'batismo_espirito' => AppColors.accent,
        'casamento' => const Color(0xFFE91E63),
        'falecimento' => AppColors.textMuted,
        'mudanca_status' => AppColors.info,
        'observacao' => AppColors.textSecondary,
        _ => AppColors.primary,
      };
}

// ── Add Event Dialog ──

class _NewEventData {
  final String eventType;
  final DateTime eventDate;
  final String description;
  final String? previousValue;
  final String? newValue;

  _NewEventData({
    required this.eventType,
    required this.eventDate,
    required this.description,
    this.previousValue,
    this.newValue,
  });
}

const _eventTypes = [
  ('mudanca_cargo', 'Mudança de Cargo'),
  ('entrada_ministerio', 'Entrada em Ministério'),
  ('saida_ministerio', 'Saída de Ministério'),
  ('transferencia_entrada', 'Transferência (Entrada)'),
  ('transferencia_saida', 'Transferência (Saída)'),
  ('disciplina', 'Disciplina Eclesiástica'),
  ('reconciliacao', 'Reconciliação'),
  ('batismo_aguas', 'Batismo nas Águas'),
  ('batismo_espirito', 'Batismo no Espírito Santo'),
  ('casamento', 'Casamento'),
  ('falecimento', 'Falecimento'),
  ('mudanca_status', 'Mudança de Status'),
  ('observacao', 'Observação'),
];

class _AddHistoryEventDialog extends StatefulWidget {
  @override
  State<_AddHistoryEventDialog> createState() => _AddHistoryEventDialogState();
}

class _AddHistoryEventDialogState extends State<_AddHistoryEventDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedType;
  DateTime _eventDate = DateTime.now();
  final _descriptionController = TextEditingController();
  final _previousValueController = TextEditingController();
  final _newValueController = TextEditingController();
  bool _showValueFields = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _previousValueController.dispose();
    _newValueController.dispose();
    super.dispose();
  }

  /// Some event types naturally have before/after values.
  bool _typeHasValues(String? type) => switch (type) {
        'mudanca_cargo' => true,
        'mudanca_status' => true,
        'transferencia_entrada' => true,
        'transferencia_saida' => true,
        _ => false,
      };

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: const Text('Registrar Evento'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event type dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Evento *',
                    border: OutlineInputBorder(),
                  ),
                  items: _eventTypes
                      .map((t) => DropdownMenuItem(
                            value: t.$1,
                            child: Text(t.$2),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                      _showValueFields = _typeHasValues(value);
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Selecione o tipo de evento' : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Date picker
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data do Evento *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(dateFormat.format(_eventDate)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição *',
                    hintText: 'Descreva o evento...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Descrição é obrigatória'
                          : null,
                ),

                // Optional value fields
                if (_showValueFields) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _previousValueController,
                    decoration: const InputDecoration(
                      labelText: 'Valor Anterior',
                      hintText: 'Ex: Membro',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _newValueController,
                    decoration: const InputDecoration(
                      labelText: 'Novo Valor',
                      hintText: 'Ex: Diácono',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                _NewEventData(
                  eventType: _selectedType!,
                  eventDate: _eventDate,
                  description: _descriptionController.text.trim(),
                  previousValue: _previousValueController.text.trim().isNotEmpty
                      ? _previousValueController.text.trim()
                      : null,
                  newValue: _newValueController.text.trim().isNotEmpty
                      ? _newValueController.text.trim()
                      : null,
                ),
              );
            }
          },
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
