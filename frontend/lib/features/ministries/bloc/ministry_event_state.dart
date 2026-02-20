import 'package:equatable/equatable.dart';
import '../data/models/ministry_models.dart';

// ── Events ──
abstract class MinistryEvent extends Equatable {
  const MinistryEvent();

  @override
  List<Object?> get props => [];
}

class MinistriesLoadRequested extends MinistryEvent {
  final int page;
  final String? search;
  final bool? isActive;

  const MinistriesLoadRequested({this.page = 1, this.search, this.isActive});

  @override
  List<Object?> get props => [page, search, isActive];
}

class MinistryCreateRequested extends MinistryEvent {
  final Map<String, dynamic> data;

  const MinistryCreateRequested({required this.data});

  @override
  List<Object?> get props => [data];
}

class MinistryUpdateRequested extends MinistryEvent {
  final String ministryId;
  final Map<String, dynamic> data;

  const MinistryUpdateRequested({required this.ministryId, required this.data});

  @override
  List<Object?> get props => [ministryId, data];
}

class MinistryDeleteRequested extends MinistryEvent {
  final String ministryId;

  const MinistryDeleteRequested({required this.ministryId});

  @override
  List<Object?> get props => [ministryId];
}

class MinistryMemberAddRequested extends MinistryEvent {
  final String ministryId;
  final String memberId;
  final String? roleInMinistry;

  const MinistryMemberAddRequested({
    required this.ministryId,
    required this.memberId,
    this.roleInMinistry,
  });

  @override
  List<Object?> get props => [ministryId, memberId, roleInMinistry];
}

class MinistryMemberRemoveRequested extends MinistryEvent {
  final String ministryId;
  final String memberId;

  const MinistryMemberRemoveRequested({
    required this.ministryId,
    required this.memberId,
  });

  @override
  List<Object?> get props => [ministryId, memberId];
}

// ── States ──
abstract class MinistryState extends Equatable {
  const MinistryState();

  @override
  List<Object?> get props => [];
}

class MinistryInitial extends MinistryState {
  const MinistryInitial();
}

class MinistryLoading extends MinistryState {
  const MinistryLoading();
}

class MinistryListLoaded extends MinistryState {
  final List<Ministry> ministries;
  final int totalCount;
  final int currentPage;
  final String? activeSearch;

  const MinistryListLoaded({
    required this.ministries,
    required this.totalCount,
    this.currentPage = 1,
    this.activeSearch,
  });

  bool get hasMore => currentPage * 20 < totalCount;

  @override
  List<Object?> get props =>
      [ministries, totalCount, currentPage, activeSearch];
}

class MinistrySaved extends MinistryState {
  final Ministry ministry;
  final String message;

  const MinistrySaved({required this.ministry, required this.message});

  @override
  List<Object?> get props => [ministry, message];
}

class MinistryMemberUpdated extends MinistryState {
  final String message;

  const MinistryMemberUpdated({required this.message});

  @override
  List<Object?> get props => [message];
}

class MinistryError extends MinistryState {
  final String message;

  const MinistryError({required this.message});

  @override
  List<Object?> get props => [message];
}
