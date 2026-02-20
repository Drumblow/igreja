import 'package:equatable/equatable.dart';
import '../data/models/member_models.dart';

// ── Events ──
abstract class MemberEvent extends Equatable {
  const MemberEvent();

  @override
  List<Object?> get props => [];
}

class MembersLoadRequested extends MemberEvent {
  final int page;
  final String? search;
  final String? status;

  const MembersLoadRequested({
    this.page = 1,
    this.search,
    this.status,
  });

  @override
  List<Object?> get props => [page, search, status];
}

class MemberCreateRequested extends MemberEvent {
  final Map<String, dynamic> data;

  const MemberCreateRequested({required this.data});

  @override
  List<Object?> get props => [data];
}

class MemberUpdateRequested extends MemberEvent {
  final String memberId;
  final Map<String, dynamic> data;

  const MemberUpdateRequested({required this.memberId, required this.data});

  @override
  List<Object?> get props => [memberId, data];
}

class MemberDeleteRequested extends MemberEvent {
  final String memberId;

  const MemberDeleteRequested({required this.memberId});

  @override
  List<Object?> get props => [memberId];
}

// ── States ──
abstract class MemberState extends Equatable {
  const MemberState();

  @override
  List<Object?> get props => [];
}

class MemberInitial extends MemberState {
  const MemberInitial();
}

class MemberLoading extends MemberState {
  const MemberLoading();
}

class MemberLoaded extends MemberState {
  final List<Member> members;
  final int totalCount;
  final int currentPage;
  final String? activeSearch;
  final String? activeStatus;

  const MemberLoaded({
    required this.members,
    required this.totalCount,
    this.currentPage = 1,
    this.activeSearch,
    this.activeStatus,
  });

  bool get hasMore => currentPage * 20 < totalCount;

  @override
  List<Object?> get props =>
      [members, totalCount, currentPage, activeSearch, activeStatus];
}

class MemberSaved extends MemberState {
  final Member member;
  final String message;

  const MemberSaved({required this.member, required this.message});

  @override
  List<Object?> get props => [member, message];
}

class MemberError extends MemberState {
  final String message;

  const MemberError({required this.message});

  @override
  List<Object?> get props => [message];
}
