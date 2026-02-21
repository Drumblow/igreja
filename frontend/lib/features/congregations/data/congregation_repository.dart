import '../../../core/network/api_client.dart';
import 'models/congregation_models.dart';

class CongregationRepository {
  final ApiClient _apiClient;

  CongregationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// List all congregations for the current church
  Future<List<Congregation>> getCongregations({
    bool? isActive,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{};
    if (isActive != null) queryParams['is_active'] = isActive;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;

    final response = await _apiClient.dio.get(
      '/v1/congregations',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as List;
    return data
        .map((json) => Congregation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get congregation by ID (returns enriched detail with leader_name and stats)
  Future<Congregation> getCongregation(String id) async {
    final response = await _apiClient.dio.get('/v1/congregations/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    // The backend returns a flattened CongregationDetail with congregation
    // fields at root level (via serde flatten), plus leader_name and stats.
    // Congregation.fromJson handles all root-level fields including leader_name.
    return Congregation.fromJson(data);
  }

  /// Get the embedded stats from a congregation detail response, if available.
  Future<CongregationStats?> getCongregationStatsFromDetail(String id) async {
    final response = await _apiClient.dio.get('/v1/congregations/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    if (data['stats'] != null) {
      return CongregationStats.fromJson(data['stats'] as Map<String, dynamic>);
    }
    return null;
  }

  /// Create a new congregation
  Future<Congregation> createCongregation(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      '/v1/congregations',
      data: data,
    );
    return Congregation.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Update a congregation
  Future<Congregation> updateCongregation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.dio.put(
      '/v1/congregations/$id',
      data: data,
    );
    return Congregation.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Deactivate a congregation (soft delete)
  Future<void> deactivateCongregation(String id) async {
    await _apiClient.dio.delete('/v1/congregations/$id');
  }

  /// Get congregation stats
  Future<CongregationStats> getCongregationStats(String id) async {
    final response =
        await _apiClient.dio.get('/v1/congregations/$id/stats');
    return CongregationStats.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// List users with access to a congregation
  Future<List<CongregationUser>> getCongregationUsers(
    String congregationId,
  ) async {
    final response = await _apiClient.dio
        .get('/v1/congregations/$congregationId/users');
    final data = response.data['data'] as List;
    return data
        .map(
            (json) => CongregationUser.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Add user to a congregation
  Future<void> addUserToCongregation({
    required String congregationId,
    required String userId,
    required String roleInCongregation,
    bool isPrimary = false,
  }) async {
    await _apiClient.dio.post(
      '/v1/congregations/$congregationId/users',
      data: {
        'user_id': userId,
        'role_in_congregation': roleInCongregation,
        'is_primary': isPrimary,
      },
    );
  }

  /// Remove user from a congregation
  Future<void> removeUserFromCongregation({
    required String congregationId,
    required String userId,
  }) async {
    await _apiClient.dio
        .delete('/v1/congregations/$congregationId/users/$userId');
  }

  /// Assign members to a congregation in batch
  Future<AssignMembersResult> assignMembers({
    required String congregationId,
    required List<String> memberIds,
    bool overwrite = false,
  }) async {
    final response = await _apiClient.dio.post(
      '/v1/congregations/$congregationId/assign-members',
      data: {
        'member_ids': memberIds,
        'overwrite': overwrite,
      },
    );
    return AssignMembersResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Set active congregation for the current user
  Future<void> setActiveCongregation(String? congregationId) async {
    await _apiClient.dio.post(
      '/v1/user/active-congregation',
      data: {'congregation_id': congregationId},
    );
  }

  /// Get congregations overview report
  Future<CongregationsOverview> getOverviewReport() async {
    final response = await _apiClient.dio
        .get('/v1/reports/congregations/overview');
    return CongregationsOverview.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Get congregations compare report
  Future<CongregationCompareReport> getCompareReport({
    String metric = 'members',
    String? periodStart,
    String? periodEnd,
    List<String>? congregationIds,
  }) async {
    final queryParams = <String, dynamic>{
      'metric': metric,
    };
    if (periodStart != null) queryParams['period_start'] = periodStart;
    if (periodEnd != null) queryParams['period_end'] = periodEnd;
    if (congregationIds != null && congregationIds.isNotEmpty) {
      queryParams['congregation_ids'] = congregationIds.join(',');
    }

    final response = await _apiClient.dio.get(
      '/v1/reports/congregations/compare',
      queryParameters: queryParams,
    );
    return CongregationCompareReport.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
