import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/asset_repository.dart';
import 'asset_event_state.dart';

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  final AssetRepository _repository;

  AssetBloc({required AssetRepository repository})
      : _repository = repository,
        super(const AssetInitial()) {
    on<AssetsLoadRequested>(_onAssetsLoadRequested);
    on<AssetCreateRequested>(_onAssetCreateRequested);
    on<AssetUpdateRequested>(_onAssetUpdateRequested);
    on<AssetDeleteRequested>(_onAssetDeleteRequested);
    on<AssetCategoriesLoadRequested>(_onCategoriesLoadRequested);
    on<AssetCategoryCreateRequested>(_onCategoryCreateRequested);
    on<MaintenancesLoadRequested>(_onMaintenancesLoadRequested);
    on<MaintenanceCreateRequested>(_onMaintenanceCreateRequested);
    on<MaintenanceUpdateRequested>(_onMaintenanceUpdateRequested);
    on<InventoriesLoadRequested>(_onInventoriesLoadRequested);
    on<InventoryCreateRequested>(_onInventoryCreateRequested);
    on<InventoryCloseRequested>(_onInventoryCloseRequested);
    on<AssetLoansLoadRequested>(_onLoansLoadRequested);
    on<AssetLoanCreateRequested>(_onLoanCreateRequested);
    on<AssetLoanReturnRequested>(_onLoanReturnRequested);
  }

  Future<void> _onAssetsLoadRequested(
    AssetsLoadRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      final result = await _repository.getAssets(
        page: event.page,
        search: event.search,
        categoryId: event.categoryId,
        status: event.status,
        condition: event.condition,
      );
      emit(AssetListLoaded(
        assets: result.items,
        totalCount: result.total,
        currentPage: event.page,
        activeSearch: event.search,
        activeStatus: event.status,
        activeCondition: event.condition,
      ));
    } catch (e) {
      emit(AssetError(message: e.toString()));
    }
  }

  Future<void> _onAssetCreateRequested(
    AssetCreateRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      await _repository.createAsset(event.data);
      emit(const AssetSaved(message: 'Bem cadastrado com sucesso'));
    } catch (e) {
      emit(AssetError(message: 'Erro ao cadastrar bem: $e'));
    }
  }

  Future<void> _onAssetUpdateRequested(
    AssetUpdateRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      await _repository.updateAsset(event.assetId, event.data);
      emit(const AssetSaved(message: 'Bem atualizado com sucesso'));
    } catch (e) {
      emit(AssetError(message: 'Erro ao atualizar bem: $e'));
    }
  }

  Future<void> _onAssetDeleteRequested(
    AssetDeleteRequested event,
    Emitter<AssetState> emit,
  ) async {
    try {
      await _repository.deleteAsset(event.assetId);
      emit(const AssetSaved(message: 'Bem baixado com sucesso'));
    } catch (e) {
      emit(AssetError(message: 'Erro ao baixar bem: $e'));
    }
  }

  Future<void> _onCategoriesLoadRequested(
    AssetCategoriesLoadRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      final result = await _repository.getCategories(search: event.search);
      emit(AssetCategoriesLoaded(
        categories: result.items,
        totalCount: result.total,
      ));
    } catch (e) {
      emit(AssetError(message: e.toString()));
    }
  }

  Future<void> _onCategoryCreateRequested(
    AssetCategoryCreateRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      await _repository.createCategory(event.data);
      emit(const AssetSaved(message: 'Categoria criada com sucesso'));
    } catch (e) {
      emit(AssetError(message: 'Erro ao criar categoria: $e'));
    }
  }

  Future<void> _onMaintenancesLoadRequested(
    MaintenancesLoadRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      final result = await _repository.getMaintenances(
        page: event.page,
        assetId: event.assetId,
        status: event.status,
        type: event.type,
      );
      emit(MaintenancesLoaded(
        maintenances: result.items,
        totalCount: result.total,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(AssetError(message: e.toString()));
    }
  }

  Future<void> _onMaintenanceCreateRequested(
    MaintenanceCreateRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      await _repository.createMaintenance(event.data);
      emit(const AssetSaved(message: 'Manutenção registrada com sucesso'));
    } catch (e) {
      emit(AssetError(message: 'Erro ao registrar manutenção: $e'));
    }
  }

  Future<void> _onMaintenanceUpdateRequested(
    MaintenanceUpdateRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      await _repository.updateMaintenance(event.maintenanceId, event.data);
      emit(const AssetSaved(message: 'Manutenção atualizada com sucesso'));
    } catch (e) {
      emit(AssetError(message: 'Erro ao atualizar manutenção: $e'));
    }
  }

  Future<void> _onInventoriesLoadRequested(
    InventoriesLoadRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      final result = await _repository.getInventories(page: event.page);
      emit(InventoriesLoaded(
        inventories: result.items,
        totalCount: result.total,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(AssetError(message: e.toString()));
    }
  }

  Future<void> _onInventoryCreateRequested(
    InventoryCreateRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      await _repository.createInventory(event.data);
      emit(const AssetSaved(message: 'Inventário criado com sucesso'));
    } catch (e) {
      emit(AssetError(message: 'Erro ao criar inventário: $e'));
    }
  }

  Future<void> _onInventoryCloseRequested(
    InventoryCloseRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      await _repository.closeInventory(event.inventoryId);
      emit(const AssetSaved(message: 'Inventário fechado com sucesso'));
    } catch (e) {
      emit(AssetError(message: 'Erro ao fechar inventário: $e'));
    }
  }

  Future<void> _onLoansLoadRequested(
    AssetLoansLoadRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      final result = await _repository.getLoans(
        page: event.page,
        status: event.status,
      );
      emit(AssetLoansLoaded(
        loans: result.items,
        totalCount: result.total,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(AssetError(message: e.toString()));
    }
  }

  Future<void> _onLoanCreateRequested(
    AssetLoanCreateRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      await _repository.createLoan(event.data);
      emit(const AssetSaved(message: 'Empréstimo registrado com sucesso'));
    } catch (e) {
      emit(AssetError(message: 'Erro ao registrar empréstimo: $e'));
    }
  }

  Future<void> _onLoanReturnRequested(
    AssetLoanReturnRequested event,
    Emitter<AssetState> emit,
  ) async {
    emit(const AssetLoading());
    try {
      await _repository.returnLoan(event.loanId, event.data);
      emit(const AssetSaved(message: 'Devolução registrada com sucesso'));
    } catch (e) {
      emit(AssetError(message: 'Erro ao registrar devolução: $e'));
    }
  }
}
