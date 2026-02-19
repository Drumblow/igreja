import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/ebd_repository.dart';
import '../data/models/ebd_models.dart';
import 'ebd_event_state.dart';

class EbdBloc extends Bloc<EbdEvent, EbdState> {
  final EbdRepository repository;

  EbdBloc({required this.repository}) : super(const EbdInitial()) {
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
    // Students (E3)
    on<EbdStudentsLoadRequested>(_onStudentsLoad);
    on<EbdStudentProfileLoadRequested>(_onStudentProfileLoad);
    // Student Notes (E5)
    on<EbdStudentNoteCreateRequested>(_onStudentNoteCreate);
    on<EbdStudentNoteDeleteRequested>(_onStudentNoteDelete);
    // Attendance
    on<EbdAttendanceLoadRequested>(_onAttendanceLoad);
    on<EbdAttendanceRecordRequested>(_onAttendanceRecord);
    // Report
    on<EbdClassReportLoadRequested>(_onClassReportLoad);
  }

  // ==========================================
  // Terms
  // ==========================================

  Future<void> _onTermsLoad(EbdTermsLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final terms = await repository.getTerms();
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
    emit(const EbdLoading());
    try {
      final classes = await repository.getClasses(
        termId: event.termId,
        isActive: event.isActive,
      );
      emit(EbdClassesLoaded(classes: classes));
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
    emit(const EbdLoading());
    try {
      final lessons = await repository.getLessons(
        classId: event.classId,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
      );
      emit(EbdLessonsLoaded(lessons: lessons));
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
      await repository.getLessonActivities(event.lessonId);
      emit(EbdLessonsLoaded(lessons: const [])); // placeholder - use specific state
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

  // ==========================================
  // Students (E3)
  // ==========================================

  Future<void> _onStudentsLoad(EbdStudentsLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final students = await repository.getEbdStudents(
        termId: event.termId,
        classId: event.classId,
        search: event.search,
      );
      emit(EbdStudentsLoaded(students: students));
    } catch (e) {
      emit(EbdError(message: 'Erro ao carregar alunos: $e'));
    }
  }

  Future<void> _onStudentProfileLoad(
      EbdStudentProfileLoadRequested event, Emitter<EbdState> emit) async {
    emit(const EbdLoading());
    try {
      final students = await repository.getEbdStudents();
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
}
