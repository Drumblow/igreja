import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../data/ebd_repository.dart';
import '../data/models/ebd_models.dart';
import 'ebd_event_state.dart';

class EbdBloc extends Bloc<EbdEvent, EbdState> {
  final EbdRepository repository;
  final CongregationContextCubit _congregationCubit;
  late final StreamSubscription<CongregationContextState> _congSub;

  EbdBloc({
    required this.repository,
    required CongregationContextCubit congregationCubit,
  })  : _congregationCubit = congregationCubit,
        super(const EbdInitial()) {
    // Terms
    on<EbdTermsLoadRequested>(_onTermsLoad);
    on<EbdTermCreateRequested>(_onTermCreate);
    on<EbdTermUpdateRequested>(_onTermUpdate);
    // Classes
    on<EbdClassesLoadRequested>(_onClassesLoad);
    on<EbdClassDetailLoadRequested>(_onClassDetailLoad);
    on<EbdClassCreateRequested>(_onClassCreate);
    on<EbdClassUpdateRequested>(_onClassUpdate);
    // Enrollments
    on<EbdEnrollmentsLoadRequested>(_onEnrollmentsLoad);
    on<EbdEnrollMemberRequested>(_onEnrollMember);
    on<EbdRemoveEnrollmentRequested>(_onRemoveEnrollment);
    // Lessons
    on<EbdLessonsLoadRequested>(_onLessonsLoad);
    on<EbdLessonDetailLoadRequested>(_onLessonDetailLoad);
    on<EbdLessonCreateRequested>(_onLessonCreate);
    on<EbdLessonUpdateRequested>(_onLessonUpdate);
    on<EbdLessonDeleteRequested>(_onLessonDelete);
    // Lesson Contents (E1)
    on<EbdLessonContentsLoadRequested>(_onLessonContentsLoad);
    on<EbdLessonContentCreateRequested>(_onLessonContentCreate);
    on<EbdLessonContentUpdateRequested>(_onLessonContentUpdate);
    on<EbdLessonContentDeleteRequested>(_onLessonContentDelete);
    // Lesson Activities (E2)
    on<EbdLessonActivitiesLoadRequested>(_onLessonActivitiesLoad);
    on<EbdLessonActivityCreateRequested>(_onLessonActivityCreate);
    on<EbdLessonActivityDeleteRequested>(_onLessonActivityDelete);
    on<EbdLessonActivityUpdateRequested>(_onLessonActivityUpdate);
    // Activity Responses (E2)
    on<EbdActivityResponsesLoadRequested>(_onActivityResponsesLoad);
    on<EbdActivityResponsesRecordRequested>(_onActivityResponsesRecord);
    // Students (E3)
    on<EbdStudentsLoadRequested>(_onStudentsLoad);
    on<EbdStudentProfileLoadRequested>(_onStudentProfileLoad);
    // Student Notes (E5)
    on<EbdStudentNoteCreateRequested>(_onStudentNoteCreate);
    on<EbdStudentNoteDeleteRequested>(_onStudentNoteDelete);
    on<EbdStudentNoteUpdateRequested>(_onStudentNoteUpdate);
    // Clone (E7)
    on<EbdCloneClassesRequested>(_onCloneClasses);
    // Delete terms/classes (F1.10)
    on<EbdTermDeleteRequested>(_onTermDelete);
    on<EbdClassDeleteRequested>(_onClassDelete);
    // Attendance
    on<EbdAttendanceLoadRequested>(_onAttendanceLoad);
    on<EbdAttendanceRecordRequested>(_onAttendanceRecord);
    // Report
    on<EbdClassReportLoadRequested>(_onClassReportLoad);
    // Reports (E6)
    on<EbdTermReportLoadRequested>(_onTermReportLoad);
    on<EbdTermRankingLoadRequested>(_onTermRankingLoad);
    on<EbdAbsentStudentsLoadRequested>(_onAbsentStudentsLoad);

    // Re-load terms/classes when active congregation changes
    _congSub = _congregationCubit.stream.listen((congState) {
      if (state is EbdTermsLoaded) {
        add(EbdTermsLoadRequested(
          congregationId: congState.activeCongregationId,
        ));
      } else if (state is EbdClassesLoaded) {
        add(EbdClassesLoadRequested(
          congregationId: congState.activeCongregationId,
        ));
      }
    });
  }

  String? get _activeCongregationId =>
      _congregationCubit.state.activeCongregationId;

  @override
  Future<void> close() {
    _congSub.cancel();
    return super.close();
  }

  // ==========================================
  // Terms
  // ==========================================

  Future<void> _onTermsLoad(EbdTermsLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final congregationId = event.congregationId ?? _activeCongregationId;
      final terms = await repository.getTerms(congregationId: congregationId);
      emit(EbdTermsLoaded(terms: terms));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar trimestres: $e'));
    }
  }

  Future<void> _onTermCreate(EbdTermCreateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.createTerm(event.data);
      emit(const EbdSaved(message: 'Trimestre criado com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao criar trimestre: $e'));
    }
  }

  Future<void> _onTermUpdate(EbdTermUpdateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.updateTerm(event.termId, event.data);
      emit(const EbdSaved(message: 'Trimestre atualizado com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao atualizar trimestre: $e'));
    }
  }

  // ==========================================
  // Classes
  // ==========================================

  Future<void> _onClassesLoad(EbdClassesLoadRequested event, Emitter<EbdState> emit) async {
    final isLoadMore = event.page > 1;
    if (!isLoadMore) emit(const EbdLoading());
    try {
      final congregationId = event.congregationId ?? _activeCongregationId;
      final (newClasses, meta) = await repository.getClasses(
        termId: event.termId,
        isActive: event.isActive,
        congregationId: congregationId,
        page: event.page,
      );
      final existing = isLoadMore && state is EbdClassesLoaded
          ? (state as EbdClassesLoaded).classes
          : <EbdClassSummary>[];
      emit(EbdClassesLoaded(
        classes: [...existing, ...newClasses],
        currentPage: meta.page,
        hasMore: meta.hasMore,
      ));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar turmas: $e'));
    }
  }

  Future<void> _onClassDetailLoad(
      EbdClassDetailLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final ebdClass = await repository.getClass(event.classId);
      final enrollments = await repository.getClassEnrollments(event.classId);
      emit(EbdClassDetailLoaded(ebdClass: ebdClass, enrollments: enrollments));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar detalhes da turma: $e'));
    }
  }

  Future<void> _onClassCreate(EbdClassCreateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.createClass(event.data);
      emit(const EbdSaved(message: 'Turma criada com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao criar turma: $e'));
    }
  }

  Future<void> _onClassUpdate(EbdClassUpdateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.updateClass(event.classId, event.data);
      emit(const EbdSaved(message: 'Turma atualizada com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao atualizar turma: $e'));
    }
  }

  // ==========================================
  // Enrollments
  // ==========================================

  Future<void> _onEnrollmentsLoad(
      EbdEnrollmentsLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final ebdClass = await repository.getClass(event.classId);
      final enrollments = await repository.getClassEnrollments(event.classId);
      emit(EbdClassDetailLoaded(ebdClass: ebdClass, enrollments: enrollments));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar matrículas: $e'));
    }
  }

  Future<void> _onEnrollMember(EbdEnrollMemberRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.enrollMember(event.classId, event.data);
      emit(const EbdSaved(message: 'Aluno matriculado com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao matricular aluno: $e'));
    }
  }

  Future<void> _onRemoveEnrollment(
      EbdRemoveEnrollmentRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.removeEnrollment(event.classId, event.enrollmentId);
      emit(const EbdSaved(message: 'Matrícula removida com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao remover matrícula: $e'));
    }
  }

  // ==========================================
  // Lessons
  // ==========================================

  Future<void> _onLessonsLoad(EbdLessonsLoadRequested event, Emitter<EbdState> emit) async {
    final isLoadMore = event.page > 1;
    if (!isLoadMore) emit(const EbdLoading());
    try {
      final (newLessons, meta) = await repository.getLessons(
        classId: event.classId,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
        page: event.page,
      );
      final existing = isLoadMore && state is EbdLessonsLoaded
          ? (state as EbdLessonsLoaded).lessons
          : <EbdLessonSummary>[];
      emit(EbdLessonsLoaded(
        lessons: [...existing, ...newLessons],
        currentPage: meta.page,
        hasMore: meta.hasMore,
      ));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar aulas: $e'));
    }
  }

  Future<void> _onLessonDetailLoad(
      EbdLessonDetailLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final lesson = await repository.getLesson(event.lessonId);
      final attendance = await repository.getLessonAttendance(event.lessonId);
      emit(EbdLessonDetailLoaded(lesson: lesson, attendance: attendance));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar detalhes da aula: $e'));
    }
  }

  Future<void> _onLessonCreate(EbdLessonCreateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.createLesson(event.data);
      emit(const EbdSaved(message: 'Aula registrada com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao registrar aula: $e'));
    }
  }

  Future<void> _onLessonUpdate(EbdLessonUpdateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.updateLesson(event.lessonId, event.data);
      emit(const EbdSaved(message: 'Aula atualizada com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao atualizar aula: $e'));
    }
  }

  Future<void> _onLessonDelete(EbdLessonDeleteRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.deleteLesson(event.lessonId, force: event.force);
      emit(const EbdSaved(message: 'Aula excluída com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao excluir aula: $e'));
    }
  }

  // ==========================================
  // Lesson Contents (E1)
  // ==========================================

  Future<void> _onLessonContentsLoad(
      EbdLessonContentsLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final lesson = await repository.getLesson(event.lessonId);
      final contents = await repository.getLessonContents(event.lessonId);
      final activities = await repository.getLessonActivities(event.lessonId);
      final materials = await repository.getLessonMaterials(event.lessonId);
      final attendance = await repository.getLessonAttendance(event.lessonId);
      emit(EbdLessonFullLoaded(
        lesson: lesson,
        contents: contents,
        activities: activities,
        materials: materials,
        attendance: attendance,
      ));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar conteúdo da aula: $e'));
    }
  }

  Future<void> _onLessonContentCreate(
      EbdLessonContentCreateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.createLessonContent(event.lessonId, event.data);
      emit(const EbdSaved(message: 'Conteúdo adicionado com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao adicionar conteúdo: $e'));
    }
  }

  Future<void> _onLessonContentUpdate(
      EbdLessonContentUpdateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.updateLessonContent(event.lessonId, event.contentId, event.data);
      emit(const EbdSaved(message: 'Conteúdo atualizado com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao atualizar conteúdo: $e'));
    }
  }

  Future<void> _onLessonContentDelete(
      EbdLessonContentDeleteRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.deleteLessonContent(event.lessonId, event.contentId);
      emit(const EbdSaved(message: 'Conteúdo removido com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao remover conteúdo: $e'));
    }
  }

  // ==========================================
  // Lesson Activities (E2)
  // ==========================================

  Future<void> _onLessonActivitiesLoad(
      EbdLessonActivitiesLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final lesson = await repository.getLesson(event.lessonId);
      final contents = await repository.getLessonContents(event.lessonId);
      final activities = await repository.getLessonActivities(event.lessonId);
      final materials = await repository.getLessonMaterials(event.lessonId);
      final attendance = await repository.getLessonAttendance(event.lessonId);
      emit(EbdLessonFullLoaded(
        lesson: lesson,
        contents: contents,
        activities: activities,
        materials: materials,
        attendance: attendance,
      ));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar atividades: $e'));
    }
  }

  Future<void> _onLessonActivityCreate(
      EbdLessonActivityCreateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.createLessonActivity(event.lessonId, event.data);
      emit(const EbdSaved(message: 'Atividade criada com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao criar atividade: $e'));
    }
  }

  Future<void> _onLessonActivityDelete(
      EbdLessonActivityDeleteRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.deleteLessonActivity(event.lessonId, event.activityId);
      emit(const EbdSaved(message: 'Atividade removida com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao remover atividade: $e'));
    }
  }

  Future<void> _onLessonActivityUpdate(
      EbdLessonActivityUpdateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.updateLessonActivity(event.lessonId, event.activityId, event.data);
      emit(const EbdSaved(message: 'Atividade atualizada com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao atualizar atividade: $e'));
    }
  }

  // ==========================================
  // Activity Responses (E2)
  // ==========================================

  Future<void> _onActivityResponsesLoad(
      EbdActivityResponsesLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final responses = await repository.getActivityResponses(event.activityId);
      emit(EbdActivityResponsesLoaded(activityId: event.activityId, responses: responses));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar respostas: $e'));
    }
  }

  Future<void> _onActivityResponsesRecord(
      EbdActivityResponsesRecordRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.recordActivityResponses(event.activityId, {'responses': event.responses});
      emit(const EbdSaved(message: 'Respostas registradas com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao registrar respostas: $e'));
    }
  }

  // ==========================================
  // Students (E3)
  // ==========================================

  Future<void> _onStudentsLoad(EbdStudentsLoadRequested event, Emitter<EbdState> emit) async {
    final isLoadMore = event.page > 1;
    if (!isLoadMore) emit(const EbdLoading());
    try {
      final (newStudents, meta) = await repository.getEbdStudents(
        termId: event.termId,
        classId: event.classId,
        search: event.search,
        page: event.page,
      );
      final existing = isLoadMore && state is EbdStudentsLoaded
          ? (state as EbdStudentsLoaded).students
          : <EbdStudentSummary>[];
      emit(EbdStudentsLoaded(
        students: [...existing, ...newStudents],
        currentPage: meta.page,
        hasMore: meta.hasMore,
      ));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar alunos: $e'));
    }
  }

  Future<void> _onStudentProfileLoad(
      EbdStudentProfileLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final (students, _) = await repository.getEbdStudents();
      final summary = students.firstWhere(
        (s) => s.memberId == event.memberId,
        orElse: () => EbdStudentSummary(memberId: event.memberId, fullName: 'Aluno'),
      );
      final history = await repository.getStudentHistory(event.memberId);
      final notes = await repository.getStudentNotes(event.memberId);
      emit(EbdStudentProfileLoaded(
        summary: summary,
        history: history,
        notes: notes,
      ));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar perfil do aluno: $e'));
    }
  }

  // ==========================================
  // Student Notes (E5)
  // ==========================================

  Future<void> _onStudentNoteCreate(
      EbdStudentNoteCreateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.createStudentNote(event.memberId, event.data);
      emit(const EbdSaved(message: 'Anotação criada com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao criar anotação: $e'));
    }
  }

  Future<void> _onStudentNoteDelete(
      EbdStudentNoteDeleteRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.deleteStudentNote(event.memberId, event.noteId);
      emit(const EbdSaved(message: 'Anotação removida com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao remover anotação: $e'));
    }
  }

  Future<void> _onStudentNoteUpdate(
      EbdStudentNoteUpdateRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.updateStudentNote(event.memberId, event.noteId, event.data);
      emit(const EbdSaved(message: 'Anotação atualizada com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao atualizar anotação: $e'));
    }
  }

  // ==========================================
  // Clone Classes (E7)
  // ==========================================

  Future<void> _onCloneClasses(
      EbdCloneClassesRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.cloneClasses(event.termId, {
        'source_term_id': event.sourceTermId,
        'include_enrollments': event.includeEnrollments,
      });
      emit(const EbdSaved(message: 'Turmas clonadas com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao clonar turmas: $e'));
    }
  }

  // ==========================================
  // Delete Terms/Classes (F1.10)
  // ==========================================

  Future<void> _onTermDelete(
      EbdTermDeleteRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.deleteTerm(event.termId);
      emit(const EbdSaved(message: 'Trimestre excluído com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao excluir trimestre: $e'));
    }
  }

  Future<void> _onClassDelete(
      EbdClassDeleteRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.deleteClass(event.classId);
      emit(const EbdSaved(message: 'Turma excluída com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao excluir turma: $e'));
    }
  }

  // ==========================================
  // Attendance
  // ==========================================

  Future<void> _onAttendanceLoad(
      EbdAttendanceLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final attendance = await repository.getLessonAttendance(event.lessonId);
      emit(EbdAttendanceLoaded(attendance: attendance));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar frequência: $e'));
    }
  }

  Future<void> _onAttendanceRecord(
      EbdAttendanceRecordRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      await repository.recordAttendance(event.lessonId, event.data);
      emit(const EbdSaved(message: 'Frequência registrada com sucesso'));
    } catch (e) {
      emit(EbdError(message: 'Erro ao registrar frequência: $e'));
    }
  }

  // ==========================================
  // Report
  // ==========================================

  Future<void> _onClassReportLoad(
      EbdClassReportLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final report = await repository.getClassReport(
        event.classId,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
      );
      emit(EbdClassReportLoaded(report: report));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar relatório: $e'));
    }
  }

  // ==========================================
  // Reports (E6)
  // ==========================================

  Future<void> _onTermReportLoad(
      EbdTermReportLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final results = await Future.wait([
        repository.getTermReport(event.termId),
        repository.getTermRanking(event.termId),
      ]);
      emit(EbdTermReportLoaded(
        report: results[0] as Map<String, dynamic>,
        ranking: results[1] as List<Map<String, dynamic>>,
      ));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar relatório do período: $e'));
    }
  }

  Future<void> _onTermRankingLoad(
      EbdTermRankingLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final ranking = await repository.getTermRanking(event.termId);
      emit(EbdTermReportLoaded(report: const {}, ranking: ranking));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar ranking: $e'));
    }
  }

  Future<void> _onAbsentStudentsLoad(
      EbdAbsentStudentsLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final students = await repository.getAbsentStudents();
      emit(EbdAbsentStudentsLoaded(students: students));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar alunos faltosos: $e'));
    }
  }
}
