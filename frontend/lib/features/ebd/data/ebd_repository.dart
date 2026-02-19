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
}
