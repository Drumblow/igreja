import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/member_repository.dart';
import 'member_event_state.dart';

class MemberBloc extends Bloc<MemberEvent, MemberState> {
  final MemberRepository _repository;

  MemberBloc({required MemberRepository repository})
      : _repository = repository,
        super(const MemberInitial()) {
    on<MembersLoadRequested>(_onLoadRequested);
    on<MemberCreateRequested>(_onCreateRequested);
    on<MemberUpdateRequested>(_onUpdateRequested);
    on<MemberDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    MembersLoadRequested event,
    Emitter<MemberState> emit,
  ) async {
    emit(const MemberLoading());
    try {
      final result = await _repository.getMembers(
        page: event.page,
        search: event.search,
        status: event.status,
      );
      emit(MemberLoaded(
        members: result.members,
        totalCount: result.total,
        currentPage: event.page,
        activeSearch: event.search,
        activeStatus: event.status,
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
        ));
      }
    } catch (e) {
      emit(MemberError(message: 'Erro ao remover membro: $e'));
    }
  }
}
