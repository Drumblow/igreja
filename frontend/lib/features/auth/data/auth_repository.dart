import '../../../core/network/api_client.dart';
import 'models/auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      '/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final loginResponse = LoginResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );

    await _apiClient.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
    );

    return loginResponse;
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/v1/auth/logout');
    } catch (_) {
      // Even if server logout fails, clear local tokens
    }
    await _apiClient.clearTokens();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.dio.get('/v1/auth/me');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<bool> isAuthenticated() async {
    return _apiClient.hasToken();
  }

  Future<void> forgotPassword({required String email}) async {
    await _apiClient.dio.post(
      '/v1/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.dio.post(
      '/v1/auth/reset-password',
      data: {
        'token': token,
        'new_password': newPassword,
      },
    );
  }
}
