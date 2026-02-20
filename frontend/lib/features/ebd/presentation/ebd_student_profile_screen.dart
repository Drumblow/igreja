import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../bloc/ebd_bloc.dart';
import '../bloc/ebd_event_state.dart';
import '../data/ebd_repository.dart';
import '../data/models/ebd_models.dart';

class EbdStudentProfileScreen extends StatelessWidget {
  final String memberId;
  const EbdStudentProfileScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => EbdBloc(
        repository: EbdRepository(apiClient: apiClient),
      )..add(EbdStudentProfileLoadRequested(memberId: memberId)),
      child: _ProfileView(memberId: memberId),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final String memberId;
  const _ProfileView({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil do Aluno EBD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'Nova Anotação',
            onPressed: () => _showAddNoteDialog(context),
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
                .add(EbdStudentProfileLoadRequested(memberId: memberId));
          }
          if (state is EbdError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is EbdLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }
          if (state is EbdStudentProfileLoaded) {
            return _buildProfile(context, state);
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

  Widget _buildProfile(
      BuildContext context, EbdStudentProfileLoaded state) {
    final s = state.summary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          _ProfileHeader(summary: s),
          const SizedBox(height: AppSpacing.lg),

          // Stats cards
          _StatsSection(summary: s),
          const SizedBox(height: AppSpacing.lg),

          // Enrollment History
          Text('Histórico de Turmas',
              style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          if (state.history.isEmpty)
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Nenhum histórico disponível',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            )
          else
            ...state.history.map((h) => _HistoryCard(history: h)),
          const SizedBox(height: AppSpacing.lg),

          // Notes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Anotações do Professor',
                  style: AppTypography.headingSmall),
              TextButton.icon(
                onPressed: () => _showAddNoteDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nova'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.notes.isEmpty)
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Nenhuma anotação registrada',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            )
          else
            ...state.notes.map((n) => _NoteCard(
                  note: n,
                  memberId: memberId,
                )),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    String selectedType = 'observation';
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    bool isPrivate = false;
    final bloc = context.read<EbdBloc>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nova Anotação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de Anotação'),
                  items: const [
                    DropdownMenuItem(
                        value: 'observation', child: Text('Observação')),
                    DropdownMenuItem(
                        value: 'behavior', child: Text('Comportamento')),
                    DropdownMenuItem(
                        value: 'progress', child: Text('Progresso')),
                    DropdownMenuItem(
                        value: 'special_need',
                        child: Text('Necessidade Especial')),
                    DropdownMenuItem(
                        value: 'praise', child: Text('Elogio')),
                    DropdownMenuItem(
                        value: 'concern', child: Text('Preocupação')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? 'observation'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo *',
                    hintText: 'Descreva a observação...',
                  ),
                  maxLines: 4,
                ),
                SwitchListTile(
                  title: const Text('Nota privada'),
                  subtitle:
                      const Text('Visível apenas para você'),
                  value: isPrivate,
                  onChanged: (v) =>
                      setDialogState(() => isPrivate = v),
                  contentPadding: EdgeInsets.zero,
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
                if (titleCtrl.text.trim().isEmpty ||
                    contentCtrl.text.trim().isEmpty) return;
                bloc.add(EbdStudentNoteCreateRequested(
                  memberId: memberId,
                  data: {
                    'note_type': selectedType,
                    'title': titleCtrl.text.trim(),
                    'content': contentCtrl.text.trim(),
                    'is_private': isPrivate,
                  },
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Profile Header
// ==========================================

class _ProfileHeader extends StatelessWidget {
  final EbdStudentSummary summary;
  const _ProfileHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              backgroundImage: summary.photoUrl != null
                  ? NetworkImage(summary.photoUrl!)
                  : null,
              child: summary.photoUrl == null
                  ? Text(
                      summary.fullName.isNotEmpty
                          ? summary.fullName[0].toUpperCase()
                          : '?',
                      style: AppTypography.headingMedium
                          .copyWith(color: AppColors.accent),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.fullName,
                      style: AppTypography.headingSmall),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (summary.memberStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            summary.memberStatus!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${summary.totalEnrollments} matrículas',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Stats Section
// ==========================================

class _StatsSection extends StatelessWidget {
  final EbdStudentSummary summary;
  const _StatsSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final attendanceColor = summary.attendancePercentage >= 75
        ? AppColors.success
        : summary.attendancePercentage >= 50
            ? AppColors.warning
            : AppColors.error;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _StatCard(
          label: 'Frequência',
          value: '${summary.attendancePercentage.toStringAsFixed(0)}%',
          color: attendanceColor,
          icon: Icons.pie_chart_outline,
        ),
        _StatCard(
          label: 'Presenças',
          value: '${summary.totalPresent}',
          color: AppColors.success,
          icon: Icons.check_circle_outline,
        ),
        _StatCard(
          label: 'Ausências',
          value: '${summary.totalAbsent}',
          color: AppColors.error,
          icon: Icons.cancel_outlined,
        ),
        _StatCard(
          label: 'Bíblia',
          value: '${summary.timesBroughtBible}x',
          color: const Color(0xFF8D6E63),
          icon: Icons.book_outlined,
        ),
        _StatCard(
          label: 'Revista',
          value: '${summary.timesBroughtMagazine}x',
          color: AppColors.info,
          icon: Icons.menu_book_outlined,
        ),
        _StatCard(
          label: 'Ofertas',
          value: 'R\$ ${summary.totalOfferings.toStringAsFixed(2)}',
          color: AppColors.accent,
          icon: Icons.volunteer_activism_outlined,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        color: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  )),
              Text(label,
                  style: AppTypography.bodySmall.copyWith(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// History Card (enrollment per term)
// ==========================================

class _HistoryCard extends StatelessWidget {
  final EbdEnrollmentHistory history;
  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final attendanceColor = history.attendancePercentage >= 75
        ? AppColors.success
        : history.attendancePercentage >= 50
            ? AppColors.warning
            : AppColors.error;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(history.termName,
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(history.className,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                      if (history.teacherName != null)
                        Text('Prof: ${history.teacherName}',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: attendanceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${history.attendancePercentage.toStringAsFixed(0)}%',
                    style: AppTypography.bodyMedium.copyWith(
                      color: attendanceColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _MiniStat('P', '${history.presentCount}', AppColors.success),
                const SizedBox(width: AppSpacing.md),
                _MiniStat('A', '${history.absentCount}', AppColors.error),
                const SizedBox(width: AppSpacing.md),
                _MiniStat('J', '${history.justifiedCount}', AppColors.warning),
                const SizedBox(width: AppSpacing.md),
                _MiniStat('Aulas', '${history.totalLessons}', AppColors.info),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 3),
        Text('$label: $value',
            style: AppTypography.bodySmall
                .copyWith(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ==========================================
// Note Card (E5)
// ==========================================

class _NoteCard extends StatelessWidget {
  final EbdStudentNote note;
  final String memberId;
  const _NoteCard({required this.note, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: note.typeColor.withValues(alpha: 0.4)),
      ),
      color: note.typeColor.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: note.typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(note.typeLabel,
                      style: AppTypography.bodySmall.copyWith(
                        color: note.typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      )),
                ),
                if (note.isPrivate) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.lock, size: 12, color: AppColors.textMuted),
                ],
                const Spacer(),
                if (note.termName != null)
                  Text(note.termName!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted, fontSize: 10)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  color: AppColors.accent,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Editar',
                  onPressed: () => _showEditNoteDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: AppColors.error,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    context.read<EbdBloc>().add(EbdStudentNoteDeleteRequested(
                      memberId: memberId,
                      noteId: note.id,
                    ));
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(note.title,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Text(note.content,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            if (note.createdByName != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Por: ${note.createdByName}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted, fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context) {
    String selectedType = note.noteType;
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content);
    bool isPrivate = note.isPrivate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Anotação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'observation', child: Text('Observação')),
                    DropdownMenuItem(value: 'behavior', child: Text('Comportamento')),
                    DropdownMenuItem(value: 'progress', child: Text('Progresso')),
                    DropdownMenuItem(value: 'special_need', child: Text('Necessidade Especial')),
                    DropdownMenuItem(value: 'praise', child: Text('Elogio')),
                    DropdownMenuItem(value: 'concern', child: Text('Preocupação')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v ?? 'observation'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título *'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: 'Conteúdo *'),
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  title: const Text('Nota privada'),
                  subtitle: Text(isPrivate ? 'Visível apenas para você' : 'Visível para outros professores',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  value: isPrivate,
                  onChanged: (v) => setDialogState(() => isPrivate = v),
                  contentPadding: EdgeInsets.zero,
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
                if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
                context.read<EbdBloc>().add(EbdStudentNoteUpdateRequested(
                  memberId: memberId,
                  noteId: note.id,
                  data: {
                    'note_type': selectedType,
                    'title': titleCtrl.text.trim(),
                    'content': contentCtrl.text.trim(),
                    'is_private': isPrivate,
                  },
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
