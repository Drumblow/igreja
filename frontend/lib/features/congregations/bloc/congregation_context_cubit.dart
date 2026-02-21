import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../data/congregation_repository.dart';
import '../data/models/congregation_models.dart';

/// State for the global congregation context
class CongregationContextState extends Equatable {
  final List<Congregation> availableCongregations;
  final Congregation? activeCongregation;
  final bool isLoading;
  final bool hasLoaded;

  const CongregationContextState({
    this.availableCongregations = const [],
    this.activeCongregation,
    this.isLoading = false,
    this.hasLoaded = false,
  });

  bool get isAllSelected => activeCongregation == null;
  bool get hasCongregations => availableCongregations.isNotEmpty;

  String get activeLabel =>
      activeCongregation?.shortName ??
      activeCongregation?.name ??
      'Geral';

  String? get activeCongregationId => activeCongregation?.id;

  CongregationContextState copyWith({
    List<Congregation>? availableCongregations,
    Congregation? Function()? activeCongregation,
    bool? isLoading,
    bool? hasLoaded,
  }) {
    return CongregationContextState(
      availableCongregations:
          availableCongregations ?? this.availableCongregations,
      activeCongregation: activeCongregation != null
          ? activeCongregation()
          : this.activeCongregation,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  @override
  List<Object?> get props =>
      [availableCongregations, activeCongregation, isLoading, hasLoaded];
}

/// Global cubit that manages which congregation is currently active
/// Injected at the app root via BlocProvider
class CongregationContextCubit extends Cubit<CongregationContextState> {
  final CongregationRepository _repository;

  CongregationContextCubit({required CongregationRepository repository})
      : _repository = repository,
        super(const CongregationContextState());

  /// Load available congregations (called after login)
  Future<void> loadCongregations() async {
    emit(state.copyWith(isLoading: true));
    try {
      final congregations = await _repository.getCongregations(isActive: true);
      emit(state.copyWith(
        availableCongregations: congregations,
        isLoading: false,
        hasLoaded: true,
      ));
    } catch (e) {
      debugPrint('Failed to load congregations: $e');
      emit(state.copyWith(
        isLoading: false,
        hasLoaded: true,
      ));
    }
  }

  /// Select a specific congregation (or null for "All")
  Future<void> selectCongregation(Congregation? congregation) async {
    emit(state.copyWith(
      activeCongregation: () => congregation,
    ));

    // Notify backend (fire-and-forget)
    try {
      await _repository.setActiveCongregation(congregation?.id);
    } catch (_) {
      // Ignore — preference is also stored locally
    }
  }

  /// Clear context (on logout)
  void clear() {
    emit(const CongregationContextState());
  }
}
