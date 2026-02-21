import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/congregation_repository.dart';
import 'congregation_event_state.dart';

class CongregationBloc extends Bloc<CongregationEvent, CongregationState> {
  final CongregationRepository repository;

  CongregationBloc({required this.repository})
      : super(const CongregationInitial()) {
    on<CongregationsLoadRequested>(_onLoad);
    on<CongregationCreateRequested>(_onCreate);
    on<CongregationUpdateRequested>(_onUpdate);
    on<CongregationDeactivateRequested>(_onDeactivate);
    on<CongregationAssignMembersRequested>(_onAssignMembers);
  }

  Future<void> _onLoad(
    CongregationsLoadRequested event,
    Emitter<CongregationState> emit,
  ) async {
    emit(const CongregationLoading());
    try {
      final congregations = await repository.getCongregations(
        isActive: event.isActive,
        type: event.type,
      );
      emit(CongregationListLoaded(congregations: congregations));
    } catch (e) {
      emit(CongregationError(message: e.toString()));
    }
  }

  Future<void> _onCreate(
    CongregationCreateRequested event,
    Emitter<CongregationState> emit,
  ) async {
    emit(const CongregationLoading());
    try {
      final congregation = await repository.createCongregation(event.data);
      emit(CongregationSaved(
        congregation: congregation,
        message: 'Congregação criada com sucesso',
      ));
    } catch (e) {
      emit(CongregationError(message: e.toString()));
    }
  }

  Future<void> _onUpdate(
    CongregationUpdateRequested event,
    Emitter<CongregationState> emit,
  ) async {
    emit(const CongregationLoading());
    try {
      final congregation = await repository.updateCongregation(
        event.congregationId,
        event.data,
      );
      emit(CongregationSaved(
        congregation: congregation,
        message: 'Congregação atualizada com sucesso',
      ));
    } catch (e) {
      emit(CongregationError(message: e.toString()));
    }
  }

  Future<void> _onDeactivate(
    CongregationDeactivateRequested event,
    Emitter<CongregationState> emit,
  ) async {
    emit(const CongregationLoading());
    try {
      await repository.deactivateCongregation(event.congregationId);
      emit(const CongregationDeleted(
        message: 'Congregação desativada com sucesso',
      ));
    } catch (e) {
      emit(CongregationError(message: e.toString()));
    }
  }

  Future<void> _onAssignMembers(
    CongregationAssignMembersRequested event,
    Emitter<CongregationState> emit,
  ) async {
    emit(const CongregationLoading());
    try {
      final result = await repository.assignMembers(
        congregationId: event.congregationId,
        memberIds: event.memberIds,
        overwrite: event.overwrite,
      );
      emit(CongregationMembersAssigned(
        result: result,
        message: '${result.assigned} membros associados',
      ));
    } catch (e) {
      emit(CongregationError(message: e.toString()));
    }
  }
}
