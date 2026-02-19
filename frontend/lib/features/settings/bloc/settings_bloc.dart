import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/settings_repository.dart';
import 'settings_event_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

  SettingsBloc({required this.repository}) : super(const SettingsInitial()) {
    on<ChurchLoadRequested>(_onChurchLoad);
    on<ChurchesLoadRequested>(_onChurchesLoad);
    on<ChurchCreateRequested>(_onChurchCreate);
    on<ChurchUpdateRequested>(_onChurchUpdate);
    on<UsersLoadRequested>(_onUsersLoad);
    on<UserCreateRequested>(_onUserCreate);
    on<UserUpdateRequested>(_onUserUpdate);
    on<RolesLoadRequested>(_onRolesLoad);
  }

  // ==========================================
  // Churches
  // ==========================================

  Future<void> _onChurchLoad(
      ChurchLoadRequested event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      final church = await repository.getMyChurch();
      emit(ChurchLoaded(church: church));
    } catch (e) {
      emit(SettingsError(message: 'Erro ao carregar dados da igreja: $e'));
    }
  }

  Future<void> _onChurchesLoad(
      ChurchesLoadRequested event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      final result = await repository.getChurches(search: event.search);
      emit(ChurchesLoaded(churches: result.churches, total: result.total));
    } catch (e) {
      emit(SettingsError(message: 'Erro ao carregar igrejas: $e'));
    }
  }

  Future<void> _onChurchCreate(
      ChurchCreateRequested event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      await repository.createChurch(event.data);
      emit(const SettingsSaved(message: 'Igreja criada com sucesso'));
    } catch (e) {
      emit(SettingsError(message: 'Erro ao criar igreja: $e'));
    }
  }

  Future<void> _onChurchUpdate(
      ChurchUpdateRequested event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      await repository.updateChurch(event.churchId, event.data);
      emit(const SettingsSaved(message: 'Igreja atualizada com sucesso'));
    } catch (e) {
      emit(SettingsError(message: 'Erro ao atualizar igreja: $e'));
    }
  }

  // ==========================================
  // Users
  // ==========================================

  Future<void> _onUsersLoad(
      UsersLoadRequested event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      final result = await repository.getUsers(search: event.search);
      final roles = await repository.getRoles();
      emit(UsersLoaded(users: result.users, total: result.total, roles: roles));
    } catch (e) {
      emit(SettingsError(message: 'Erro ao carregar usuários: $e'));
    }
  }

  Future<void> _onUserCreate(
      UserCreateRequested event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      await repository.createUser(event.data);
      emit(const SettingsSaved(message: 'Usuário criado com sucesso'));
    } catch (e) {
      emit(SettingsError(message: 'Erro ao criar usuário: $e'));
    }
  }

  Future<void> _onUserUpdate(
      UserUpdateRequested event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      await repository.updateUser(event.userId, event.data);
      emit(const SettingsSaved(message: 'Usuário atualizado com sucesso'));
    } catch (e) {
      emit(SettingsError(message: 'Erro ao atualizar usuário: $e'));
    }
  }

  // ==========================================
  // Roles
  // ==========================================

  Future<void> _onRolesLoad(
      RolesLoadRequested event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      final roles = await repository.getRoles();
      emit(RolesLoaded(roles: roles));
    } catch (e) {
      emit(SettingsError(message: 'Erro ao carregar papéis: $e'));
    }
  }
}
