import 'package:equatable/equatable.dart';

class Family extends Equatable {
  final String id;
  final String churchId;
  final String name;
  final String? headId;

  // Address
  final String? zipCode;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;

  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Detail only
  final List<FamilyMember>? members;

  const Family({
    required this.id,
    this.churchId = '',
    required this.name,
    this.headId,
    this.zipCode,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.members,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      churchId: json['church_id'] as String? ?? '',
      name: json['name'] as String,
      headId: json['head_id'] as String?,
      zipCode: json['zip_code'] as String?,
      street: json['street'] as String?,
      number: json['number'] as String?,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      members: json['members'] != null
          ? (json['members'] as List)
              .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (headId != null) 'head_id': headId,
      if (zipCode != null && zipCode!.isNotEmpty) 'zip_code': zipCode,
      if (street != null && street!.isNotEmpty) 'street': street,
      if (number != null && number!.isNotEmpty) 'number': number,
      if (complement != null && complement!.isNotEmpty) 'complement': complement,
      if (neighborhood != null && neighborhood!.isNotEmpty)
        'neighborhood': neighborhood,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (state != null && state!.isNotEmpty) 'state': state,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  String get formattedAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (number != null && number!.isNotEmpty) parts.add('nº $number');
    if (complement != null && complement!.isNotEmpty) parts.add(complement!);
    return parts.isNotEmpty ? parts.join(', ') : '';
  }

  String get cityState {
    final parts = <String?>[];
    if (city != null && city!.isNotEmpty) parts.add(city);
    if (state != null && state!.isNotEmpty) parts.add(state);
    return parts.where((p) => p != null).join(' - ');
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [id];
}

class FamilyMember extends Equatable {
  final String memberId;
  final String fullName;
  final String relationship;
  final String? phonePrimary;
  final String? email;
  final DateTime? birthDate;

  const FamilyMember({
    required this.memberId,
    required this.fullName,
    required this.relationship,
    this.phonePrimary,
    this.email,
    this.birthDate,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      memberId: json['member_id'] as String,
      fullName: json['full_name'] as String,
      relationship: json['relationship'] as String,
      phonePrimary: json['phone_primary'] as String?,
      email: json['email'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
    );
  }

  String get formattedRelationship {
    return switch (relationship) {
      'chefe' => 'Chefe da Família',
      'conjuge' => 'Cônjuge',
      'filho' => 'Filho(a)',
      'pai' => 'Pai',
      'mae' => 'Mãe',
      'irmao' => 'Irmão(ã)',
      'neto' => 'Neto(a)',
      'avo' => 'Avô/Avó',
      'outro' => 'Outro',
      _ => relationship,
    };
  }

  @override
  List<Object?> get props => [memberId, relationship];
}
