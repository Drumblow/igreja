import '../../../core/network/api_client.dart';
import 'models/ebd_models.dart';

class EbdRepository {
  final ApiClient _apiClient;

  EbdRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ==========================================
  // Terms (Trimestres)
  // ==========================================

  Future<List<EbdTerm>> getTerms({int page = 1, int perPage = 20}) async {
    final response = await _apiClient.dio.get(
      '/v1/ebd/terms',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdTerm.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EbdTerm> getTerm(String termId) async {
    final response = await _apiClient.dio.get('/v1/ebd/terms/$termId');
    return EbdTerm.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> createTerm(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/terms', data: data);
  }

  Future<void> updateTerm(String termId, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/v1/ebd/terms/$termId', data: data);
  }

  // ==========================================
  // Classes (Turmas)
  // ==========================================

  Future<List<EbdClassSummary>> getClasses({
    String? termId,
    bool? isActive,
    String? teacherId,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (termId != null) params['term_id'] = termId;
    if (isActive != null) params['is_active'] = isActive;
    if (teacherId != null) params['teacher_id'] = teacherId;

    final response = await _apiClient.dio.get(
      '/v1/ebd/classes',
      queryParameters: params,
    );
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdClassSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EbdClass> getClass(String classId) async {
    final response = await _apiClient.dio.get('/v1/ebd/classes/$classId');
    return EbdClass.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> createClass(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/classes', data: data);
  }

  Future<void> updateClass(String classId, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/v1/ebd/classes/$classId', data: data);
  }

  // ==========================================
  // Enrollments (Matrículas)
  // ==========================================

  Future<List<EbdEnrollmentDetail>> getClassEnrollments(String classId) async {
    final response = await _apiClient.dio.get('/v1/ebd/classes/$classId/enrollments');
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdEnrollmentDetail.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> enrollMember(String classId, Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/classes/$classId/enrollments', data: data);
  }

  Future<void> removeEnrollment(String classId, String enrollmentId) async {
    await _apiClient.dio.delete('/v1/ebd/classes/$classId/enrollments/$enrollmentId');
  }

  // ==========================================
  // Lessons (Aulas)
  // ==========================================

  Future<List<EbdLessonSummary>> getLessons({
    String? classId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (classId != null) params['class_id'] = classId;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;

    final response = await _apiClient.dio.get(
      '/v1/ebd/lessons',
      queryParameters: params,
    );
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdLessonSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EbdLesson> getLesson(String lessonId) async {
    final response = await _apiClient.dio.get('/v1/ebd/lessons/$lessonId');
    return EbdLesson.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> createLesson(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/lessons', data: data);
  }

  // ==========================================
  // Attendance (Frequência)
  // ==========================================

  Future<void> recordAttendance(String lessonId, Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/lessons/$lessonId/attendance', data: data);
  }

  Future<List<EbdAttendanceDetail>> getLessonAttendance(String lessonId) async {
    final response = await _apiClient.dio.get('/v1/ebd/lessons/$lessonId/attendance');
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdAttendanceDetail.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getClassReport(
    String classId, {
    String? dateFrom,
    String? dateTo,
  }) async {
    final params = <String, dynamic>{};
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;

    final response = await _apiClient.dio.get(
      '/v1/ebd/classes/$classId/report',
      queryParameters: params,
    );
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  // ==========================================
  // Lessons - Update / Delete (F1.2)
  // ==========================================

  Future<void> updateLesson(String lessonId, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/v1/ebd/lessons/$lessonId', data: data);
  }

  Future<void> deleteLesson(String lessonId, {bool force = false}) async {
    await _apiClient.dio.delete(
      '/v1/ebd/lessons/$lessonId',
      queryParameters: {'force': force},
    );
  }

  // ==========================================
  // Lesson Contents (E1)
  // ==========================================

  Future<List<EbdLessonContent>> getLessonContents(String lessonId) async {
    final response = await _apiClient.dio.get('/v1/ebd/lessons/$lessonId/contents');
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdLessonContent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createLessonContent(String lessonId, Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/lessons/$lessonId/contents', data: data);
  }

  Future<void> updateLessonContent(String lessonId, String contentId, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/v1/ebd/lessons/$lessonId/contents/$contentId', data: data);
  }

  Future<void> deleteLessonContent(String lessonId, String contentId) async {
    await _apiClient.dio.delete('/v1/ebd/lessons/$lessonId/contents/$contentId');
  }

  Future<void> reorderLessonContents(String lessonId, List<String> contentIds) async {
    await _apiClient.dio.put(
      '/v1/ebd/lessons/$lessonId/contents/reorder',
      data: {'content_ids': contentIds},
    );
  }

  // ==========================================
  // Lesson Activities (E2)
  // ==========================================

  Future<List<EbdLessonActivity>> getLessonActivities(String lessonId) async {
    final response = await _apiClient.dio.get('/v1/ebd/lessons/$lessonId/activities');
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdLessonActivity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createLessonActivity(String lessonId, Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/lessons/$lessonId/activities', data: data);
  }

  Future<void> updateLessonActivity(String lessonId, String activityId, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/v1/ebd/lessons/$lessonId/activities/$activityId', data: data);
  }

  Future<void> deleteLessonActivity(String lessonId, String activityId) async {
    await _apiClient.dio.delete('/v1/ebd/lessons/$lessonId/activities/$activityId');
  }

  // ==========================================
  // Activity Responses (E2)
  // ==========================================

  Future<List<EbdActivityResponse>> getActivityResponses(String activityId) async {
    final response = await _apiClient.dio.get('/v1/ebd/activities/$activityId/responses');
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdActivityResponse.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> recordActivityResponses(String activityId, Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/activities/$activityId/responses', data: data);
  }

  Future<void> updateActivityResponse(String activityId, String responseId, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/v1/ebd/activities/$activityId/responses/$responseId', data: data);
  }

  // ==========================================
  // Lesson Materials (E4)
  // ==========================================

  Future<List<EbdLessonMaterial>> getLessonMaterials(String lessonId) async {
    final response = await _apiClient.dio.get('/v1/ebd/lessons/$lessonId/materials');
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdLessonMaterial.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createLessonMaterial(String lessonId, Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/lessons/$lessonId/materials', data: data);
  }

  Future<void> deleteLessonMaterial(String lessonId, String materialId) async {
    await _apiClient.dio.delete('/v1/ebd/lessons/$lessonId/materials/$materialId');
  }

  // ==========================================
  // Student Profile (E3)
  // ==========================================

  Future<List<EbdStudentSummary>> getEbdStudents({
    String? termId,
    String? classId,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (termId != null) params['term_id'] = termId;
    if (classId != null) params['class_id'] = classId;
    if (search != null) params['search'] = search;

    final response = await _apiClient.dio.get(
      '/v1/ebd/students',
      queryParameters: params,
    );
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdStudentSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getStudentProfile(String memberId) async {
    final response = await _apiClient.dio.get('/v1/ebd/students/$memberId/profile');
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<EbdEnrollmentHistory>> getStudentHistory(String memberId) async {
    final response = await _apiClient.dio.get('/v1/ebd/students/$memberId/history');
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdEnrollmentHistory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<EbdActivityResponse>> getStudentActivities(String memberId) async {
    final response = await _apiClient.dio.get('/v1/ebd/students/$memberId/activities');
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdActivityResponse.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ==========================================
  // Student Notes (E5)
  // ==========================================

  Future<List<EbdStudentNote>> getStudentNotes(String memberId, {String? termId}) async {
    final params = <String, dynamic>{};
    if (termId != null) params['term_id'] = termId;

    final response = await _apiClient.dio.get(
      '/v1/ebd/students/$memberId/notes',
      queryParameters: params,
    );
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => EbdStudentNote.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createStudentNote(String memberId, Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/students/$memberId/notes', data: data);
  }

  Future<void> updateStudentNote(String memberId, String noteId, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/v1/ebd/students/$memberId/notes/$noteId', data: data);
  }

  Future<void> deleteStudentNote(String memberId, String noteId) async {
    await _apiClient.dio.delete('/v1/ebd/students/$memberId/notes/$noteId');
  }

  // ==========================================
  // Clone Classes (E7)
  // ==========================================

  Future<void> cloneClasses(String termId, Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/ebd/terms/$termId/clone-classes', data: data);
  }
}
