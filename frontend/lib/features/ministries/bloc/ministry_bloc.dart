import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../congregations/bloc/congregation_context_cubit.dart';
import '../data/ministry_repository.dart';
import 'ministry_event_state.dart';

class MinistryBloc extends Bloc<MinistryEvent, MinistryState> {
  final MinistryRepository repository;
  final CongregationContextCubit _congregationCubit;
  late final StreamSubscription<CongregationContextState> _congSub;

  MinistryBloc({
    required this.repository,
    required CongregationContextCubit congregationCubit,
  })  : _congregationCubit = congregationCubit,
        super(const MinistryInitial()) {
    on<MinistriesLoadRequested>(_onLoad);
    on<MinistryCreateRequested>(_onCreate);
    on<MinistryUpdateRequested>(_onUpdate);
    on<MinistryDeleteRequested>(_onDelete);
    on<MinistryMemberAddRequested>(_onAddMember);
    on<MinistryMemberRemoveRequested>(_onRemoveMember);

    // Re-load ministries when active congregation changes
    _congSub = _congregationCubit.stream.listen((congState) {
      if (state is MinistryListLoaded) {
        final current = state as MinistryListLoaded;
        add(MinistriesLoadRequested(
          page: 1,
          search: current.activeSearch,
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

  Future<void> _onLoad(
    MinistriesLoadRequested event,
    Emitter<MinistryState> emit,
  ) async {
    if (event.page == 1) emit(const MinistryLoading());
    final congregationId = event.congregationId ?? _activeCongregationId;
    try {
      final result = await repository.getMinistries(
        page: event.page,
        search: event.search,
        isActive: event.isActive,
        congregationId: congregationId,
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
