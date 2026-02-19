import 'package:equatable/equatable.dart';

// ==========================================
// Helper parsers
// ==========================================

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

// ==========================================
// Church
// ==========================================

class Church extends Equatable {
  final String id;
  final String name;
  final String? legalName;
  final String? cnpj;
  final String? email;
  final String? phone;
  final String? website;

  // Address
  final String? zipCode;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;

  // Details
  final String? logoUrl;
  final String? denomination;
  final String? foundedAt;
  final String? pastorName;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Church({
    required this.id,
    required this.name,
    this.legalName,
    this.cnpj,
    this.email,
    this.phone,
    this.website,
    this.zipCode,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.logoUrl,
    this.denomination,
    this.foundedAt,
    this.pastorName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Church.fromJson(Map<String, dynamic> json) {
    return Church(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      legalName: json['legal_name'] as String?,
      cnpj: json['cnpj'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      zipCode: json['zip_code'] as String?,
      street: json['street'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      logoUrl: json['logo_url'] as String?,
      denomination: json['denomination'] as String?,
      foundedAt: json['founded_at'] as String?,
      pastorName: json['pastor_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (legalName != null) 'legal_name': legalName,
      if (cnpj != null) 'cnpj': cnpj,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (website != null) 'website': website,
      if (zipCode != null) 'zip_code': zipCode,
      if (street != null) 'street': street,
      if (number != null) 'number': number,
      if (complement != null) 'complement': complement,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (denomination != null) 'denomination': denomination,
      if (foundedAt != null) 'founded_at': foundedAt,
      if (pastorName != null) 'pastor_name': pastorName,
    };
  }

  @override
  List<Object?> get props => [id, name, isActive];
}

// ==========================================
// User (for management)
// ==========================================

class AppUser extends Equatable {
  final String id;
  final String email;
  final String? roleName;
  final String? roleDisplayName;
  final String? memberName;
  final bool isActive;
  final bool emailVerified;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.roleName,
    this.roleDisplayName,
    this.memberName,
    this.isActive = true,
    this.emailVerified = false,
    this.lastLoginAt,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      roleName: json['role_name'] as String?,
      roleDisplayName: json['role_display_name'] as String?,
      memberName: json['member_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      emailVerified: json['email_verified'] as bool? ?? false,
      lastLoginAt: _parseDate(json['last_login_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, email, isActive];
}

// ==========================================
// Role
// ==========================================

class AppRole extends Equatable {
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final bool isSystem;

  const AppRole({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.isSystem = false,
  });

  factory AppRole.fromJson(Map<String, dynamic> json) {
    return AppRole(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      description: json['description'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name];
}
