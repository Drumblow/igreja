import '../../../core/network/api_client.dart';
import 'models/financial_models.dart';

class FinancialRepository {
  final ApiClient _apiClient;

  FinancialRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ==========================================
  // Account Plans
  // ==========================================

  Future<({List<AccountPlan> items, int total})> getAccountPlans({
    int page = 1,
    int perPage = 50,
    String? search,
    String? type,
    bool? isActive,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (type != null) params['type'] = type;
    if (isActive != null) params['is_active'] = isActive;

    final response = await _apiClient.dio.get('/v1/financial/account-plans', queryParameters: params);
    final data = response.data;
    final items = (data['data'] as List).map((j) => AccountPlan.fromJson(j as Map<String, dynamic>)).toList();
    final total = (data['meta'] as Map<String, dynamic>?)?['total'] as int? ?? items.length;
    return (items: items, total: total);
  }

  Future<AccountPlan> createAccountPlan(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/v1/financial/account-plans', data: data);
    return AccountPlan.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AccountPlan> updateAccountPlan(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/v1/financial/account-plans/$id', data: data);
    return AccountPlan.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // ==========================================
  // Bank Accounts
  // ==========================================

  Future<({List<BankAccount> items, int total})> getBankAccounts({
    int page = 1,
    int perPage = 50,
    String? search,
    bool? isActive,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (isActive != null) params['is_active'] = isActive;

    final response = await _apiClient.dio.get('/v1/financial/bank-accounts', queryParameters: params);
    final data = response.data;
    final items = (data['data'] as List).map((j) => BankAccount.fromJson(j as Map<String, dynamic>)).toList();
    final total = (data['meta'] as Map<String, dynamic>?)?['total'] as int? ?? items.length;
    return (items: items, total: total);
  }

  Future<BankAccount> createBankAccount(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/v1/financial/bank-accounts', data: data);
    return BankAccount.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BankAccount> updateBankAccount(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/v1/financial/bank-accounts/$id', data: data);
    return BankAccount.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // ==========================================
  // Campaigns
  // ==========================================

  Future<({List<Campaign> items, int total})> getCampaigns({
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) params['search'] = search;

    final response = await _apiClient.dio.get('/v1/financial/campaigns', queryParameters: params);
    final data = response.data;
    final items = (data['data'] as List).map((j) => Campaign.fromJson(j as Map<String, dynamic>)).toList();
    final total = (data['meta'] as Map<String, dynamic>?)?['total'] as int? ?? items.length;
    return (items: items, total: total);
  }

  Future<Campaign> getCampaign(String id) async {
    final response = await _apiClient.dio.get('/v1/financial/campaigns/$id');
    return Campaign.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Campaign> createCampaign(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/v1/financial/campaigns', data: data);
    return Campaign.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Campaign> updateCampaign(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/v1/financial/campaigns/$id', data: data);
    return Campaign.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // ==========================================
  // Financial Entries
  // ==========================================

  Future<({List<FinancialEntry> items, int total})> getEntries({
    int page = 1,
    int perPage = 20,
    String? search,
    String? type,
    String? status,
    String? accountPlanId,
    String? bankAccountId,
    String? dateFrom,
    String? dateTo,
    String? paymentMethod,
    String? congregationId,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;
    if (accountPlanId != null) params['account_plan_id'] = accountPlanId;
    if (bankAccountId != null) params['bank_account_id'] = bankAccountId;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (paymentMethod != null) params['payment_method'] = paymentMethod;
    if (congregationId != null) params['congregation_id'] = congregationId;

    final response = await _apiClient.dio.get('/v1/financial/entries', queryParameters: params);
    final data = response.data;
    final items = (data['data'] as List).map((j) => FinancialEntry.fromJson(j as Map<String, dynamic>)).toList();
    final total = (data['meta'] as Map<String, dynamic>?)?['total'] as int? ?? items.length;
    return (items: items, total: total);
  }

  Future<FinancialEntry> getEntry(String id) async {
    final response = await _apiClient.dio.get('/v1/financial/entries/$id');
    return FinancialEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<FinancialEntry> createEntry(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/v1/financial/entries', data: data);
    return FinancialEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<FinancialEntry> updateEntry(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/v1/financial/entries/$id', data: data);
    return FinancialEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteEntry(String id) async {
    await _apiClient.dio.delete('/v1/financial/entries/$id');
  }

  // ==========================================
  // Balance Report
  // ==========================================

  Future<FinancialBalance> getBalanceReport({
    String? dateFrom,
    String? dateTo,
    String? congregationId,
  }) async {
    final params = <String, dynamic>{};
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (congregationId != null) params['congregation_id'] = congregationId;

    final response = await _apiClient.dio.get('/v1/financial/reports/balance', queryParameters: params);
    return FinancialBalance.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // ==========================================
  // Monthly Closings
  // ==========================================

  Future<({List<MonthlyClosing> items, int total})> getMonthlyClosings({
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};

    final response = await _apiClient.dio.get('/v1/financial/monthly-closings', queryParameters: params);
    final data = response.data;
    final items = (data['data'] as List).map((j) => MonthlyClosing.fromJson(j as Map<String, dynamic>)).toList();
    final total = (data['meta'] as Map<String, dynamic>?)?['total'] as int? ?? items.length;
    return (items: items, total: total);
  }

  Future<MonthlyClosing> createMonthlyClosing(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/v1/financial/monthly-closings', data: data);
    return MonthlyClosing.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
