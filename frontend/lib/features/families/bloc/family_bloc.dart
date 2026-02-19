import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/family_repository.dart';
import 'family_event_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository _repository;

  FamilyBloc({required FamilyRepository repository})
      : _repository = repository,
        super(const FamilyInitial()) {
    on<FamiliesLoadRequested>(_onLoadRequested);
    on<FamilyCreateRequested>(_onCreateRequested);
    on<FamilyUpdateRequested>(_onUpdateRequested);
    on<FamilyDeleteRequested>(_onDeleteRequested);
    on<FamilyMemberAddRequested>(_onAddMember);
    on<FamilyMemberRemoveRequested>(_onRemoveMember);
  }

  Future<void> _onLoadRequested(
    FamiliesLoadRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyLoading());
    try {
      final result = await _repository.getFamilies(
        page: event.page,
        search: event.search,
      );
      emit(FamilyListLoaded(
        families: result.families,
        totalCount: result.total,
        currentPage: event.page,
        activeSearch: event.search,
      ));
    } catch (e) {
      emit(FamilyError(message: e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    FamilyCreateRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyLoading());
    try {
      final family = await _repository.createFamily(event.data);
      emit(FamilySaved(family: family, message: 'Família criada com sucesso'));
    } catch (e) {
      emit(FamilyError(message: 'Erro ao criar família: $e'));
    }
  }

  Future<void> _onUpdateRequested(
    FamilyUpdateRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(const FamilyLoading());
    try {
      final family = await _repository.updateFamily(event.familyId, event.data);
      emit(FamilySaved(
          family: family, message: 'Família atualizada com sucesso'));
    } catch (e) {
      emit(FamilyError(message: 'Erro ao atualizar família: $e'));
    }
  }

  Future<void> _onDeleteRequested(
    FamilyDeleteRequested event,
    Emitter<FamilyState> emit,
  ) async {
    try {
      await _repository.deleteFamily(event.familyId);
      if (state is FamilyListLoaded) {
        final current = state as FamilyListLoaded;
        add(FamiliesLoadRequested(
          page: current.currentPage,
          search: current.activeSearch,
        ));
      }
    } catch (e) {
      emit(FamilyError(message: 'Erro ao remover família: $e'));
    }
  }

  Future<void> _onAddMember(
    FamilyMemberAddRequested event,
    Emitter<FamilyState> emit,
  ) async {
    try {
      await _repository.addMember(
        familyId: event.familyId,
        memberId: event.memberId,
        relationship: event.relationship,
      );
      emit(const FamilyMemberUpdated(
          message: 'Membro adicionado à família'));
    } catch (e) {
      emit(FamilyError(message: 'Erro ao adicionar membro: $e'));
    }
  }

  Future<void> _onRemoveMember(
    FamilyMemberRemoveRequested event,
    Emitter<FamilyState> emit,
  ) async {
    try {
      await _repository.removeMember(
        familyId: event.familyId,
        memberId: event.memberId,
      );
      emit(const FamilyMemberUpdated(
          message: 'Membro removido da família'));
    } catch (e) {
      emit(FamilyError(message: 'Erro ao remover membro: $e'));
    }
  }
}
