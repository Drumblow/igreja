import 'package:equatable/equatable.dart';
import '../data/models/family_models.dart';

// ── Events ──
abstract class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

class FamiliesLoadRequested extends FamilyEvent {
  final int page;
  final String? search;

  const FamiliesLoadRequested({this.page = 1, this.search});

  @override
  List<Object?> get props => [page, search];
}

class FamilyCreateRequested extends FamilyEvent {
  final Map<String, dynamic> data;

  const FamilyCreateRequested({required this.data});

  @override
  List<Object?> get props => [data];
}

class FamilyUpdateRequested extends FamilyEvent {
  final String familyId;
  final Map<String, dynamic> data;

  const FamilyUpdateRequested({required this.familyId, required this.data});

  @override
  List<Object?> get props => [familyId, data];
}

class FamilyDeleteRequested extends FamilyEvent {
  final String familyId;

  const FamilyDeleteRequested({required this.familyId});

  @override
  List<Object?> get props => [familyId];
}

class FamilyMemberAddRequested extends FamilyEvent {
  final String familyId;
  final String memberId;
  final String relationship;

  const FamilyMemberAddRequested({
    required this.familyId,
    required this.memberId,
    required this.relationship,
  });

  @override
  List<Object?> get props => [familyId, memberId, relationship];
}

class FamilyMemberRemoveRequested extends FamilyEvent {
  final String familyId;
  final String memberId;

  const FamilyMemberRemoveRequested({
    required this.familyId,
    required this.memberId,
  });

  @override
  List<Object?> get props => [familyId, memberId];
}

// ── States ──
abstract class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object?> get props => [];
}

class FamilyInitial extends FamilyState {
  const FamilyInitial();
}

class FamilyLoading extends FamilyState {
  const FamilyLoading();
}

class FamilyListLoaded extends FamilyState {
  final List<Family> families;
  final int totalCount;
  final int currentPage;
  final String? activeSearch;

  const FamilyListLoaded({
    required this.families,
    required this.totalCount,
    this.currentPage = 1,
    this.activeSearch,
  });

  @override
  List<Object?> get props => [families, totalCount, currentPage, activeSearch];
}

class FamilySaved extends FamilyState {
  final Family family;
  final String message;

  const FamilySaved({required this.family, required this.message});

  @override
  List<Object?> get props => [family, message];
}

class FamilyMemberUpdated extends FamilyState {
  final String message;

  const FamilyMemberUpdated({required this.message});

  @override
  List<Object?> get props => [message];
}

class FamilyError extends FamilyState {
  final String message;

  const FamilyError({required this.message});

  @override
  List<Object?> get props => [message];
}
