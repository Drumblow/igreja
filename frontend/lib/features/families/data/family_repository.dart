import '../../../core/network/api_client.dart';
import 'models/family_models.dart';

class FamilyRepository {
  final ApiClient _apiClient;

  FamilyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<({List<Family> families, int total})> getFamilies({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final response = await _apiClient.dio.get(
      '/v1/families',
      queryParameters: queryParams,
    );

    final data = response.data;
    final items = (data['data'] as List)
        .map((json) => Family.fromJson(json as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>?;
    final total = meta?['total'] as int? ?? items.length;

    return (families: items, total: total);
  }

  Future<Family> getFamily(String id) async {
    final response = await _apiClient.dio.get('/v1/families/$id');
    return Family.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Family> createFamily(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/v1/families', data: data);
    return Family.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Family> updateFamily(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/v1/families/$id', data: data);
    return Family.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteFamily(String id) async {
    await _apiClient.dio.delete('/v1/families/$id');
  }

  Future<void> addMember({
    required String familyId,
    required String memberId,
    required String relationship,
  }) async {
    await _apiClient.dio.post(
      '/v1/families/$familyId/members',
      data: {
        'member_id': memberId,
        'relationship': relationship,
      },
    );
  }

  Future<void> removeMember({
    required String familyId,
    required String memberId,
  }) async {
    await _apiClient.dio.delete('/v1/families/$familyId/members/$memberId');
  }
}
