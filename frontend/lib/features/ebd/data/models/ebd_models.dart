import 'package:equatable/equatable.dart';

// ==========================================
// Helper parsers
// ==========================================

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

double _parseDecimal(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

// ==========================================
// EBD Term (Trimestre/Período)
// ==========================================

class EbdTerm extends Equatable {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final String? theme;
  final String? magazineTitle;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EbdTerm({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.theme,
    this.magazineTitle,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory EbdTerm.fromJson(Map<String, dynamic> json) {
    return EbdTerm(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      theme: json['theme'] as String?,
      magazineTitle: json['magazine_title'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  String get statusLabel => isActive ? 'Ativo' : 'Encerrado';

  @override
  List<Object?> get props => [id, name, startDate, endDate, isActive];
}

// ==========================================
// EBD Class (Turma)
// ==========================================

class EbdClass extends Equatable {
  final String id;
  final String termId;
  final String name;
  final int? ageRangeStart;
  final int? ageRangeEnd;
  final String? room;
  final int? maxCapacity;
  final String? teacherId;
  final String? auxTeacherId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EbdClass({
    required this.id,
    required this.termId,
    required this.name,
    this.ageRangeStart,
    this.ageRangeEnd,
    this.room,
    this.maxCapacity,
    this.teacherId,
    this.auxTeacherId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory EbdClass.fromJson(Map<String, dynamic> json) {
    return EbdClass(
      id: json['id'] as String,
      termId: json['term_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ageRangeStart: json['age_range_start'] as int?,
      ageRangeEnd: json['age_range_end'] as int?,
      room: json['room'] as String?,
      maxCapacity: json['max_capacity'] as int?,
      teacherId: json['teacher_id'] as String?,
      auxTeacherId: json['aux_teacher_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  String get ageRangeLabel {
    if (ageRangeStart == null && ageRangeEnd == null) return 'Todas as idades';
    if (ageRangeStart != null && ageRangeEnd != null) {
      return '$ageRangeStart–$ageRangeEnd anos';
    }
    if (ageRangeStart != null) return 'A partir de $ageRangeStart anos';
    return 'Até $ageRangeEnd anos';
  }

  @override
  List<Object?> get props => [id, termId, name, isActive];
}

// ==========================================
// EBD Class Summary (lista com contadores)
// ==========================================

class EbdClassSummary extends Equatable {
  final String id;
  final String termId;
  final String name;
  final int? ageRangeStart;
  final int? ageRangeEnd;
  final String? room;
  final int? maxCapacity;
  final String? teacherName;
  final bool isActive;
  final int enrolledCount;
  final DateTime? createdAt;

  const EbdClassSummary({
    required this.id,
    required this.termId,
    required this.name,
    this.ageRangeStart,
    this.ageRangeEnd,
    this.room,
    this.maxCapacity,
    this.teacherName,
    this.isActive = true,
    this.enrolledCount = 0,
    this.createdAt,
  });

  factory EbdClassSummary.fromJson(Map<String, dynamic> json) {
    return EbdClassSummary(
      id: json['id'] as String,
      termId: json['term_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ageRangeStart: json['age_range_start'] as int?,
      ageRangeEnd: json['age_range_end'] as int?,
      room: json['room'] as String?,
      maxCapacity: json['max_capacity'] as int?,
      teacherName: json['teacher_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      enrolledCount: json['enrolled_count'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
    );
  }

  String get ageRangeLabel {
    if (ageRangeStart == null && ageRangeEnd == null) return 'Todas as idades';
    if (ageRangeStart != null && ageRangeEnd != null) {
      return '$ageRangeStart–$ageRangeEnd anos';
    }
    if (ageRangeStart != null) return 'A partir de $ageRangeStart anos';
    return 'Até $ageRangeEnd anos';
  }

  @override
  List<Object?> get props => [id, termId, name, enrolledCount];
}

// ==========================================
// EBD Enrollment (Matrícula)
// ==========================================

class EbdEnrollment extends Equatable {
  final String id;
  final String classId;
  final String memberId;
  final String enrolledAt;
  final String? leftAt;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;

  const EbdEnrollment({
    required this.id,
    required this.classId,
    required this.memberId,
    required this.enrolledAt,
    this.leftAt,
    this.isActive = true,
    this.notes,
    this.createdAt,
  });

  factory EbdEnrollment.fromJson(Map<String, dynamic> json) {
    return EbdEnrollment(
      id: json['id'] as String,
      classId: json['class_id'] as String? ?? '',
      memberId: json['member_id'] as String? ?? '',
      enrolledAt: json['enrolled_at'] as String? ?? '',
      leftAt: json['left_at'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, classId, memberId, isActive];
}

// ==========================================
// EBD Enrollment Detail (com nome do membro)
// ==========================================

class EbdEnrollmentDetail extends Equatable {
  final String id;
  final String classId;
  final String memberId;
  final String? memberName;
  final String enrolledAt;
  final String? leftAt;
  final bool isActive;

  const EbdEnrollmentDetail({
    required this.id,
    required this.classId,
    required this.memberId,
    this.memberName,
    required this.enrolledAt,
    this.leftAt,
    this.isActive = true,
  });

  factory EbdEnrollmentDetail.fromJson(Map<String, dynamic> json) {
    return EbdEnrollmentDetail(
      id: json['id'] as String,
      classId: json['class_id'] as String? ?? '',
      memberId: json['member_id'] as String? ?? '',
      memberName: json['member_name'] as String?,
      enrolledAt: json['enrolled_at'] as String? ?? '',
      leftAt: json['left_at'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, classId, memberId, isActive];
}

// ==========================================
// EBD Lesson (Aula)
// ==========================================

class EbdLesson extends Equatable {
  final String id;
  final String classId;
  final String lessonDate;
  final int? lessonNumber;
  final String? title;
  final String? theme;
  final String? bibleText;
  final String? summary;
  final String? teacherId;
  final String? materialsUsed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EbdLesson({
    required this.id,
    required this.classId,
    required this.lessonDate,
    this.lessonNumber,
    this.title,
    this.theme,
    this.bibleText,
    this.summary,
    this.teacherId,
    this.materialsUsed,
    this.createdAt,
    this.updatedAt,
  });

  factory EbdLesson.fromJson(Map<String, dynamic> json) {
    return EbdLesson(
      id: json['id'] as String,
      classId: json['class_id'] as String? ?? '',
      lessonDate: json['lesson_date'] as String? ?? '',
      lessonNumber: json['lesson_number'] as int?,
      title: json['title'] as String?,
      theme: json['theme'] as String?,
      bibleText: json['bible_text'] as String?,
      summary: json['summary'] as String?,
      teacherId: json['teacher_id'] as String?,
      materialsUsed: json['materials_used'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  String get displayTitle => title ?? 'Aula ${lessonNumber ?? ""}';

  @override
  List<Object?> get props => [id, classId, lessonDate, lessonNumber];
}

// ==========================================
// EBD Lesson Summary (lista com contadores)
// ==========================================

class EbdLessonSummary extends Equatable {
  final String id;
  final String classId;
  final String? className;
  final String lessonDate;
  final int? lessonNumber;
  final String? title;
  final String? teacherName;
  final int attendanceCount;
  final DateTime? createdAt;

  const EbdLessonSummary({
    required this.id,
    required this.classId,
    this.className,
    required this.lessonDate,
    this.lessonNumber,
    this.title,
    this.teacherName,
    this.attendanceCount = 0,
    this.createdAt,
  });

  factory EbdLessonSummary.fromJson(Map<String, dynamic> json) {
    return EbdLessonSummary(
      id: json['id'] as String,
      classId: json['class_id'] as String? ?? '',
      className: json['class_name'] as String?,
      lessonDate: json['lesson_date'] as String? ?? '',
      lessonNumber: json['lesson_number'] as int?,
      title: json['title'] as String?,
      teacherName: json['teacher_name'] as String?,
      attendanceCount: json['attendance_count'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
    );
  }

  String get displayTitle => title ?? 'Aula ${lessonNumber ?? ""}';

  @override
  List<Object?> get props => [id, classId, lessonDate, attendanceCount];
}

// ==========================================
// EBD Attendance (Frequência)
// ==========================================

class EbdAttendance extends Equatable {
  final String id;
  final String lessonId;
  final String memberId;
  final String status; // present, absent, justified
  final bool? broughtBible;
  final bool? broughtMagazine;
  final double offeringAmount;
  final bool isVisitor;
  final String? visitorName;
  final String? notes;
  final String? registeredBy;
  final DateTime? createdAt;

  const EbdAttendance({
    required this.id,
    required this.lessonId,
    required this.memberId,
    required this.status,
    this.broughtBible,
    this.broughtMagazine,
    this.offeringAmount = 0,
    this.isVisitor = false,
    this.visitorName,
    this.notes,
    this.registeredBy,
    this.createdAt,
  });

  factory EbdAttendance.fromJson(Map<String, dynamic> json) {
    return EbdAttendance(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String? ?? '',
      memberId: json['member_id'] as String? ?? '',
      status: json['status'] as String? ?? 'absent',
      broughtBible: json['brought_bible'] as bool?,
      broughtMagazine: json['brought_magazine'] as bool?,
      offeringAmount: _parseDecimal(json['offering_amount']),
      isVisitor: json['is_visitor'] as bool? ?? false,
      visitorName: json['visitor_name'] as String?,
      notes: json['notes'] as String?,
      registeredBy: json['registered_by'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'present':
        return 'Presente';
      case 'absent':
        return 'Ausente';
      case 'justified':
        return 'Justificado';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [id, lessonId, memberId, status];
}

// ==========================================
// EBD Attendance Detail (com nome do membro)
// ==========================================

class EbdAttendanceDetail extends Equatable {
  final String id;
  final String lessonId;
  final String memberId;
  final String? memberName;
  final String status;
  final bool? broughtBible;
  final bool? broughtMagazine;
  final double offeringAmount;
  final bool isVisitor;
  final String? visitorName;

  const EbdAttendanceDetail({
    required this.id,
    required this.lessonId,
    required this.memberId,
    this.memberName,
    required this.status,
    this.broughtBible,
    this.broughtMagazine,
    this.offeringAmount = 0,
    this.isVisitor = false,
    this.visitorName,
  });

  factory EbdAttendanceDetail.fromJson(Map<String, dynamic> json) {
    return EbdAttendanceDetail(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String? ?? '',
      memberId: json['member_id'] as String? ?? '',
      memberName: json['member_name'] as String?,
      status: json['status'] as String? ?? 'absent',
      broughtBible: json['brought_bible'] as bool?,
      broughtMagazine: json['brought_magazine'] as bool?,
      offeringAmount: _parseDecimal(json['offering_amount']),
      isVisitor: json['is_visitor'] as bool? ?? false,
      visitorName: json['visitor_name'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'present':
        return 'Presente';
      case 'absent':
        return 'Ausente';
      case 'justified':
        return 'Justificado';
      default:
        return status;
    }
  }

  String get displayName => isVisitor ? (visitorName ?? 'Visitante') : (memberName ?? 'Membro');

  @override
  List<Object?> get props => [id, lessonId, memberId, status];
}
