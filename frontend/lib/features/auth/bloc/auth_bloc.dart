import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';
import 'auth_event_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        final profile = await _authRepository.getProfile();
        emit(AuthAuthenticated(
          user: AuthUser(
            id: profile['id'] as String,
            email: profile['email'] as String,
            role: profile['role'] as String,
            churchId: profile['church_id'] as String,
            churchName: profile['church_name'] as String,
          ),
        ));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: response.user));
    } catch (e) {
      String message = 'Erro ao realizar login';
      if (e is Exception) {
        // Extract message from Dio errors
        message = _extractErrorMessage(e);
      }
      emit(AuthError(message: message));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  String _extractErrorMessage(dynamic error) {
    try {
      if (error.toString().contains('401')) {
        return 'E-mail ou senha inválidos';
      }
      if (error.toString().contains('bloqueada')) {
        return 'Conta temporariamente bloqueada';
      }
    } catch (_) {}
    return 'Erro de conexão. Tente novamente.';
  }
}
