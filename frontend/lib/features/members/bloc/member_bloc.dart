import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../data/member_repository.dart';
import 'member_event_state.dart';

class MemberBloc extends Bloc<MemberEvent, MemberState> {
  final MemberRepository _repository;
  final CongregationContextCubit _congregationCubit;
  late final StreamSubscription<CongregationContextState> _congSub;

  MemberBloc({
    required MemberRepository repository,
    required CongregationContextCubit congregationCubit,
  })  : _repository = repository,
        _congregationCubit = congregationCubit,
        super(const MemberInitial()) {
    on<MembersLoadRequested>(_onLoadRequested);
    on<MemberCreateRequested>(_onCreateRequested);
    on<MemberUpdateRequested>(_onUpdateRequested);
    on<MemberDeleteRequested>(_onDeleteRequested);

    // Re-load members when active congregation changes
    _congSub = _congregationCubit.stream.listen((congState) {
      if (state is MemberLoaded) {
        final current = state as MemberLoaded;
        add(MembersLoadRequested(
          page: 1,
          search: current.activeSearch,
          status: current.activeStatus,
          congregationId: congState.activeCongregationId,
        ));
      }
    });
  }

  String? get _activeCongregationId =>
      _congregationCubit.state.activeCongregationId;

  @override
  Future<void> close() {
    _congSub.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    MembersLoadRequested event,
    Emitter<MemberState> emit,
  ) async {
    if (event.page == 1) emit(const MemberLoading());
    final congregationId = event.congregationId ?? _activeCongregationId;
    try {
      final result = await _repository.getMembers(
        page: event.page,
        search: event.search,
        status: event.status,
        congregationId: congregationId,
      );
      final allMembers = event.page > 1 && state is MemberLoaded
          ? [...(state as MemberLoaded).members, ...result.members]
          : result.members;
      emit(MemberLoaded(
        members: allMembers,
        totalCount: result.total,
        currentPage: event.page,
        activeSearch: event.search,
        activeStatus: event.status,
        activeCongregationId: congregationId,
      ));
    } catch (e) {
      emit(MemberError(message: e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    MemberCreateRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(const MemberLoading());
    try {
      final member = await _repository.createMember(event.data);
      emit(MemberSaved(member: member, message: 'Membro cadastrado com sucesso'));
    } catch (e) {
      emit(MemberError(message: 'Erro ao cadastrar membro: $e'));
    }
  }

  Future<void> _onUpdateRequested(
    MemberUpdateRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(const MemberLoading());
    try {
      final member = await _repository.updateMember(event.memberId, event.data);
      emit(MemberSaved(member: member, message: 'Membro atualizado com sucesso'));
    } catch (e) {
      emit(MemberError(message: 'Erro ao atualizar membro: $e'));
    }
  }

  Future<void> _onDeleteRequested(
    MemberDeleteRequested event,
    Emitter<MemberState> emit,
  ) async {
    try {
      await _repository.deleteMember(event.memberId);
      // Reload current list
      if (state is MemberLoaded) {
        final current = state as MemberLoaded;
        add(MembersLoadRequested(
          page: current.currentPage,
          search: current.activeSearch,
          status: current.activeStatus,
          congregationId: current.activeCongregationId,
        ));
      }
    } catch (e) {
      emit(MemberError(message: 'Erro ao remover membro: $e'));
    }
  }
}
