import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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
      status: json['status'] as String? ?? 'ausente',
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
      case 'presente':
        return 'Presente';
      case 'ausente':
        return 'Ausente';
      case 'justificado':
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
      status: json['status'] as String? ?? 'ausente',
      broughtBible: json['brought_bible'] as bool?,
      broughtMagazine: json['brought_magazine'] as bool?,
      offeringAmount: _parseDecimal(json['offering_amount']),
      isVisitor: json['is_visitor'] as bool? ?? false,
      visitorName: json['visitor_name'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'presente':
        return 'Presente';
      case 'ausente':
        return 'Ausente';
      case 'justificado':
        return 'Justificado';
      default:
        return status;
    }
  }

  String get displayName => isVisitor ? (visitorName ?? 'Visitante') : (memberName ?? 'Membro');

  @override
  List<Object?> get props => [id, lessonId, memberId, status];
}

// ==========================================
// EBD Lesson Content (E1 - Conteúdo Enriquecido)
// ==========================================

class EbdLessonContent extends Equatable {
  final String id;
  final String lessonId;
  final String contentType; // text, image, bible_reference, note
  final String? title;
  final String? body;
  final String? imageUrl;
  final String? imageCaption;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EbdLessonContent({
    required this.id,
    required this.lessonId,
    required this.contentType,
    this.title,
    this.body,
    this.imageUrl,
    this.imageCaption,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory EbdLessonContent.fromJson(Map<String, dynamic> json) {
    return EbdLessonContent(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String? ?? '',
      contentType: json['content_type'] as String? ?? 'text',
      title: json['title'] as String?,
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      imageCaption: json['image_caption'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  IconData get typeIcon {
    switch (contentType) {
      case 'text':
        return const IconData(0xe262, fontFamily: 'MaterialIcons'); // description
      case 'image':
        return const IconData(0xe3f4, fontFamily: 'MaterialIcons'); // image
      case 'bible_reference':
        return const IconData(0xe0ef, fontFamily: 'MaterialIcons'); // auto_stories
      case 'note':
        return const IconData(0xe566, fontFamily: 'MaterialIcons'); // sticky_note_2
      default:
        return const IconData(0xe262, fontFamily: 'MaterialIcons');
    }
  }

  String get typeLabel {
    switch (contentType) {
      case 'text':
        return 'Texto';
      case 'image':
        return 'Imagem';
      case 'bible_reference':
        return 'Referência Bíblica';
      case 'note':
        return 'Nota';
      default:
        return contentType;
    }
  }

  @override
  List<Object?> get props => [id, lessonId, contentType, sortOrder];
}

// ==========================================
// EBD Lesson Activity (E2 - Atividades)
// ==========================================

class EbdLessonActivity extends Equatable {
  final String id;
  final String lessonId;
  final String activityType; // question, multiple_choice, fill_blank, group_activity, homework, other
  final String title;
  final String? description;
  final dynamic options; // JSON array for multiple_choice
  final String? correctAnswer;
  final String? bibleReference;
  final bool isRequired;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EbdLessonActivity({
    required this.id,
    required this.lessonId,
    required this.activityType,
    required this.title,
    this.description,
    this.options,
    this.correctAnswer,
    this.bibleReference,
    this.isRequired = false,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory EbdLessonActivity.fromJson(Map<String, dynamic> json) {
    return EbdLessonActivity(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String? ?? '',
      activityType: json['activity_type'] as String? ?? 'question',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      options: json['options'],
      correctAnswer: json['correct_answer'] as String?,
      bibleReference: json['bible_reference'] as String?,
      isRequired: json['is_required'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  String get typeLabel {
    switch (activityType) {
      case 'question':
        return 'Pergunta';
      case 'multiple_choice':
        return 'Múltipla Escolha';
      case 'fill_blank':
        return 'Complete';
      case 'group_activity':
        return 'Dinâmica de Grupo';
      case 'homework':
        return 'Tarefa de Casa';
      case 'other':
        return 'Outro';
      default:
        return activityType;
    }
  }

  String get typeEmoji {
    switch (activityType) {
      case 'question':
        return '❓';
      case 'multiple_choice':
        return '📋';
      case 'fill_blank':
        return '📝';
      case 'group_activity':
        return '👥';
      case 'homework':
        return '🏠';
      default:
        return '📌';
    }
  }

  List<String> get optionsList {
    if (options == null) return [];
    if (options is List) return (options as List).map((e) => e.toString()).toList();
    return [];
  }

  @override
  List<Object?> get props => [id, lessonId, activityType, title];
}

// ==========================================
// EBD Activity Response (E2 - Respostas)
// ==========================================

class EbdActivityResponse extends Equatable {
  final String id;
  final String activityId;
  final String memberId;
  final String? memberName;
  final String? responseText;
  final bool isCompleted;
  final int? score;
  final String? teacherFeedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EbdActivityResponse({
    required this.id,
    required this.activityId,
    required this.memberId,
    this.memberName,
    this.responseText,
    this.isCompleted = false,
    this.score,
    this.teacherFeedback,
    this.createdAt,
    this.updatedAt,
  });

  factory EbdActivityResponse.fromJson(Map<String, dynamic> json) {
    return EbdActivityResponse(
      id: json['id'] as String,
      activityId: json['activity_id'] as String? ?? '',
      memberId: json['member_id'] as String? ?? '',
      memberName: json['member_name'] as String?,
      responseText: json['response_text'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      score: json['score'] as int?,
      teacherFeedback: json['teacher_feedback'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [id, activityId, memberId, isCompleted];
}

// ==========================================
// EBD Lesson Material (E4 - Materiais)
// ==========================================

class EbdLessonMaterial extends Equatable {
  final String id;
  final String lessonId;
  final String materialType; // document, video, audio, link, image
  final String title;
  final String? description;
  final String? url;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? uploadedBy;
  final DateTime? createdAt;

  const EbdLessonMaterial({
    required this.id,
    required this.lessonId,
    required this.materialType,
    required this.title,
    this.description,
    this.url,
    this.fileSizeBytes,
    this.mimeType,
    this.uploadedBy,
    this.createdAt,
  });

  factory EbdLessonMaterial.fromJson(Map<String, dynamic> json) {
    return EbdLessonMaterial(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String? ?? '',
      materialType: json['material_type'] as String? ?? 'link',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      url: json['url'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      mimeType: json['mime_type'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  String get typeLabel {
    switch (materialType) {
      case 'document':
        return 'Documento';
      case 'video':
        return 'Vídeo';
      case 'audio':
        return 'Áudio';
      case 'link':
        return 'Link';
      case 'image':
        return 'Imagem';
      default:
        return materialType;
    }
  }

  IconData get typeIcon {
    switch (materialType) {
      case 'document':
        return const IconData(0xe873, fontFamily: 'MaterialIcons'); // description
      case 'video':
        return const IconData(0xf06bb, fontFamily: 'MaterialIcons'); // videocam
      case 'audio':
        return const IconData(0xe050, fontFamily: 'MaterialIcons'); // audiotrack
      case 'link':
        return const IconData(0xe157, fontFamily: 'MaterialIcons'); // link
      case 'image':
        return const IconData(0xe3f4, fontFamily: 'MaterialIcons'); // image
      default:
        return const IconData(0xe226, fontFamily: 'MaterialIcons'); // attach_file
    }
  }

  @override
  List<Object?> get props => [id, lessonId, materialType, title];
}

// ==========================================
// EBD Student Note (E5 - Anotações do Professor)
// ==========================================

class EbdStudentNote extends Equatable {
  final String id;
  final String memberId;
  final String? termId;
  final String? termName;
  final String noteType; // observation, behavior, progress, special_need, praise, concern
  final String title;
  final String content;
  final bool isPrivate;
  final String? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EbdStudentNote({
    required this.id,
    required this.memberId,
    this.termId,
    this.termName,
    required this.noteType,
    required this.title,
    required this.content,
    this.isPrivate = false,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  factory EbdStudentNote.fromJson(Map<String, dynamic> json) {
    return EbdStudentNote(
      id: json['id'] as String,
      memberId: json['member_id'] as String? ?? '',
      termId: json['term_id'] as String?,
      termName: json['term_name'] as String?,
      noteType: json['note_type'] as String? ?? 'observation',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isPrivate: json['is_private'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdByName: json['created_by_name'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  String get typeLabel {
    switch (noteType) {
      case 'observation':
        return 'Observação';
      case 'behavior':
        return 'Comportamento';
      case 'progress':
        return 'Progresso';
      case 'special_need':
        return 'Necessidade Especial';
      case 'praise':
        return 'Elogio';
      case 'concern':
        return 'Preocupação';
      default:
        return noteType;
    }
  }

  Color get typeColor {
    switch (noteType) {
      case 'praise':
        return const Color(0xFF4CAF50);
      case 'concern':
        return const Color(0xFFF44336);
      case 'progress':
        return const Color(0xFF2196F3);
      case 'special_need':
        return const Color(0xFFFF9800);
      case 'behavior':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF607D8B);
    }
  }

  @override
  List<Object?> get props => [id, memberId, noteType, title];
}

// ==========================================
// EBD Student Summary (E3 - Perfil do Aluno)
// ==========================================

class EbdStudentSummary extends Equatable {
  final String memberId;
  final String fullName;
  final String? gender;
  final String? photoUrl;
  final String? memberStatus;
  final int activeEnrollments;
  final int totalEnrollments;
  final int termsAttended;
  final int totalPresent;
  final int totalAbsent;
  final int totalJustified;
  final int totalAttendanceRecords;
  final double attendancePercentage;
  final int timesBroughtBible;
  final int timesBroughtMagazine;
  final double totalOfferings;

  const EbdStudentSummary({
    required this.memberId,
    required this.fullName,
    this.gender,
    this.photoUrl,
    this.memberStatus,
    this.activeEnrollments = 0,
    this.totalEnrollments = 0,
    this.termsAttended = 0,
    this.totalPresent = 0,
    this.totalAbsent = 0,
    this.totalJustified = 0,
    this.totalAttendanceRecords = 0,
    this.attendancePercentage = 0,
    this.timesBroughtBible = 0,
    this.timesBroughtMagazine = 0,
    this.totalOfferings = 0,
  });

  factory EbdStudentSummary.fromJson(Map<String, dynamic> json) {
    return EbdStudentSummary(
      memberId: json['member_id'] as String,
      fullName: json['full_name'] as String? ?? '',
      gender: json['gender'] as String?,
      photoUrl: json['photo_url'] as String?,
      memberStatus: json['member_status'] as String?,
      activeEnrollments: json['active_enrollments'] as int? ?? 0,
      totalEnrollments: json['total_enrollments'] as int? ?? 0,
      termsAttended: json['terms_attended'] as int? ?? 0,
      totalPresent: json['total_present'] as int? ?? 0,
      totalAbsent: json['total_absent'] as int? ?? 0,
      totalJustified: json['total_justified'] as int? ?? 0,
      totalAttendanceRecords: json['total_attendance_records'] as int? ?? 0,
      attendancePercentage: _parseDecimal(json['attendance_percentage']),
      timesBroughtBible: json['times_brought_bible'] as int? ?? 0,
      timesBroughtMagazine: json['times_brought_magazine'] as int? ?? 0,
      totalOfferings: _parseDecimal(json['total_offerings']),
    );
  }

  @override
  List<Object?> get props => [memberId, fullName, attendancePercentage];
}

// ==========================================
// EBD Enrollment History (E3 - Histórico)
// ==========================================

class EbdEnrollmentHistory extends Equatable {
  final String termName;
  final String className;
  final String? teacherName;
  final String enrolledAt;
  final String? leftAt;
  final int totalLessons;
  final int presentCount;
  final int absentCount;
  final int justifiedCount;
  final double attendancePercentage;

  const EbdEnrollmentHistory({
    required this.termName,
    required this.className,
    this.teacherName,
    required this.enrolledAt,
    this.leftAt,
    this.totalLessons = 0,
    this.presentCount = 0,
    this.absentCount = 0,
    this.justifiedCount = 0,
    this.attendancePercentage = 0,
  });

  factory EbdEnrollmentHistory.fromJson(Map<String, dynamic> json) {
    return EbdEnrollmentHistory(
      termName: json['term_name'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      teacherName: json['teacher_name'] as String?,
      enrolledAt: json['enrolled_at'] as String? ?? '',
      leftAt: json['left_at'] as String?,
      totalLessons: json['total_lessons'] as int? ?? 0,
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      justifiedCount: json['justified_count'] as int? ?? 0,
      attendancePercentage: _parseDecimal(json['attendance_percentage']),
    );
  }

  @override
  List<Object?> get props => [termName, className, attendancePercentage];
}
