import 'package:equatable/equatable.dart';
import '../data/models/settings_models.dart';

// ══════════════════════════════════════════
// Events
// ══════════════════════════════════════════

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

// ---- Church ----

class ChurchLoadRequested extends SettingsEvent {
  const ChurchLoadRequested();
}

class ChurchesLoadRequested extends SettingsEvent {
  final String? search;
  const ChurchesLoadRequested({this.search});
  @override
  List<Object?> get props => [search];
}

class ChurchCreateRequested extends SettingsEvent {
  final Map<String, dynamic> data;
  const ChurchCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

class ChurchUpdateRequested extends SettingsEvent {
  final String churchId;
  final Map<String, dynamic> data;
  const ChurchUpdateRequested({required this.churchId, required this.data});
  @override
  List<Object?> get props => [churchId, data];
}

// ---- Users ----

class UsersLoadRequested extends SettingsEvent {
  final String? search;
  const UsersLoadRequested({this.search});
  @override
  List<Object?> get props => [search];
}

class UserCreateRequested extends SettingsEvent {
  final Map<String, dynamic> data;
  const UserCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

class UserUpdateRequested extends SettingsEvent {
  final String userId;
  final Map<String, dynamic> data;
  const UserUpdateRequested({required this.userId, required this.data});
  @override
  List<Object?> get props => [userId, data];
}

// ---- Roles ----

class RolesLoadRequested extends SettingsEvent {
  const RolesLoadRequested();
}

// ══════════════════════════════════════════
// States
// ══════════════════════════════════════════

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class ChurchLoaded extends SettingsState {
  final Church church;
  const ChurchLoaded({required this.church});
  @override
  List<Object?> get props => [church];
}

class ChurchesLoaded extends SettingsState {
  final List<Church> churches;
  final int total;
  const ChurchesLoaded({required this.churches, required this.total});
  @override
  List<Object?> get props => [churches, total];
}

class UsersLoaded extends SettingsState {
  final List<AppUser> users;
  final int total;
  final List<AppRole> roles;
  const UsersLoaded({required this.users, required this.total, this.roles = const []});
  @override
  List<Object?> get props => [users, total, roles];
}

class RolesLoaded extends SettingsState {
  final List<AppRole> roles;
  const RolesLoaded({required this.roles});
  @override
  List<Object?> get props => [roles];
}

class SettingsSaved extends SettingsState {
  final String message;
  const SettingsSaved({required this.message});
  @override
  List<Object?> get props => [message];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError({required this.message});
  @override
  List<Object?> get props => [message];
}
