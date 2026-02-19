import '../../../core/network/api_client.dart';
import 'models/settings_models.dart';

class SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ==========================================
  // Churches
  // ==========================================

  Future<({List<Church> churches, int total})> getChurches({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _apiClient.dio.get(
      '/v1/churches',
      queryParameters: params,
    );
    final list = response.data['data'] as List? ?? [];
    final total = response.data['meta']?['total'] as int? ?? list.length;
    return (
      churches: list.map((e) => Church.fromJson(e as Map<String, dynamic>)).toList(),
      total: total,
    );
  }

  Future<Church> getChurch(String churchId) async {
    final response = await _apiClient.dio.get('/v1/churches/$churchId');
    return Church.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Church> getMyChurch() async {
    final response = await _apiClient.dio.get('/v1/churches/me');
    return Church.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> createChurch(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/churches', data: data);
  }

  Future<void> updateChurch(String churchId, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/v1/churches/$churchId', data: data);
  }

  // ==========================================
  // Users
  // ==========================================

  Future<({List<AppUser> users, int total})> getUsers({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _apiClient.dio.get(
      '/v1/users',
      queryParameters: params,
    );
    final list = response.data['data'] as List? ?? [];
    final total = response.data['meta']?['total'] as int? ?? list.length;
    return (
      users: list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList(),
      total: total,
    );
  }

  Future<AppUser> getUser(String userId) async {
    final response = await _apiClient.dio.get('/v1/users/$userId');
    return AppUser.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/v1/users', data: data);
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/v1/users/$userId', data: data);
  }

  // ==========================================
  // Roles
  // ==========================================

  Future<List<AppRole>> getRoles() async {
    final response = await _apiClient.dio.get('/v1/roles');
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => AppRole.fromJson(e as Map<String, dynamic>)).toList();
  }
}
