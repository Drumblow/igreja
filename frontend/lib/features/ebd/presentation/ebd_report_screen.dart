import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../bloc/ebd_bloc.dart';
import '../bloc/ebd_event_state.dart';
import '../data/ebd_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// E6 — Advanced EBD Reports Screen
class EbdReportScreen extends StatelessWidget {
  const EbdReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final congCubit = context.read<CongregationContextCubit>();
    return BlocProvider(
      create: (context) => EbdBloc(
        repository: context.read<EbdRepository>(),
        congregationCubit: congCubit,
      )..add(EbdTermsLoadRequested(
          congregationId: congCubit.state.activeCongregationId,
        )),
      child: const _EbdReportView(),
    );
  }
}

class _EbdReportView extends StatefulWidget {
  const _EbdReportView();

  @override
  State<_EbdReportView> createState() => _EbdReportViewState();
}

class _EbdReportViewState extends State<_EbdReportView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTermId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReport(String termId) {
    setState(() => _selectedTermId = termId);
    context.read<EbdBloc>().add(EbdTermReportLoadRequested(termId: termId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios EBD'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resumo', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Ranking', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Faltosos', icon: Icon(Icons.warning_amber)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Term selector
          _buildTermSelector(),
          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SummaryTab(selectedTermId: _selectedTermId),
                _RankingTab(selectedTermId: _selectedTermId),
                _AbsentTab(onLoad: () {
                  context
                      .read<EbdBloc>()
                      .add(const EbdAbsentStudentsLoadRequested());
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermSelector() {
    return BlocBuilder<EbdBloc, EbdState>(
      buildWhen: (prev, curr) => curr is EbdTermsLoaded,
      builder: (context, state) {
        if (state is! EbdTermsLoaded) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LinearProgressIndicator(),
          );
        }
        final terms = state.terms;
        if (terms.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text('Nenhum período cadastrado'),
          );
        }

        // Auto-select first term
        if (_selectedTermId == null && terms.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadReport(terms.first.id);
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedTermId,
            decoration: const InputDecoration(
              labelText: 'Período',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: terms
                .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) _loadReport(val);
            },
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════
// Summary Tab
// ════════════════════════════════════════════════

class _SummaryTab extends StatelessWidget {
  final String? selectedTermId;
  const _SummaryTab({this.selectedTermId});

  @override
  Widget build(BuildContext context) {
    if (selectedTermId == null) {
      return const Center(child: Text('Selecione um período acima'));
    }

    return BlocBuilder<EbdBloc, EbdState>(
      buildWhen: (prev, curr) =>
          curr is EbdTermReportLoaded || curr is EbdLoading || curr is EbdError,
      builder: (context, state) {
        if (state is EbdLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is EbdError) {
          return Center(child: Text(state.message));
        }
        if (state is! EbdTermReportLoaded) {
          return const Center(child: Text('Carregando...'));
        }

        final report = state.report;
        if (report.isEmpty) {
          return const Center(child: Text('Nenhum dado disponível'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              _buildStatCards(report),
              const SizedBox(height: AppSpacing.lg),
              // Classes summary table
              Text('Resumo por Turma',
                  style: AppTypography.headingSmall
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              _buildClassesTable(report),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards(Map<String, dynamic> report) {
    final totalClasses = report['total_classes'] ?? 0;
    final totalStudents = report['total_students'] ?? 0;
    final totalLessons = report['total_lessons'] ?? 0;
    final avgAttendance = (report['average_attendance_percentage'] as num?)?.toDouble() ?? 0.0;
    final totalOfferings = (report['total_offerings'] as num?)?.toDouble() ?? 0.0;
    final biblePct = (report['bible_percentage'] as num?)?.toDouble() ?? 0.0;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _StatCard(
          icon: Icons.groups,
          label: 'Turmas',
          value: '$totalClasses',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.person,
          label: 'Alunos',
          value: '$totalStudents',
          color: AppColors.info,
        ),
        _StatCard(
          icon: Icons.menu_book,
          label: 'Aulas',
          value: '$totalLessons',
          color: AppColors.accent,
        ),
        _StatCard(
          icon: Icons.check_circle,
          label: 'Presença Média',
          value: '${avgAttendance.toStringAsFixed(1)}%',
          color: avgAttendance >= 70 ? AppColors.success : AppColors.warning,
        ),
        _StatCard(
          icon: Icons.attach_money,
          label: 'Ofertas',
          value: 'R\$ ${totalOfferings.toStringAsFixed(2)}',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.auto_stories,
          label: 'Bíblias',
          value: '${biblePct.toStringAsFixed(1)}%',
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildClassesTable(Map<String, dynamic> report) {
    final classes = (report['classes_summary'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    if (classes.isEmpty) {
      return const Text('Nenhuma turma encontrada');
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Turma')),
            DataColumn(label: Text('Professor')),
            DataColumn(label: Text('Alunos'), numeric: true),
            DataColumn(label: Text('Aulas'), numeric: true),
            DataColumn(label: Text('Presença %'), numeric: true),
            DataColumn(label: Text('Ofertas'), numeric: true),
          ],
          rows: classes.map((c) {
            final pct = (c['attendance_percentage'] as num?)?.toDouble() ?? 0.0;
            return DataRow(cells: [
              DataCell(Text(c['class_name'] ?? '')),
              DataCell(Text(c['teacher_name'] ?? '—')),
              DataCell(Text('${c['enrolled_count'] ?? 0}')),
              DataCell(Text('${c['total_lessons'] ?? 0}')),
              DataCell(Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: pct >= 70 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              )),
              DataCell(Text(
                'R\$ ${((c['total_offerings'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Ranking Tab
// ════════════════════════════════════════════════

class _RankingTab extends StatelessWidget {
  final String? selectedTermId;
  const _RankingTab({this.selectedTermId});

  @override
  Widget build(BuildContext context) {
    if (selectedTermId == null) {
      return const Center(child: Text('Selecione um período acima'));
    }

    return BlocBuilder<EbdBloc, EbdState>(
      buildWhen: (prev, curr) =>
          curr is EbdTermReportLoaded || curr is EbdLoading || curr is EbdError,
      builder: (context, state) {
        if (state is EbdLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is EbdError) {
          return Center(child: Text(state.message));
        }
        if (state is! EbdTermReportLoaded) {
          return const Center(child: Text('Carregando...'));
        }

        final ranking = state.ranking;
        if (ranking.isEmpty) {
          return const Center(child: Text('Nenhum dado para ranking'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: ranking.length,
          itemBuilder: (context, index) {
            final item = ranking[index];
            final pct =
                (item['attendance_percentage'] as num?)?.toDouble() ?? 0.0;
            final name = item['class_name'] ?? '';
            final teacher = item['teacher_name'] ?? '—';

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      index < 3 ? AppColors.accent : AppColors.divider,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          index < 3 ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                title: Text(name, style: AppTypography.bodyLarge),
                subtitle: Text('Professor: $teacher'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: AppTypography.headingSmall.copyWith(
                        color: pct >= 70 ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: AppColors.divider,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          pct >= 70 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════
// Absent Students Tab
// ════════════════════════════════════════════════

class _AbsentTab extends StatefulWidget {
  final VoidCallback onLoad;
  const _AbsentTab({required this.onLoad});

  @override
  State<_AbsentTab> createState() => _AbsentTabState();
}

class _AbsentTabState extends State<_AbsentTab> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      widget.onLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EbdBloc, EbdState>(
      buildWhen: (prev, curr) =>
          curr is EbdAbsentStudentsLoaded ||
          curr is EbdLoading ||
          curr is EbdError,
      builder: (context, state) {
        if (state is EbdLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is EbdError) {
          return Center(child: Text(state.message));
        }
        if (state is! EbdAbsentStudentsLoaded) {
          return const Center(child: Text('Carregando...'));
        }

        final students = state.students;
        if (students.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 64, color: AppColors.success),
                SizedBox(height: AppSpacing.md),
                Text('Nenhum aluno com 3+ ausências consecutivas'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final s = students[index];
            final absences = s['consecutive_absences'] ?? 0;
            final lastPresent = s['last_present_date'] ?? '—';
            final phone = s['phone_primary'];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  child: const Icon(Icons.warning, color: AppColors.error),
                ),
                title: Text(
                  s['member_name'] ?? '',
                  style: AppTypography.bodyLarge,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Turma: ${s['class_name'] ?? '—'}'),
                    Text('Ausências consecutivas: $absences'),
                    Text('Última presença: $lastPresent'),
                  ],
                ),
                isThreeLine: true,
                trailing: phone != null
                    ? IconButton(
                        icon: const Icon(Icons.phone, color: AppColors.primary),
                        tooltip: phone,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Telefone: $phone')),
                          );
                        },
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════
// Stat Card Widget
// ════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.headingMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
