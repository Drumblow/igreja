import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/ebd_repository.dart';
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
