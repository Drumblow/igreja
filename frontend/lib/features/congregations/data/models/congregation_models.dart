import 'package:equatable/equatable.dart';

/// Congregation model for list and detail views
class Congregation extends Equatable {
  final String id;
  final String? churchId;
  final String name;
  final String? shortName;
  final String type; // 'sede', 'congregacao', 'ponto_de_pregacao'
  final String? leaderId;
  final String? leaderName;
  final String? zipCode;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? phone;
  final String? email;
  final bool isActive;
  final int sortOrder;
  final int activeMembers;
  final int totalMembers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Congregation({
    required this.id,
    this.churchId,
    required this.name,
    this.shortName,
    this.type = 'congregacao',
    this.leaderId,
    this.leaderName,
    this.zipCode,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.phone,
    this.email,
    this.isActive = true,
    this.sortOrder = 0,
    this.activeMembers = 0,
    this.totalMembers = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Congregation.fromJson(Map<String, dynamic> json) {
    return Congregation(
      id: json['id'] as String,
      churchId: json['church_id'] as String?,
      name: json['name'] as String,
      shortName: json['short_name'] as String?,
      type: json['type'] as String? ?? 'congregacao',
      leaderId: json['leader_id'] as String?,
      leaderName: json['leader_name'] as String?,
      zipCode: json['zip_code'] as String?,
      street: json['street'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      activeMembers: (json['active_members'] as num?)?.toInt() ?? 0,
      totalMembers: (json['total_members'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (shortName != null && shortName!.isNotEmpty) 'short_name': shortName,
      if (type.isNotEmpty) 'congregation_type': type,
      if (leaderId != null) 'leader_id': leaderId,
      if (zipCode != null && zipCode!.isNotEmpty) 'zip_code': zipCode,
      if (street != null && street!.isNotEmpty) 'street': street,
      if (number != null && number!.isNotEmpty) 'number': number,
      if (complement != null && complement!.isNotEmpty) 'complement': complement,
      if (neighborhood != null && neighborhood!.isNotEmpty) 'neighborhood': neighborhood,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (state != null && state!.isNotEmpty) 'state': state,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
    };
  }

  Congregation copyWith({
    String? name,
    String? shortName,
    String? type,
    String? leaderId,
    String? leaderName,
    bool? isActive,
    int? activeMembers,
    int? totalMembers,
  }) {
    return Congregation(
      id: id,
      churchId: churchId,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      type: type ?? this.type,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      zipCode: zipCode,
      street: street,
      number: number,
      complement: complement,
      neighborhood: neighborhood,
      city: city,
      state: state,
      phone: phone,
      email: email,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder,
      activeMembers: activeMembers ?? this.activeMembers,
      totalMembers: totalMembers ?? this.totalMembers,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get displayName => shortName ?? name;

  String get typeLabel {
    switch (type) {
      case 'sede':
        return 'Sede';
      case 'congregacao':
        return 'Congregação';
      case 'ponto_de_pregacao':
        return 'Ponto de Pregação';
      default:
        return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'sede':
        return '🏛️';
      case 'congregacao':
        return '⛪';
      case 'ponto_de_pregacao':
        return '📍';
      default:
        return '⛪';
    }
  }

  String get addressShort {
    final parts = <String>[];
    if (neighborhood != null && neighborhood!.isNotEmpty) parts.add(neighborhood!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [id];
}

/// Stats for a single congregation
class CongregationStats {
  final int activeMembers;
  final int totalMembers;
  final int visitors;
  final int congregados;
  final int newThisMonth;
  final double incomeThisMonth;
  final double expenseThisMonth;
  final double balance;
  final int ebdClasses;
  final int ebdStudents;
  final int totalAssets;

  const CongregationStats({
    this.activeMembers = 0,
    this.totalMembers = 0,
    this.visitors = 0,
    this.congregados = 0,
    this.newThisMonth = 0,
    this.incomeThisMonth = 0,
    this.expenseThisMonth = 0,
    this.balance = 0,
    this.ebdClasses = 0,
    this.ebdStudents = 0,
    this.totalAssets = 0,
  });

  factory CongregationStats.fromJson(Map<String, dynamic> json) {
    return CongregationStats(
      activeMembers: (json['active_members'] as num?)?.toInt() ?? 0,
      totalMembers: (json['total_members'] as num?)?.toInt() ?? 0,
      visitors: (json['visitors'] as num?)?.toInt() ?? 0,
      congregados: (json['congregados'] as num?)?.toInt() ?? 0,
      newThisMonth: (json['new_this_month'] as num?)?.toInt() ?? 0,
      incomeThisMonth: (json['income_this_month'] as num?)?.toDouble() ?? 0,
      expenseThisMonth: (json['expense_this_month'] as num?)?.toDouble() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      ebdClasses: (json['ebd_classes'] as num?)?.toInt() ?? 0,
      ebdStudents: (json['ebd_students'] as num?)?.toInt() ?? 0,
      totalAssets: (json['total_assets'] as num?)?.toInt() ?? 0,
    );
  }
}

/// User access to a congregation
class CongregationUser {
  final String userId;
  final String email;
  final String roleInCongregation;
  final bool isPrimary;
  final String? userRoleName;

  const CongregationUser({
    required this.userId,
    required this.email,
    required this.roleInCongregation,
    this.isPrimary = false,
    this.userRoleName,
  });

  factory CongregationUser.fromJson(Map<String, dynamic> json) {
    return CongregationUser(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      roleInCongregation: json['role_in_congregation'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      userRoleName: json['user_role_name'] as String?,
    );
  }

  String get roleLabel {
    switch (roleInCongregation) {
      case 'dirigente':
        return 'Dirigente';
      case 'secretario':
        return 'Secretário(a)';
      case 'tesoureiro':
        return 'Tesoureiro(a)';
      case 'professor_ebd':
        return 'Professor(a) EBD';
      case 'viewer':
        return 'Visualização';
      default:
        return roleInCongregation;
    }
  }
}

/// Assign members result
class AssignMembersResult {
  final int assigned;
  final int skipped;

  const AssignMembersResult({
    this.assigned = 0,
    this.skipped = 0,
  });

  factory AssignMembersResult.fromJson(Map<String, dynamic> json) {
    return AssignMembersResult(
      assigned: (json['assigned'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Congregations overview for reports
class CongregationsOverview {
  final int totalCongregations;
  final int totalMembersAll;
  final double totalIncomeMonth;
  final double totalExpenseMonth;
  final List<CongregationOverviewItem> congregations;

  const CongregationsOverview({
    this.totalCongregations = 0,
    this.totalMembersAll = 0,
    this.totalIncomeMonth = 0,
    this.totalExpenseMonth = 0,
    this.congregations = const [],
  });

  factory CongregationsOverview.fromJson(Map<String, dynamic> json) {
    return CongregationsOverview(
      totalCongregations: (json['total_congregations'] as num?)?.toInt() ?? 0,
      totalMembersAll: (json['total_members_all'] as num?)?.toInt() ?? 0,
      totalIncomeMonth: (json['total_income_month'] as num?)?.toDouble() ?? 0,
      totalExpenseMonth: (json['total_expense_month'] as num?)?.toDouble() ?? 0,
      congregations: (json['congregations'] as List?)
              ?.map((e) =>
                  CongregationOverviewItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CongregationOverviewItem {
  final String id;
  final String name;
  final String type;
  final int activeMembers;
  final double incomeMonth;
  final double expenseMonth;

  const CongregationOverviewItem({
    required this.id,
    required this.name,
    this.type = 'congregacao',
    this.activeMembers = 0,
    this.incomeMonth = 0,
    this.expenseMonth = 0,
  });

  factory CongregationOverviewItem.fromJson(Map<String, dynamic> json) {
    return CongregationOverviewItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'congregacao',
      activeMembers: (json['active_members'] as num?)?.toInt() ?? 0,
      incomeMonth: (json['income_month'] as num?)?.toDouble() ?? 0,
      expenseMonth: (json['expense_month'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Compare report between congregations
class CongregationCompareReport {
  final String metric;
  final String? periodStart;
  final String? periodEnd;
  final List<CongregationCompareItem> congregations;

  const CongregationCompareReport({
    required this.metric,
    this.periodStart,
    this.periodEnd,
    this.congregations = const [],
  });

  factory CongregationCompareReport.fromJson(Map<String, dynamic> json) {
    return CongregationCompareReport(
      metric: json['metric'] as String? ?? 'members',
      periodStart: json['period_start'] as String?,
      periodEnd: json['period_end'] as String?,
      congregations: (json['congregations'] as List?)
              ?.map((e) =>
                  CongregationCompareItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CongregationCompareItem {
  final String id;
  final String name;
  final String type;
  final double value1;
  final double value2;
  final double value3;
  final String? label1;
  final String? label2;
  final String? label3;

  const CongregationCompareItem({
    required this.id,
    required this.name,
    this.type = 'congregacao',
    this.value1 = 0,
    this.value2 = 0,
    this.value3 = 0,
    this.label1,
    this.label2,
    this.label3,
  });

  factory CongregationCompareItem.fromJson(Map<String, dynamic> json) {
    return CongregationCompareItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'congregacao',
      value1: (json['value_1'] as num?)?.toDouble() ?? 0,
      value2: (json['value_2'] as num?)?.toDouble() ?? 0,
      value3: (json['value_3'] as num?)?.toDouble() ?? 0,
      label1: json['label_1'] as String?,
      label2: json['label_2'] as String?,
      label3: json['label_3'] as String?,
    );
  }
}
