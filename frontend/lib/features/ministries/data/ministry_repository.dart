import '../../../core/network/api_client.dart';
import 'models/ministry_models.dart';

class MinistryRepository {
  final ApiClient _apiClient;

  MinistryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<({List<Ministry> ministries, int total})> getMinistries({
    int page = 1,
    int perPage = 20,
    String? search,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive;
    }

    final response = await _apiClient.dio.get(
      '/v1/ministries',
      queryParameters: queryParams,
    );

    final data = response.data;
    final items = (data['data'] as List)
        .map((json) => Ministry.fromJson(json as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>?;
    final total = meta?['total'] as int? ?? items.length;

    return (ministries: items, total: total);
  }

  Future<Ministry> getMinistry(String id) async {
    final response = await _apiClient.dio.get('/v1/ministries/$id');
    return Ministry.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<MinistryMember>> getMinistryMembers(String ministryId) async {
    final response =
        await _apiClient.dio.get('/v1/ministries/$ministryId/members');
    final data = response.data['data'] as List;
    return data
        .map((json) => MinistryMember.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Ministry> createMinistry(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/v1/ministries', data: data);
    return Ministry.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Ministry> updateMinistry(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response =
        await _apiClient.dio.put('/v1/ministries/$id', data: data);
    return Ministry.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteMinistry(String id) async {
    await _apiClient.dio.delete('/v1/ministries/$id');
  }

  Future<void> addMember({
    required String ministryId,
    required String memberId,
    String? roleInMinistry,
  }) async {
    await _apiClient.dio.post(
      '/v1/ministries/$ministryId/members',
      data: {
        'member_id': memberId,
        if (roleInMinistry != null && roleInMinistry.isNotEmpty)
          'role_in_ministry': roleInMinistry,
      },
    );
  }

  Future<void> removeMember({
    required String ministryId,
    required String memberId,
  }) async {
    await _apiClient.dio
        .delete('/v1/ministries/$ministryId/members/$memberId');
  }
}
