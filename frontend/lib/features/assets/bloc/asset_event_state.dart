import 'package:equatable/equatable.dart';
import '../data/models/asset_models.dart';

// ══════════════════════════════════════════
// Events
// ══════════════════════════════════════════

abstract class AssetEvent extends Equatable {
  const AssetEvent();
  @override
  List<Object?> get props => [];
}

/// Load asset list
class AssetsLoadRequested extends AssetEvent {
  final int page;
  final String? search;
  final String? categoryId;
  final String? status;
  final String? condition;
  final String? congregationId;

  const AssetsLoadRequested({
    this.page = 1,
    this.search,
    this.categoryId,
    this.status,
    this.condition,
    this.congregationId,
  });

  @override
  List<Object?> get props => [page, search, categoryId, status, condition, congregationId];
}

/// Create asset
class AssetCreateRequested extends AssetEvent {
  final Map<String, dynamic> data;
  const AssetCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

/// Update asset
class AssetUpdateRequested extends AssetEvent {
  final String assetId;
  final Map<String, dynamic> data;
  const AssetUpdateRequested({required this.assetId, required this.data});
  @override
  List<Object?> get props => [assetId, data];
}

/// Delete asset
class AssetDeleteRequested extends AssetEvent {
  final String assetId;
  const AssetDeleteRequested({required this.assetId});
  @override
  List<Object?> get props => [assetId];
}

/// Load categories
class AssetCategoriesLoadRequested extends AssetEvent {
  final String? search;
  const AssetCategoriesLoadRequested({this.search});
  @override
  List<Object?> get props => [search];
}

/// Create category
class AssetCategoryCreateRequested extends AssetEvent {
  final Map<String, dynamic> data;
  const AssetCategoryCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

/// Load maintenances
class MaintenancesLoadRequested extends AssetEvent {
  final int page;
  final String? assetId;
  final String? status;
  final String? type;

  const MaintenancesLoadRequested({
    this.page = 1,
    this.assetId,
    this.status,
    this.type,
  });

  @override
  List<Object?> get props => [page, assetId, status, type];
}

/// Create maintenance
class MaintenanceCreateRequested extends AssetEvent {
  final Map<String, dynamic> data;
  const MaintenanceCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

/// Update maintenance
class MaintenanceUpdateRequested extends AssetEvent {
  final String maintenanceId;
  final Map<String, dynamic> data;
  const MaintenanceUpdateRequested({
    required this.maintenanceId,
    required this.data,
  });
  @override
  List<Object?> get props => [maintenanceId, data];
}

/// Load inventories
class InventoriesLoadRequested extends AssetEvent {
  final int page;
  const InventoriesLoadRequested({this.page = 1});
  @override
  List<Object?> get props => [page];
}

/// Create inventory
class InventoryCreateRequested extends AssetEvent {
  final Map<String, dynamic> data;
  const InventoryCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

/// Close inventory
class InventoryCloseRequested extends AssetEvent {
  final String inventoryId;
  const InventoryCloseRequested({required this.inventoryId});
  @override
  List<Object?> get props => [inventoryId];
}

/// Load loans
class AssetLoansLoadRequested extends AssetEvent {
  final int page;
  final String? status;

  const AssetLoansLoadRequested({this.page = 1, this.status});

  @override
  List<Object?> get props => [page, status];
}

/// Create loan
class AssetLoanCreateRequested extends AssetEvent {
  final Map<String, dynamic> data;
  const AssetLoanCreateRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

/// Return loan
class AssetLoanReturnRequested extends AssetEvent {
  final String loanId;
  final Map<String, dynamic> data;
  const AssetLoanReturnRequested({required this.loanId, required this.data});
  @override
  List<Object?> get props => [loanId, data];
}

// ══════════════════════════════════════════
// States
// ══════════════════════════════════════════

abstract class AssetState extends Equatable {
  const AssetState();
  @override
  List<Object?> get props => [];
}

class AssetInitial extends AssetState {
  const AssetInitial();
}

class AssetLoading extends AssetState {
  const AssetLoading();
}

class AssetListLoaded extends AssetState {
  final List<Asset> assets;
  final int totalCount;
  final int currentPage;
  final String? activeSearch;
  final String? activeStatus;
  final String? activeCondition;

  const AssetListLoaded({
    required this.assets,
    required this.totalCount,
    this.currentPage = 1,
    this.activeSearch,
    this.activeStatus,
    this.activeCondition,
  });

  bool get hasMore => currentPage * 20 < totalCount;

  @override
  List<Object?> get props =>
      [assets, totalCount, currentPage, activeSearch, activeStatus, activeCondition];
}

class AssetCategoriesLoaded extends AssetState {
  final List<AssetCategory> categories;
  final int totalCount;

  const AssetCategoriesLoaded({
    required this.categories,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [categories, totalCount];
}

class MaintenancesLoaded extends AssetState {
  final List<Maintenance> maintenances;
  final int totalCount;
  final int currentPage;

  const MaintenancesLoaded({
    required this.maintenances,
    required this.totalCount,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [maintenances, totalCount, currentPage];
}

class InventoriesLoaded extends AssetState {
  final List<Inventory> inventories;
  final int totalCount;
  final int currentPage;

  const InventoriesLoaded({
    required this.inventories,
    required this.totalCount,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [inventories, totalCount, currentPage];
}

class AssetLoansLoaded extends AssetState {
  final List<AssetLoan> loans;
  final int totalCount;
  final int currentPage;

  const AssetLoansLoaded({
    required this.loans,
    required this.totalCount,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [loans, totalCount, currentPage];
}

class AssetSaved extends AssetState {
  final String message;
  const AssetSaved({required this.message});
  @override
  List<Object?> get props => [message];
}

class AssetError extends AssetState {
  final String message;
  const AssetError({required this.message});
  @override
  List<Object?> get props => [message];
}
