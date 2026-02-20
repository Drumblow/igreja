import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/ministry_repository.dart';
import 'ministry_event_state.dart';

class MinistryBloc extends Bloc<MinistryEvent, MinistryState> {
  final MinistryRepository repository;

  MinistryBloc({required this.repository}) : super(const MinistryInitial()) {
    on<MinistriesLoadRequested>(_onLoad);
    on<MinistryCreateRequested>(_onCreate);
    on<MinistryUpdateRequested>(_onUpdate);
    on<MinistryDeleteRequested>(_onDelete);
    on<MinistryMemberAddRequested>(_onAddMember);
    on<MinistryMemberRemoveRequested>(_onRemoveMember);
  }

  Future<void> _onLoad(
    MinistriesLoadRequested event,
    Emitter<MinistryState> emit,
  ) async {
    if (event.page == 1) emit(const MinistryLoading());
    try {
      final result = await repository.getMinistries(
        page: event.page,
        search: event.search,
        isActive: event.isActive,
      );
      final allMinistries = event.page > 1 && state is MinistryListLoaded
          ? [...(state as MinistryListLoaded).ministries, ...result.ministries]
          : result.ministries;
      emit(MinistryListLoaded(
        ministries: allMinistries,
        totalCount: result.total,
        currentPage: event.page,
        activeSearch: event.search,
      ));
    } catch (e) {
      emit(MinistryError(message: e.toString()));
    }
  }

  Future<void> _onCreate(
    MinistryCreateRequested event,
    Emitter<MinistryState> emit,
  ) async {
    emit(const MinistryLoading());
    try {
      final ministry = await repository.createMinistry(event.data);
      emit(MinistrySaved(
          ministry: ministry, message: 'Ministério criado com sucesso'));
    } catch (e) {
      emit(MinistryError(message: e.toString()));
    }
  }

  Future<void> _onUpdate(
    MinistryUpdateRequested event,
    Emitter<MinistryState> emit,
  ) async {
    emit(const MinistryLoading());
    try {
      final ministry =
          await repository.updateMinistry(event.ministryId, event.data);
      emit(MinistrySaved(
          ministry: ministry, message: 'Ministério atualizado com sucesso'));
    } catch (e) {
      emit(MinistryError(message: e.toString()));
    }
  }

  Future<void> _onDelete(
    MinistryDeleteRequested event,
    Emitter<MinistryState> emit,
  ) async {
    emit(const MinistryLoading());
    try {
      await repository.deleteMinistry(event.ministryId);
      emit(const MinistryMemberUpdated(
          message: 'Ministério removido com sucesso'));
    } catch (e) {
      emit(MinistryError(message: e.toString()));
    }
  }

  Future<void> _onAddMember(
    MinistryMemberAddRequested event,
    Emitter<MinistryState> emit,
  ) async {
    emit(const MinistryLoading());
    try {
      await repository.addMember(
        ministryId: event.ministryId,
        memberId: event.memberId,
        roleInMinistry: event.roleInMinistry,
      );
      emit(const MinistryMemberUpdated(
          message: 'Membro adicionado ao ministério'));
    } catch (e) {
      emit(MinistryError(message: e.toString()));
    }
  }

  Future<void> _onRemoveMember(
    MinistryMemberRemoveRequested event,
    Emitter<MinistryState> emit,
  ) async {
    emit(const MinistryLoading());
    try {
      await repository.removeMember(
        ministryId: event.ministryId,
        memberId: event.memberId,
      );
      emit(const MinistryMemberUpdated(
          message: 'Membro removido do ministério'));
    } catch (e) {
      emit(MinistryError(message: e.toString()));
    }
  }
}
