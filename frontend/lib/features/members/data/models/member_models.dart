import 'package:equatable/equatable.dart';

class Member extends Equatable {
  final String id;
  final String churchId;
  final String? familyId;

  // Personal data
  final String fullName;
  final String? socialName;
  final DateTime? birthDate;
  final String gender;
  final String? maritalStatus;
  final String? cpf;
  final String? rg;
  final String? email;
  final String? phonePrimary;
  final String? phoneSecondary;
  final String? photoUrl;

  // Address
  final String? zipCode;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;

  // Additional
  final String? profession;
  final String? workplace;
  final String? birthplaceCity;
  final String? birthplaceState;
  final String? nationality;
  final String? educationLevel;
  final String? bloodType;

  // Ecclesiastical
  final DateTime? conversionDate;
  final DateTime? waterBaptismDate;
  final DateTime? spiritBaptismDate;
  final String? originChurch;
  final DateTime? entryDate;
  final String? entryType;
  final String? rolePosition;
  final DateTime? ordinationDate;

  // Status
  final String status;
  final DateTime? statusChangedAt;
  final String? statusReason;

  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Member({
    required this.id,
    this.churchId = '',
    this.familyId,
    required this.fullName,
    this.socialName,
    this.birthDate,
    required this.gender,
    this.maritalStatus,
    this.cpf,
    this.rg,
    this.email,
    this.phonePrimary,
    this.phoneSecondary,
    this.photoUrl,
    this.zipCode,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.profession,
    this.workplace,
    this.birthplaceCity,
    this.birthplaceState,
    this.nationality,
    this.educationLevel,
    this.bloodType,
    this.conversionDate,
    this.waterBaptismDate,
    this.spiritBaptismDate,
    this.originChurch,
    this.entryDate,
    this.entryType,
    this.rolePosition,
    this.ordinationDate,
    required this.status,
    this.statusChangedAt,
    this.statusReason,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      churchId: json['church_id'] as String? ?? '',
      familyId: json['family_id'] as String?,
      fullName: json['full_name'] as String,
      socialName: json['social_name'] as String?,
      birthDate: _parseDate(json['birth_date']),
      gender: json['gender'] as String? ?? '',
      maritalStatus: json['marital_status'] as String?,
      cpf: json['cpf'] as String?,
      rg: json['rg'] as String?,
      email: json['email'] as String?,
      phonePrimary: json['phone_primary'] as String?,
      phoneSecondary: json['phone_secondary'] as String?,
      photoUrl: json['photo_url'] as String?,
      zipCode: json['zip_code'] as String?,
      street: json['street'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      profession: json['profession'] as String?,
      workplace: json['workplace'] as String?,
      birthplaceCity: json['birthplace_city'] as String?,
      birthplaceState: json['birthplace_state'] as String?,
      nationality: json['nationality'] as String?,
      educationLevel: json['education_level'] as String?,
      bloodType: json['blood_type'] as String?,
      conversionDate: _parseDate(json['conversion_date']),
      waterBaptismDate: _parseDate(json['water_baptism_date']),
      spiritBaptismDate: _parseDate(json['spirit_baptism_date']),
      originChurch: json['origin_church'] as String?,
      entryDate: _parseDate(json['entry_date']),
      entryType: json['entry_type'] as String?,
      rolePosition: json['role_position'] as String?,
      ordinationDate: _parseDate(json['ordination_date']),
      status: json['status'] as String? ?? 'ativo',
      statusChangedAt: _parseDate(json['status_changed_at']),
      statusReason: json['status_reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'full_name': fullName,
      if (socialName != null) 'social_name': socialName,
      if (birthDate != null) 'birth_date': _formatDate(birthDate),
      'gender': gender,
      if (maritalStatus != null) 'marital_status': maritalStatus,
      if (cpf != null) 'cpf': cpf,
      if (rg != null) 'rg': rg,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (phonePrimary != null) 'phone_primary': phonePrimary,
      if (phoneSecondary != null) 'phone_secondary': phoneSecondary,
      if (zipCode != null) 'zip_code': zipCode,
      if (street != null) 'street': street,
      if (number != null) 'number': number,
      if (complement != null) 'complement': complement,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (profession != null) 'profession': profession,
      if (workplace != null) 'workplace': workplace,
      if (birthplaceCity != null) 'birthplace_city': birthplaceCity,
      if (birthplaceState != null) 'birthplace_state': birthplaceState,
      if (nationality != null) 'nationality': nationality,
      if (educationLevel != null) 'education_level': educationLevel,
      if (bloodType != null) 'blood_type': bloodType,
      if (conversionDate != null) 'conversion_date': _formatDate(conversionDate),
      if (waterBaptismDate != null) 'water_baptism_date': _formatDate(waterBaptismDate),
      if (spiritBaptismDate != null) 'spirit_baptism_date': _formatDate(spiritBaptismDate),
      if (originChurch != null) 'origin_church': originChurch,
      if (entryDate != null) 'entry_date': _formatDate(entryDate),
      if (entryType != null) 'entry_type': entryType,
      if (rolePosition != null) 'role_position': rolePosition,
      if (ordinationDate != null) 'ordination_date': _formatDate(ordinationDate),
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateJson() => toCreateJson();

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [id];
}

class MemberStats extends Equatable {
  final int totalActive;
  final int totalInactive;
  final int newMembersThisMonth;
  final int newMembersThisYear;

  const MemberStats({
    required this.totalActive,
    required this.totalInactive,
    required this.newMembersThisMonth,
    required this.newMembersThisYear,
  });

  int get total => totalActive + totalInactive;

  factory MemberStats.fromJson(Map<String, dynamic> json) {
    return MemberStats(
      totalActive: json['total_active'] as int? ?? 0,
      totalInactive: json['total_inactive'] as int? ?? 0,
      newMembersThisMonth: json['new_members_this_month'] as int? ?? 0,
      newMembersThisYear: json['new_members_this_year'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalActive, totalInactive, newMembersThisMonth, newMembersThisYear];
}
