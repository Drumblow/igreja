import 'package:equatable/equatable.dart';

// ==========================================
// Helper parsers
// ==========================================

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

double _parseDecimal(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

// ==========================================
// Asset Category
// ==========================================

class AssetCategory extends Equatable {
  final String id;
  final String? parentId;
  final String name;
  final int? usefulLifeMonths;
  final double? depreciationRate;
  final int? assetsCount;
  final DateTime? createdAt;

  const AssetCategory({
    required this.id,
    this.parentId,
    required this.name,
    this.usefulLifeMonths,
    this.depreciationRate,
    this.assetsCount,
    this.createdAt,
  });

  factory AssetCategory.fromJson(Map<String, dynamic> json) {
    return AssetCategory(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String? ?? '',
      usefulLifeMonths: json['useful_life_months'] as int?,
      depreciationRate: json['depreciation_rate'] != null
          ? _parseDecimal(json['depreciation_rate'])
          : null,
      assetsCount: json['assets_count'] as int?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (parentId != null) 'parent_id': parentId,
        if (usefulLifeMonths != null) 'useful_life_months': usefulLifeMonths,
        if (depreciationRate != null) 'depreciation_rate': depreciationRate,
      };

  @override
  List<Object?> get props => [id];
}

// ==========================================
// Asset
// ==========================================

class Asset extends Equatable {
  final String id;
  final String assetCode;
  final String description;
  final String? categoryId;
  final String? categoryName;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? acquisitionDate;
  final double? acquisitionValue;
  final String? acquisitionType;
  final String? donorMemberId;
  final String? invoiceUrl;
  final double? currentValue;
  final double? residualValue;
  final double? accumulatedDepreciation;
  final String? location;
  final String condition;
  final String status;
  final String? statusDate;
  final String? statusReason;
  final String? notes;
  final String? congregationId;
  final String? congregationName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Asset({
    required this.id,
    required this.assetCode,
    required this.description,
    this.categoryId,
    this.categoryName,
    this.brand,
    this.model,
    this.serialNumber,
    this.acquisitionDate,
    this.acquisitionValue,
    this.acquisitionType,
    this.donorMemberId,
    this.invoiceUrl,
    this.currentValue,
    this.residualValue,
    this.accumulatedDepreciation,
    this.location,
    this.condition = 'bom',
    this.status = 'ativo',
    this.statusDate,
    this.statusReason,
    this.notes,
    this.congregationId,
    this.congregationName,
    this.createdAt,
    this.updatedAt,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      assetCode: json['asset_code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serial_number'] as String?,
      acquisitionDate: json['acquisition_date'] as String?,
      acquisitionValue: json['acquisition_value'] != null
          ? _parseDecimal(json['acquisition_value'])
          : null,
      acquisitionType: json['acquisition_type'] as String?,
      donorMemberId: json['donor_member_id'] as String?,
      invoiceUrl: json['invoice_url'] as String?,
      currentValue: json['current_value'] != null
          ? _parseDecimal(json['current_value'])
          : null,
      residualValue: json['residual_value'] != null
          ? _parseDecimal(json['residual_value'])
          : null,
      accumulatedDepreciation: json['accumulated_depreciation'] != null
          ? _parseDecimal(json['accumulated_depreciation'])
          : null,
      location: json['location'] as String?,
      condition: json['condition'] as String? ?? 'bom',
      status: json['status'] as String? ?? 'ativo',
      statusDate: json['status_date'] as String?,
      statusReason: json['status_reason'] as String?,
      notes: json['notes'] as String?,
      congregationId: json['congregation_id'] as String?,
      congregationName: json['congregation_name'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  String get conditionLabel {
    switch (condition) {
      case 'novo':
        return 'Novo';
      case 'bom':
        return 'Bom';
      case 'regular':
        return 'Regular';
      case 'ruim':
        return 'Ruim';
      case 'inservivel':
        return 'Inservível';
      default:
        return condition;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'ativo':
        return 'Ativo';
      case 'em_manutencao':
        return 'Em Manutenção';
      case 'baixado':
        return 'Baixado';
      case 'cedido':
        return 'Cedido';
      case 'alienado':
        return 'Alienado';
      default:
        return status;
    }
  }

  String get acquisitionTypeLabel {
    switch (acquisitionType) {
      case 'compra':
        return 'Compra';
      case 'doacao':
        return 'Doação';
      case 'construcao':
        return 'Construção';
      case 'outro':
        return 'Outro';
      default:
        return acquisitionType ?? '';
    }
  }

  @override
  List<Object?> get props => [id];
}

// ==========================================
// Maintenance
// ==========================================

class Maintenance extends Equatable {
  final String id;
  final String assetId;
  final String? assetCode;
  final String? assetDescription;
  final String maintenanceType;
  final String description;
  final String? supplierName;
  final double? cost;
  final String? scheduledDate;
  final String? executionDate;
  final String? nextMaintenanceDate;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  const Maintenance({
    required this.id,
    required this.assetId,
    this.assetCode,
    this.assetDescription,
    required this.maintenanceType,
    required this.description,
    this.supplierName,
    this.cost,
    this.scheduledDate,
    this.executionDate,
    this.nextMaintenanceDate,
    this.status = 'agendada',
    this.notes,
    this.createdAt,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    return Maintenance(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      assetCode: json['asset_code'] as String?,
      assetDescription: json['asset_description'] as String?,
      maintenanceType: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      supplierName: json['supplier_name'] as String?,
      cost: json['cost'] != null ? _parseDecimal(json['cost']) : null,
      scheduledDate: json['scheduled_date'] as String?,
      executionDate: json['execution_date'] as String?,
      nextMaintenanceDate: json['next_maintenance_date'] as String?,
      status: json['status'] as String? ?? 'agendada',
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  String get typeLabel =>
      maintenanceType == 'preventiva' ? 'Preventiva' : 'Corretiva';

  String get statusLabel {
    switch (status) {
      case 'agendada':
        return 'Agendada';
      case 'em_andamento':
        return 'Em Andamento';
      case 'concluida':
        return 'Concluída';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [id];
}

// ==========================================
// Inventory
// ==========================================

class Inventory extends Equatable {
  final String id;
  final String name;
  final String referenceDate;
  final String status;
  final int? totalItems;
  final int? foundItems;
  final int? missingItems;
  final int? divergentItems;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const Inventory({
    required this.id,
    required this.name,
    required this.referenceDate,
    this.status = 'aberto',
    this.totalItems,
    this.foundItems,
    this.missingItems,
    this.divergentItems,
    this.notes,
    this.createdAt,
    this.completedAt,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      referenceDate: json['reference_date'] as String? ?? '',
      status: json['status'] as String? ?? 'aberto',
      totalItems: json['total_items'] as int?,
      foundItems: json['found_items'] as int?,
      missingItems: json['missing_items'] as int?,
      divergentItems: json['divergent_items'] as int?,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      completedAt: _parseDate(json['completed_at']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'aberto':
        return 'Aberto';
      case 'em_andamento':
        return 'Em Andamento';
      case 'fechado':
        return 'Fechado';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [id];
}

// ==========================================
// Inventory Item
// ==========================================

class InventoryItem extends Equatable {
  final String id;
  final String inventoryId;
  final String assetId;
  final String? assetCode;
  final String? assetDescription;
  final String? assetLocation;
  final String? registeredCondition;
  final String status;
  final String? observedCondition;
  final String? notes;
  final DateTime? checkedAt;

  const InventoryItem({
    required this.id,
    required this.inventoryId,
    required this.assetId,
    this.assetCode,
    this.assetDescription,
    this.assetLocation,
    this.registeredCondition,
    this.status = 'pendente',
    this.observedCondition,
    this.notes,
    this.checkedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String,
      assetId: json['asset_id'] as String,
      assetCode: json['asset_code'] as String?,
      assetDescription: json['asset_description'] as String?,
      assetLocation: json['asset_location'] as String?,
      registeredCondition: json['registered_condition'] as String?,
      status: json['status'] as String? ?? 'pendente',
      observedCondition: json['observed_condition'] as String?,
      notes: json['notes'] as String?,
      checkedAt: _parseDate(json['checked_at']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'encontrado':
        return 'Encontrado';
      case 'nao_encontrado':
        return 'Não Encontrado';
      case 'divergencia':
        return 'Divergência';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [id];
}

// ==========================================
// Asset Loan
// ==========================================

class AssetLoan extends Equatable {
  final String id;
  final String assetId;
  final String? assetCode;
  final String? assetDescription;
  final String borrowerMemberId;
  final String? borrowerName;
  final String loanDate;
  final String expectedReturnDate;
  final String? actualReturnDate;
  final String conditionOut;
  final String? conditionIn;
  final String? notes;
  final DateTime? createdAt;

  const AssetLoan({
    required this.id,
    required this.assetId,
    this.assetCode,
    this.assetDescription,
    required this.borrowerMemberId,
    this.borrowerName,
    required this.loanDate,
    required this.expectedReturnDate,
    this.actualReturnDate,
    required this.conditionOut,
    this.conditionIn,
    this.notes,
    this.createdAt,
  });

  factory AssetLoan.fromJson(Map<String, dynamic> json) {
    return AssetLoan(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      assetCode: json['asset_code'] as String?,
      assetDescription: json['asset_description'] as String?,
      borrowerMemberId: json['borrower_member_id'] as String,
      borrowerName: json['borrower_name'] as String?,
      loanDate: json['loan_date'] as String? ?? '',
      expectedReturnDate: json['expected_return_date'] as String? ?? '',
      actualReturnDate: json['actual_return_date'] as String?,
      conditionOut: json['condition_out'] as String? ?? '',
      conditionIn: json['condition_in'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  bool get isReturned => actualReturnDate != null;

  bool get isOverdue {
    if (isReturned) return false;
    final expected = DateTime.tryParse(expectedReturnDate);
    if (expected == null) return false;
    return DateTime.now().isAfter(expected);
  }

  String get statusLabel {
    if (isReturned) return 'Devolvido';
    if (isOverdue) return 'Atrasado';
    return 'Em Andamento';
  }

  @override
  List<Object?> get props => [id];
}
