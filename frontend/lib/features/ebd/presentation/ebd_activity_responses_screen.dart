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

/// E2 — Tela de respostas dos alunos para uma atividade
class EbdActivityResponsesScreen extends StatelessWidget {
  final String activityId;
  const EbdActivityResponsesScreen({super.key, required this.activityId});

  @override
  Widget build(BuildContext context) {
    final apiClient = RepositoryProvider.of<ApiClient>(context);
    return BlocProvider(
      create: (_) => EbdBloc(repository: EbdRepository(apiClient: apiClient))
        ..add(EbdActivityResponsesLoadRequested(activityId: activityId)),
      child: _ResponsesView(activityId: activityId),
    );
  }
}

class _ResponsesView extends StatefulWidget {
  final String activityId;
  const _ResponsesView({required this.activityId});

  @override
  State<_ResponsesView> createState() => _ResponsesViewState();
}

class _ResponsesViewState extends State<_ResponsesView> {
  final Map<String, _ResponseEntry> _entries = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Respostas dos Alunos'),
        actions: [
          TextButton.icon(
            onPressed: _submitResponses,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: BlocConsumer<EbdBloc, EbdState>(
        listener: (context, state) {
          if (state is EbdSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<EbdBloc>().add(
                  EbdActivityResponsesLoadRequested(
                      activityId: widget.activityId),
                );
          }
          if (state is EbdError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is EbdLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EbdActivityResponsesLoaded) {
            // Initialize entries from existing responses
            for (final r in state.responses) {
              _entries.putIfAbsent(
                r.memberId,
                () => _ResponseEntry(
                  memberId: r.memberId,
                  memberName: r.memberName ?? 'Aluno',
                  responseText: r.responseText ?? '',
                  isCompleted: r.isCompleted,
                  score: r.score,
                  teacherFeedback: r.teacherFeedback ?? '',
                ),
              );
            }

            final entries = _entries.values.toList();

            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 48,
                        color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: AppSpacing.md),
                    Text('Nenhuma resposta registrada',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                        'As respostas aparecerão quando alunos forem registrados',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: entries.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                final entry = entries[i];
                return _ResponseCard(
                  entry: entry,
                  onCompletedChanged: (v) =>
                      setState(() => entry.isCompleted = v),
                  onScoreChanged: (v) => setState(() => entry.score = v),
                  onResponseChanged: (v) =>
                      setState(() => entry.responseText = v),
                  onFeedbackChanged: (v) =>
                      setState(() => entry.teacherFeedback = v),
                );
              },
            );
          }
          if (state is EbdError) {
            return Center(
                child: Text(state.message, style: AppTypography.bodyMedium));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _submitResponses() {
    final responses = _entries.values.map((e) {
      final r = <String, dynamic>{
        'member_id': e.memberId,
        'is_completed': e.isCompleted,
      };
      if (e.responseText.isNotEmpty) r['response_text'] = e.responseText;
      if (e.score != null) r['score'] = e.score;
      if (e.teacherFeedback.isNotEmpty) {
        r['teacher_feedback'] = e.teacherFeedback;
      }
      return r;
    }).toList();

    context.read<EbdBloc>().add(EbdActivityResponsesRecordRequested(
          activityId: widget.activityId,
          responses: responses,
        ));
  }
}

class _ResponseEntry {
  final String memberId;
  final String memberName;
  String responseText;
  bool isCompleted;
  int? score;
  String teacherFeedback;

  _ResponseEntry({
    required this.memberId,
    required this.memberName,
    this.responseText = '',
    this.isCompleted = false,
    this.score,
    this.teacherFeedback = '',
  });
}

class _ResponseCard extends StatelessWidget {
  final _ResponseEntry entry;
  final ValueChanged<bool> onCompletedChanged;
  final ValueChanged<int?> onScoreChanged;
  final ValueChanged<String> onResponseChanged;
  final ValueChanged<String> onFeedbackChanged;

  const _ResponseCard({
    required this.entry,
    required this.onCompletedChanged,
    required this.onScoreChanged,
    required this.onResponseChanged,
    required this.onFeedbackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: entry.isCompleted
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + completed checkbox
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  child: Text(
                    entry.memberName.isNotEmpty
                        ? entry.memberName[0].toUpperCase()
                        : '?',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(entry.memberName,
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                Checkbox(
                  value: entry.isCompleted,
                  onChanged: (v) => onCompletedChanged(v ?? false),
                  activeColor: AppColors.success,
                ),
                Text('Concluiu',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Response text
            TextFormField(
              initialValue: entry.responseText,
              decoration: const InputDecoration(
                labelText: 'Resposta',
                hintText: 'Resposta do aluno (opcional)',
                isDense: true,
              ),
              maxLines: 2,
              onChanged: onResponseChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            // Score + Feedback row
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: entry.score?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Nota',
                      hintText: '0-10',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed >= 0 && parsed <= 10) {
                        onScoreChanged(parsed);
                      } else if (v.isEmpty) {
                        onScoreChanged(null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.teacherFeedback,
                    decoration: const InputDecoration(
                      labelText: 'Feedback do Professor',
                      hintText: 'Comentário (opcional)',
                      isDense: true,
                    ),
                    onChanged: onFeedbackChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
