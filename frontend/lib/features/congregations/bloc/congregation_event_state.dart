import 'package:equatable/equatable.dart';
import '../data/models/congregation_models.dart';

// ── Events ──
abstract class CongregationEvent extends Equatable {
  const CongregationEvent();

  @override
  List<Object?> get props => [];
}

class CongregationsLoadRequested extends CongregationEvent {
  final bool? isActive;
  final String? type;

  const CongregationsLoadRequested({this.isActive, this.type});

  @override
  List<Object?> get props => [isActive, type];
}

class CongregationCreateRequested extends CongregationEvent {
  final Map<String, dynamic> data;

  const CongregationCreateRequested({required this.data});

  @override
  List<Object?> get props => [data];
}

class CongregationUpdateRequested extends CongregationEvent {
  final String congregationId;
  final Map<String, dynamic> data;

  const CongregationUpdateRequested({
    required this.congregationId,
    required this.data,
  });

  @override
  List<Object?> get props => [congregationId, data];
}

class CongregationDeactivateRequested extends CongregationEvent {
  final String congregationId;

  const CongregationDeactivateRequested({required this.congregationId});

  @override
  List<Object?> get props => [congregationId];
}

class CongregationAssignMembersRequested extends CongregationEvent {
  final String congregationId;
  final List<String> memberIds;
  final bool overwrite;

  const CongregationAssignMembersRequested({
    required this.congregationId,
    required this.memberIds,
    this.overwrite = false,
  });

  @override
  List<Object?> get props => [congregationId, memberIds, overwrite];
}

// ── States ──
abstract class CongregationState extends Equatable {
  const CongregationState();

  @override
  List<Object?> get props => [];
}

class CongregationInitial extends CongregationState {
  const CongregationInitial();
}

class CongregationLoading extends CongregationState {
  const CongregationLoading();
}

class CongregationListLoaded extends CongregationState {
  final List<Congregation> congregations;

  const CongregationListLoaded({required this.congregations});

  @override
  List<Object?> get props => [congregations];
}

class CongregationSaved extends CongregationState {
  final Congregation congregation;
  final String message;

  const CongregationSaved({
    required this.congregation,
    required this.message,
  });

  @override
  List<Object?> get props => [congregation, message];
}

class CongregationMembersAssigned extends CongregationState {
  final AssignMembersResult result;
  final String message;

  const CongregationMembersAssigned({
    required this.result,
    required this.message,
  });

  @override
  List<Object?> get props => [result, message];
}

class CongregationDeleted extends CongregationState {
  final String message;

  const CongregationDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

class CongregationError extends CongregationState {
  final String message;

  const CongregationError({required this.message});

  @override
  List<Object?> get props => [message];
}
