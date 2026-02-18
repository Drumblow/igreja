import '../../../core/network/api_client.dart';
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
}
