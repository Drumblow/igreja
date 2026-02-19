import 'package:equatable/equatable.dart';
import '../data/models/ebd_models.dart';

// ══════════════════════════════════════════
// Events
// ══════════════════════════════════════════

abstract class EbdEvent extends Equatable {
  const EbdEvent();
  @override
  List<Object?> get props => [];
}

// ---- Terms ----

class EbdTermsLoadRequested extends EbdEvent {
  const EbdTermsLoadRequested();
}

class EbdTermCreateRequested extends EbdEvent {
  final Map<String, dynamic> data;
  const EbdTermCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

class EbdTermUpdateRequested extends EbdEvent {
  final String termId;
  final Map<String, dynamic> data;
  const EbdTermUpdateRequested({required this.termId, required this.data});
  @override
  List<Object?> get props => [termId, data];
}

// ---- Classes ----

class EbdClassesLoadRequested extends EbdEvent {
  final String? termId;
  final bool? isActive;
  const EbdClassesLoadRequested({this.termId, this.isActive});
  @override
  List<Object?> get props => [termId, isActive];
}

class EbdClassDetailLoadRequested extends EbdEvent {
  final String classId;
  const EbdClassDetailLoadRequested({required this.classId});
  @override
  List<Object?> get props => [classId];
}

class EbdClassCreateRequested extends EbdEvent {
  final Map<String, dynamic> data;
  const EbdClassCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

class EbdClassUpdateRequested extends EbdEvent {
  final String classId;
  final Map<String, dynamic> data;
  const EbdClassUpdateRequested({required this.classId, required this.data});
  @override
  List<Object?> get props => [classId, data];
}

// ---- Enrollments ----

class EbdEnrollmentsLoadRequested extends EbdEvent {
  final String classId;
  const EbdEnrollmentsLoadRequested({required this.classId});
  @override
  List<Object?> get props => [classId];
}

class EbdEnrollMemberRequested extends EbdEvent {
  final String classId;
  final Map<String, dynamic> data;
  const EbdEnrollMemberRequested({required this.classId, required this.data});
  @override
  List<Object?> get props => [classId, data];
}

class EbdRemoveEnrollmentRequested extends EbdEvent {
  final String classId;
  final String enrollmentId;
  const EbdRemoveEnrollmentRequested({required this.classId, required this.enrollmentId});
  @override
  List<Object?> get props => [classId, enrollmentId];
}

// ---- Lessons ----

class EbdLessonsLoadRequested extends EbdEvent {
  final String? classId;
  final String? dateFrom;
  final String? dateTo;
  const EbdLessonsLoadRequested({this.classId, this.dateFrom, this.dateTo});
  @override
  List<Object?> get props => [classId, dateFrom, dateTo];
}

class EbdLessonDetailLoadRequested extends EbdEvent {
  final String lessonId;
  const EbdLessonDetailLoadRequested({required this.lessonId});
  @override
  List<Object?> get props => [lessonId];
}

class EbdLessonCreateRequested extends EbdEvent {
  final Map<String, dynamic> data;
  const EbdLessonCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

// ---- Attendance ----

class EbdAttendanceLoadRequested extends EbdEvent {
  final String lessonId;
  const EbdAttendanceLoadRequested({required this.lessonId});
  @override
  List<Object?> get props => [lessonId];
}

class EbdAttendanceRecordRequested extends EbdEvent {
  final String lessonId;
  final Map<String, dynamic> data;
  const EbdAttendanceRecordRequested({required this.lessonId, required this.data});
  @override
  List<Object?> get props => [lessonId, data];
}

// ---- Report ----

class EbdClassReportLoadRequested extends EbdEvent {
  final String classId;
  final String? dateFrom;
  final String? dateTo;
  const EbdClassReportLoadRequested({required this.classId, this.dateFrom, this.dateTo});
  @override
  List<Object?> get props => [classId, dateFrom, dateTo];
}

// ══════════════════════════════════════════
// States
// ══════════════════════════════════════════

abstract class EbdState extends Equatable {
  const EbdState();
  @override
  List<Object?> get props => [];
}

class EbdInitial extends EbdState {
  const EbdInitial();
}

class EbdLoading extends EbdState {
  const EbdLoading();
}

class EbdTermsLoaded extends EbdState {
  final List<EbdTerm> terms;
  const EbdTermsLoaded({required this.terms});
  @override
  List<Object?> get props => [terms];
}

class EbdClassesLoaded extends EbdState {
  final List<EbdClassSummary> classes;
  const EbdClassesLoaded({required this.classes});
  @override
  List<Object?> get props => [classes];
}

class EbdClassDetailLoaded extends EbdState {
  final EbdClass ebdClass;
  final List<EbdEnrollmentDetail> enrollments;
  const EbdClassDetailLoaded({required this.ebdClass, required this.enrollments});
  @override
  List<Object?> get props => [ebdClass, enrollments];
}

class EbdLessonsLoaded extends EbdState {
  final List<EbdLessonSummary> lessons;
  const EbdLessonsLoaded({required this.lessons});
  @override
  List<Object?> get props => [lessons];
}

class EbdLessonDetailLoaded extends EbdState {
  final EbdLesson lesson;
  final List<EbdAttendanceDetail> attendance;
  const EbdLessonDetailLoaded({required this.lesson, required this.attendance});
  @override
  List<Object?> get props => [lesson, attendance];
}

class EbdAttendanceLoaded extends EbdState {
  final List<EbdAttendanceDetail> attendance;
  const EbdAttendanceLoaded({required this.attendance});
  @override
  List<Object?> get props => [attendance];
}

class EbdClassReportLoaded extends EbdState {
  final Map<String, dynamic> report;
  const EbdClassReportLoaded({required this.report});
  @override
  List<Object?> get props => [report];
}

class EbdSaved extends EbdState {
  final String message;
  const EbdSaved({required this.message});
  @override
  List<Object?> get props => [message];
}

class EbdError extends EbdState {
  final String message;
  const EbdError({required this.message});
  @override
  List<Object?> get props => [message];
}
