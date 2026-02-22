import 'package:equatable/equatable.dart';

// ==========================================
// Account Plan
// ==========================================

class AccountPlan extends Equatable {
  final String id;
  final String? parentId;
  final String code;
  final String name;
  final String type; // "receita" or "despesa"
  final int level;
  final bool isActive;
  final String? parentName;
  final int? childrenCount;
  final DateTime? createdAt;

  const AccountPlan({
    required this.id,
    this.parentId,
    required this.code,
    required this.name,
    required this.type,
    this.level = 1,
    this.isActive = true,
    this.parentName,
    this.childrenCount,
    this.createdAt,
  });

  factory AccountPlan.fromJson(Map<String, dynamic> json) {
    return AccountPlan(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      parentName: json['parent_name'] as String?,
      childrenCount: json['children_count'] as int?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'code': code,
        'name': name,
        'type': type,
        if (parentId != null) 'parent_id': parentId,
        if (level > 0) 'level': level,
      };

  @override
  List<Object?> get props => [id];
}

// ==========================================
// Bank Account
// ==========================================

class BankAccount extends Equatable {
  final String id;
  final String name;
  final String type; // "caixa", "conta_corrente", "poupanca", "digital"
  final String? bankName;
  final String? agency;
  final String? accountNumber;
  final double initialBalance;
  final double currentBalance;
  final bool isActive;
  final DateTime? createdAt;

  const BankAccount({
    required this.id,
    required this.name,
    required this.type,
    this.bankName,
    this.agency,
    this.accountNumber,
    this.initialBalance = 0,
    this.currentBalance = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      bankName: json['bank_name'] as String?,
      agency: json['agency'] as String?,
      accountNumber: json['account_number'] as String?,
      initialBalance: _parseDecimal(json['initial_balance']),
      currentBalance: _parseDecimal(json['current_balance']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'type': type,
        if (bankName != null) 'bank_name': bankName,
        if (agency != null) 'agency': agency,
        if (accountNumber != null) 'account_number': accountNumber,
        if (initialBalance != 0) 'initial_balance': initialBalance,
      };

  String get typeLabel {
    switch (type) {
      case 'caixa':
        return 'Caixa';
      case 'conta_corrente':
        return 'Conta Corrente';
      case 'poupanca':
        return 'Poupança';
      case 'digital':
        return 'Conta Digital';
      default:
        return type;
    }
  }

  @override
  List<Object?> get props => [id];
}

// ==========================================
// Campaign
// ==========================================

class Campaign extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double? goalAmount;
  final double raisedAmount;
  final String startDate;
  final String? endDate;
  final String status; // "ativa", "encerrada", "cancelada"
  final int? entriesCount;
  final DateTime? createdAt;

  const Campaign({
    required this.id,
    required this.name,
    this.description,
    this.goalAmount,
    this.raisedAmount = 0,
    required this.startDate,
    this.endDate,
    this.status = 'ativa',
    this.entriesCount,
    this.createdAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      goalAmount: _parseDecimalNullable(json['goal_amount']),
      raisedAmount: _parseDecimal(json['raised_amount']),
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String?,
      status: json['status'] as String? ?? 'ativa',
      entriesCount: json['entries_count'] as int?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (goalAmount != null) 'goal_amount': goalAmount,
        'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };

  double get progressPercent {
    if (goalAmount == null || goalAmount == 0) return 0;
    return (raisedAmount / goalAmount!).clamp(0, 1);
  }

  String get statusLabel {
    switch (status) {
      case 'ativa':
        return 'Ativa';
      case 'encerrada':
        return 'Encerrada';
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
// Financial Entry
// ==========================================

class FinancialEntry extends Equatable {
  final String id;
  final String type; // "receita" or "despesa"
  final double amount;
  final String entryDate;
  final String? dueDate;
  final String? paymentDate;
  final String description;
  final String? paymentMethod;
  final String status; // "pendente", "confirmado"
  final bool isClosed;
  final String? accountPlanName;
  final String? bankAccountName;
  final String? memberName;
  final String? campaignName;
  final String? supplierName;
  final String? congregationId;
  final String? congregationName;
  final DateTime? createdAt;

  // Full fields (when fetched by ID)
  final String? accountPlanId;
  final String? bankAccountId;
  final String? campaignId;
  final String? memberId;
  final String? receiptUrl;
  final String? notes;

  const FinancialEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.entryDate,
    this.dueDate,
    this.paymentDate,
    required this.description,
    this.paymentMethod,
    this.status = 'pendente',
    this.isClosed = false,
    this.accountPlanName,
    this.bankAccountName,
    this.memberName,
    this.campaignName,
    this.supplierName,
    this.congregationId,
    this.congregationName,
    this.createdAt,
    this.accountPlanId,
    this.bankAccountId,
    this.campaignId,
    this.memberId,
    this.receiptUrl,
    this.notes,
  });

  bool get isIncome => type == 'receita';
  bool get isExpense => type == 'despesa';

  factory FinancialEntry.fromJson(Map<String, dynamic> json) {
    return FinancialEntry(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      amount: _parseDecimal(json['amount']),
      entryDate: json['entry_date'] as String? ?? '',
      dueDate: json['due_date'] as String?,
      paymentDate: json['payment_date'] as String?,
      description: json['description'] as String? ?? '',
      paymentMethod: json['payment_method'] as String?,
      status: json['status'] as String? ?? 'pendente',
      isClosed: json['is_closed'] as bool? ?? false,
      accountPlanName: json['account_plan_name'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      memberName: json['member_name'] as String?,
      campaignName: json['campaign_name'] as String?,
      supplierName: json['supplier_name'] as String?,
      congregationId: json['congregation_id'] as String?,
      congregationName: json['congregation_name'] as String?,
      createdAt: _parseDate(json['created_at']),
      accountPlanId: json['account_plan_id'] as String?,
      bankAccountId: json['bank_account_id'] as String?,
      campaignId: json['campaign_id'] as String?,
      memberId: json['member_id'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'type': type,
        'account_plan_id': accountPlanId,
        'bank_account_id': bankAccountId,
        'amount': amount,
        'entry_date': entryDate,
        'description': description,
        if (dueDate != null) 'due_date': dueDate,
        if (paymentDate != null) 'payment_date': paymentDate,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (campaignId != null) 'campaign_id': campaignId,
        if (memberId != null) 'member_id': memberId,
        if (supplierName != null) 'supplier_name': supplierName,
        if (congregationId != null) 'congregation_id': congregationId,
        if (receiptUrl != null) 'receipt_url': receiptUrl,
        if (status != 'pendente') 'status': status,
        if (notes != null) 'notes': notes,
      };

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'dinheiro':
        return 'Dinheiro';
      case 'pix':
        return 'PIX';
      case 'transferencia':
        return 'Transferência';
      case 'cartao_debito':
        return 'Cartão Débito';
      case 'cartao_credito':
        return 'Cartão Crédito';
      case 'cheque':
        return 'Cheque';
      case 'boleto':
        return 'Boleto';
      default:
        return paymentMethod ?? '—';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'confirmado':
        return 'Confirmado';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [id];
}

// ==========================================
// Financial Balance (Report)
// ==========================================

class FinancialBalance extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<CategoryAmount> incomeByCategory;
  final List<CategoryAmount> expenseByCategory;

  const FinancialBalance({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.incomeByCategory,
    required this.expenseByCategory,
  });

  factory FinancialBalance.fromJson(Map<String, dynamic> json) {
    return FinancialBalance(
      totalIncome: _parseDecimal(json['total_income']),
      totalExpense: _parseDecimal(json['total_expense']),
      balance: _parseDecimal(json['balance']),
      incomeByCategory: (json['income_by_category'] as List?)
              ?.map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expenseByCategory: (json['expense_by_category'] as List?)
              ?.map((e) => CategoryAmount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [totalIncome, totalExpense, balance];
}

class CategoryAmount extends Equatable {
  final String categoryName;
  final double amount;
  final int? count;

  const CategoryAmount({
    required this.categoryName,
    required this.amount,
    this.count,
  });

  factory CategoryAmount.fromJson(Map<String, dynamic> json) {
    return CategoryAmount(
      categoryName: json['category_name'] as String? ?? '',
      amount: _parseDecimal(json['amount']),
      count: json['count'] as int?,
    );
  }

  @override
  List<Object?> get props => [categoryName, amount];
}

// ==========================================
// Monthly Closing
// ==========================================

class MonthlyClosing extends Equatable {
  final String id;
  final String referenceMonth;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double previousBalance;
  final double accumulatedBalance;
  final String? closedByName;
  final String? notes;
  final DateTime? createdAt;

  const MonthlyClosing({
    required this.id,
    required this.referenceMonth,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.previousBalance = 0,
    this.accumulatedBalance = 0,
    this.closedByName,
    this.notes,
    this.createdAt,
  });

  factory MonthlyClosing.fromJson(Map<String, dynamic> json) {
    return MonthlyClosing(
      id: json['id'] as String,
      referenceMonth: json['reference_month'] as String? ?? '',
      totalIncome: _parseDecimal(json['total_income']),
      totalExpense: _parseDecimal(json['total_expense']),
      balance: _parseDecimal(json['balance']),
      previousBalance: _parseDecimal(json['previous_balance']),
      accumulatedBalance: _parseDecimal(json['accumulated_balance']),
      closedByName: json['closed_by_name'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id];
}

// ==========================================
// Helpers
// ==========================================

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

double _parseDecimal(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

double? _parseDecimalNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
