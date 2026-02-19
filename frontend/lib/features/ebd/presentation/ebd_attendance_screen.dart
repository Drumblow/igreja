import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/searchable_entity_dropdown.dart';
import '../../members/data/member_repository.dart';
import '../bloc/ebd_bloc.dart';
import '../bloc/ebd_event_state.dart';
import '../data/ebd_repository.dart';
import '../data/models/ebd_models.dart';

class EbdAttendanceScreen extends StatelessWidget {
  final String lessonId;
  const EbdAttendanceScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => EbdBloc(
        repository: EbdRepository(apiClient: apiClient),
      )..add(EbdLessonDetailLoadRequested(lessonId: lessonId)),
      child: _AttendanceView(lessonId: lessonId),
    );
  }
}

class _AttendanceView extends StatefulWidget {
  final String lessonId;
  const _AttendanceView({required this.lessonId});

  @override
  State<_AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<_AttendanceView> {
  final List<_AttendanceEntry> _entries = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Frequência da Aula'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Adicionar presença manual',
            onPressed: () => _showAddEntryDialog(context),
          ),
          TextButton.icon(
            onPressed: _entries.isEmpty ? null : () => _submitAttendance(context),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Salvar'),
          ),
        ],
      ),
      body: BlocConsumer<EbdBloc, EbdState>(
        listener: (context, state) {
          if (state is EbdSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context
                .read<EbdBloc>()
                .add(EbdLessonDetailLoadRequested(lessonId: widget.lessonId));
          }
          if (state is EbdError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is EbdLessonDetailLoaded && !_initialized) {
            setState(() {
              _entries.clear();
              for (final a in state.attendance) {
                _entries.add(_AttendanceEntry(
                  memberId: a.memberId,
                  memberName: a.memberName ?? 'Membro',
                  status: a.status,
                  broughtBible: a.broughtBible ?? false,
                  broughtMagazine: a.broughtMagazine ?? false,
                  offeringAmount: a.offeringAmount,
                  isVisitor: a.isVisitor,
                  visitorName: a.visitorName,
                ));
              }
              _initialized = true;
            });
          }
        },
        builder: (context, state) {
          if (state is EbdLoading && !_initialized) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }
          if (state is EbdLessonDetailLoaded || _initialized) {
            return _buildContent(context, state);
          }
          if (state is EbdError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(state.message, style: AppTypography.bodyMedium),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, EbdState state) {
    EbdLesson? lesson;
    if (state is EbdLessonDetailLoaded) {
      lesson = state.lesson;
    }

    return Column(
      children: [
        // Lesson info header
        if (lesson != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.displayTitle, style: AppTypography.headingSmall),
                if (lesson.bibleText != null)
                  Text('Texto: ${lesson.bibleText}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                Text('Data: ${lesson.lessonDate}',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        // Summary bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          color: AppColors.accent.withValues(alpha: 0.05),
          child: Row(
            children: [
              _StatChip(
                  'Presentes',
                  _entries
                      .where((e) => e.status == 'presente')
                      .length
                      .toString(),
                  AppColors.success),
              const SizedBox(width: AppSpacing.md),
              _StatChip(
                  'Ausentes',
                  _entries
                      .where((e) => e.status == 'ausente')
                      .length
                      .toString(),
                  AppColors.error),
              const SizedBox(width: AppSpacing.md),
              _StatChip(
                  'Total', _entries.length.toString(), AppColors.info),
            ],
          ),
        ),
        // Attendance list
        Expanded(
          child: _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fact_check_outlined,
                          size: 48,
                          color:
                              AppColors.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: AppSpacing.md),
                      Text('Nenhuma presença registrada',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Adicione alunos usando o botão +',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 24,
                  ),
                  itemCount: _entries.length,
                  itemBuilder: (ctx, i) => _AttendanceTile(
                    entry: _entries[i],
                    onStatusChanged: (status) {
                      setState(() => _entries[i].status = status);
                    },
                    onBibleChanged: (v) {
                      setState(() => _entries[i].broughtBible = v);
                    },
                    onMagazineChanged: (v) {
                      setState(() => _entries[i].broughtMagazine = v);
                    },
                    onOfferingChanged: (v) {
                      _entries[i].offeringAmount = v;
                    },
                    onNotesChanged: (v) {
                      _entries[i].notes = v;
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    final memberRepo = MemberRepository(apiClient: apiClient);

    final nameCtrl = TextEditingController();
    bool isVisitor = false;
    EntityOption? selectedMember;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Adicionar Presença'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Visitante'),
                  value: isVisitor,
                  onChanged: (v) => setDialogState(() => isVisitor = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!isVisitor)
                  SearchableEntityDropdown(
                    label: 'Membro *',
                    hint: 'Busque pelo nome...',
                    onSelected: (entity) => selectedMember = entity,
                    searchCallback: (query) async {
                      final result = await memberRepo.getMembers(
                        search: query,
                        perPage: 20,
                        status: 'ativo',
                      );
                      return result.members
                          .map((m) => EntityOption(id: m.id, label: m.fullName))
                          .toList();
                    },
                  ),
                if (isVisitor)
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Visitante *',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!isVisitor && selectedMember == null) return;
                if (isVisitor && nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _entries.add(_AttendanceEntry(
                    memberId: isVisitor ? '' : selectedMember!.id,
                    memberName: isVisitor
                        ? nameCtrl.text.trim()
                        : selectedMember!.label,
                    status: 'presente',
                    isVisitor: isVisitor,
                    visitorName: isVisitor ? nameCtrl.text.trim() : null,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitAttendance(BuildContext context) {
    final attendances = _entries.map((e) {
      final record = <String, dynamic>{
        'member_id': e.memberId,
        'status': e.status,
        'brought_bible': e.broughtBible,
        'brought_magazine': e.broughtMagazine,
      };
      if (e.offeringAmount > 0) {
        record['offering_amount'] = e.offeringAmount;
      }
      if (e.notes != null && e.notes!.isNotEmpty) {
        record['notes'] = e.notes;
      }
      if (e.isVisitor) {
        record['is_visitor'] = true;
        record['visitor_name'] = e.visitorName ?? e.memberName;
      }
      return record;
    }).toList();

    context.read<EbdBloc>().add(EbdAttendanceRecordRequested(
          lessonId: widget.lessonId,
          data: {'attendances': attendances},
        ));
    setState(() => _initialized = false);
  }
}

class _AttendanceEntry {
  final String memberId;
  final String memberName;
  String status;
  bool broughtBible;
  bool broughtMagazine;
  double offeringAmount;
  String? notes;
  final bool isVisitor;
  final String? visitorName;

  _AttendanceEntry({
    required this.memberId,
    required this.memberName,
    this.status = 'presente',
    this.broughtBible = false,
    this.broughtMagazine = false,
    this.offeringAmount = 0,
    this.notes,
    this.isVisitor = false,
    this.visitorName,
  });
}

class _AttendanceTile extends StatelessWidget {
  final _AttendanceEntry entry;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onBibleChanged;
  final ValueChanged<bool> onMagazineChanged;
  final ValueChanged<double> onOfferingChanged;
  final ValueChanged<String?> onNotesChanged;

  const _AttendanceTile({
    required this.entry,
    required this.onStatusChanged,
    required this.onBibleChanged,
    required this.onMagazineChanged,
    required this.onOfferingChanged,
    required this.onNotesChanged,
  });

  Color _statusColor() {
    switch (entry.status) {
      case 'presente':
        return AppColors.success;
      case 'ausente':
        return AppColors.error;
      case 'justificado':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _statusColor().withValues(alpha: 0.15),
                  child: Icon(
                    entry.isVisitor
                        ? Icons.person_outline
                        : Icons.person,
                    size: 18,
                    color: _statusColor(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.memberName,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                      if (entry.isVisitor)
                        Text('Visitante',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.accent)),
                    ],
                  ),
                ),
                // Status selector
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'presente', label: Text('P')),
                    ButtonSegment(value: 'ausente', label: Text('A')),
                    ButtonSegment(value: 'justificado', label: Text('J')),
                  ],
                  selected: {entry.status},
                  onSelectionChanged: (s) => onStatusChanged(s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _CheckChip(
                  label: 'Bíblia',
                  icon: Icons.book_outlined,
                  value: entry.broughtBible,
                  onChanged: onBibleChanged,
                ),
                const SizedBox(width: AppSpacing.sm),
                _CheckChip(
                  label: 'Revista',
                  icon: Icons.menu_book_outlined,
                  value: entry.broughtMagazine,
                  onChanged: onMagazineChanged,
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: entry.offeringAmount > 0
                        ? entry.offeringAmount.toStringAsFixed(2)
                        : '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Oferta',
                      prefixText: 'R\$ ',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: AppTypography.bodySmall,
                    onChanged: (v) => onOfferingChanged(double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              initialValue: entry.notes,
              decoration: const InputDecoration(
                hintText: 'Observações (opcional)',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: AppTypography.bodySmall,
              onChanged: onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14,
              color: value ? AppColors.accent : AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: value,
      onSelected: onChanged,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text('$label: $value',
            style: AppTypography.bodySmall
                .copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
