import '../../../core/network/api_client.dart';
import 'models/asset_models.dart';

class AssetRepository {
  final ApiClient _apiClient;

  AssetRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ==========================================
  // Asset Categories
  // ==========================================

  Future<({List<AssetCategory> items, int total})> getCategories({
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _apiClient.dio.get(
      '/v1/assets/categories',
      queryParameters: params,
    );
    final data = response.data;
    final items = (data['data'] as List)
        .map((j) => AssetCategory.fromJson(j as Map<String, dynamic>))
        .toList();
    final total =
        (data['meta'] as Map<String, dynamic>?)?['total'] as int? ??
            items.length;
    return (items: items, total: total);
  }

  Future<AssetCategory> createCategory(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      '/v1/assets/categories',
      data: data,
    );
    return AssetCategory.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<AssetCategory> updateCategory(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.dio.put(
      '/v1/assets/categories/$id',
      data: data,
    );
    return AssetCategory.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  // ==========================================
  // Assets
  // ==========================================

  Future<({List<Asset> items, int total})> getAssets({
    int page = 1,
    int perPage = 20,
    String? search,
    String? categoryId,
    String? status,
    String? condition,
    String? location,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['category_id'] = categoryId;
    if (status != null) params['status'] = status;
    if (condition != null) params['condition'] = condition;
    if (location != null) params['location'] = location;

    final response = await _apiClient.dio.get(
      '/v1/assets',
      queryParameters: params,
    );
    final data = response.data;
    final items = (data['data'] as List)
        .map((j) => Asset.fromJson(j as Map<String, dynamic>))
        .toList();
    final total =
        (data['meta'] as Map<String, dynamic>?)?['total'] as int? ??
            items.length;
    return (items: items, total: total);
  }

  Future<Asset> getAsset(String id) async {
    final response = await _apiClient.dio.get('/v1/assets/$id');
    return Asset.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Asset> createAsset(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/v1/assets', data: data);
    return Asset.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Asset> updateAsset(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/v1/assets/$id', data: data);
    return Asset.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAsset(String id) async {
    await _apiClient.dio.delete('/v1/assets/$id');
  }

  // ==========================================
  // Maintenances
  // ==========================================

  Future<({List<Maintenance> items, int total})> getMaintenances({
    int page = 1,
    int perPage = 20,
    String? assetId,
    String? status,
    String? type,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (assetId != null) params['asset_id'] = assetId;
    if (status != null) params['status'] = status;
    if (type != null) params['type'] = type;

    final response = await _apiClient.dio.get(
      '/v1/assets/maintenances',
      queryParameters: params,
    );
    final data = response.data;
    final items = (data['data'] as List)
        .map((j) => Maintenance.fromJson(j as Map<String, dynamic>))
        .toList();
    final total =
        (data['meta'] as Map<String, dynamic>?)?['total'] as int? ??
            items.length;
    return (items: items, total: total);
  }

  Future<Maintenance> createMaintenance(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      '/v1/assets/maintenances',
      data: data,
    );
    return Maintenance.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Maintenance> updateMaintenance(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.dio.put(
      '/v1/assets/maintenances/$id',
      data: data,
    );
    return Maintenance.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  // ==========================================
  // Inventories
  // ==========================================

  Future<({List<Inventory> items, int total})> getInventories({
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};

    final response = await _apiClient.dio.get(
      '/v1/assets/inventories',
      queryParameters: params,
    );
    final data = response.data;
    final items = (data['data'] as List)
        .map((j) => Inventory.fromJson(j as Map<String, dynamic>))
        .toList();
    final total =
        (data['meta'] as Map<String, dynamic>?)?['total'] as int? ??
            items.length;
    return (items: items, total: total);
  }

  Future<({Inventory inventory, List<InventoryItem> inventoryItems})>
      getInventory(String id) async {
    final response = await _apiClient.dio.get('/v1/assets/inventories/$id');
    final respData = response.data['data'] as Map<String, dynamic>;
    final inventory = Inventory.fromJson(respData);
    final itemsList = (respData['items'] as List?)
            ?.map((j) => InventoryItem.fromJson(j as Map<String, dynamic>))
            .toList() ??
        [];
    return (inventory: inventory, inventoryItems: itemsList);
  }

  Future<Inventory> createInventory(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      '/v1/assets/inventories',
      data: data,
    );
    return Inventory.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<InventoryItem> updateInventoryItem(
    String inventoryId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.dio.put(
      '/v1/assets/inventories/$inventoryId/items/$itemId',
      data: data,
    );
    return InventoryItem.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Inventory> closeInventory(String id) async {
    final response = await _apiClient.dio.post(
      '/v1/assets/inventories/$id/close',
    );
    return Inventory.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  // ==========================================
  // Asset Loans
  // ==========================================

  Future<({List<AssetLoan> items, int total})> getLoans({
    int page = 1,
    int perPage = 20,
    String? status,
    String? assetId,
    String? borrowerMemberId,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (status != null) params['status'] = status;
    if (assetId != null) params['asset_id'] = assetId;
    if (borrowerMemberId != null) {
      params['borrower_member_id'] = borrowerMemberId;
    }

    final response = await _apiClient.dio.get(
      '/v1/assets/loans',
      queryParameters: params,
    );
    final data = response.data;
    final items = (data['data'] as List)
        .map((j) => AssetLoan.fromJson(j as Map<String, dynamic>))
        .toList();
    final total =
        (data['meta'] as Map<String, dynamic>?)?['total'] as int? ??
            items.length;
    return (items: items, total: total);
  }

  Future<AssetLoan> createLoan(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post(
      '/v1/assets/loans',
      data: data,
    );
    return AssetLoan.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<AssetLoan> returnLoan(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put(
      '/v1/assets/loans/$id/return',
      data: data,
    );
    return AssetLoan.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
