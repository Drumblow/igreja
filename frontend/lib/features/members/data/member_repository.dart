import '../../../core/network/api_client.dart';
import 'models/church_role_model.dart';
import 'models/member_models.dart';

class MemberRepository {
  final ApiClient _apiClient;

  MemberRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<({List<Member> members, int total})> getMembers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _apiClient.dio.get(
      '/v1/members',
      queryParameters: queryParams,
    );

    final data = response.data;
    final items = (data['data'] as List)
        .map((json) => Member.fromJson(json as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>?;
    final total = meta?['total'] as int? ?? items.length;

    return (members: items, total: total);
  }

  Future<Member> getMember(String id) async {
    final response = await _apiClient.dio.get('/v1/members/$id');
    return Member.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Member> createMember(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/v1/members', data: data);
    return Member.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Member> updateMember(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/v1/members/$id', data: data);
    return Member.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteMember(String id) async {
    await _apiClient.dio.delete('/v1/members/$id');
  }

  Future<MemberStats> getStats() async {
    final response = await _apiClient.dio.get('/v1/members/stats');
    return MemberStats.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Fetch the full history timeline for a member.
  Future<List<MemberHistory>> getMemberHistory(String memberId) async {
    final response = await _apiClient.dio.get('/v1/members/$memberId/history');
    final data = response.data['data'] as List;
    return data
        .map((json) => MemberHistory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new history event for a member.
  Future<MemberHistory> createMemberHistory(
    String memberId, {
    required String eventType,
    required DateTime eventDate,
    required String description,
    String? previousValue,
    String? newValue,
  }) async {
    final response = await _apiClient.dio.post(
      '/v1/members/$memberId/history',
      data: {
        'event_type': eventType,
        'event_date':
            '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
        'description': description,
        if (previousValue != null) 'previous_value': previousValue,
        if (newValue != null) 'new_value': newValue,
      },
    );
    return MemberHistory.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  // ── Church Roles ──

  /// Fetch all active church roles.
  Future<List<ChurchRole>> getChurchRoles() async {
    final response = await _apiClient.dio.get('/v1/church-roles');
    final data = response.data['data'] as List;
    return data
        .map((json) => ChurchRole.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new custom church role.
  Future<ChurchRole> createChurchRole({
    required String key,
    required String displayName,
    String? investitureType,
  }) async {
    final response = await _apiClient.dio.post(
      '/v1/church-roles',
      data: {
        'key': key,
        'display_name': displayName,
        if (investitureType != null) 'investiture_type': investitureType,
      },
    );
    return ChurchRole.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
