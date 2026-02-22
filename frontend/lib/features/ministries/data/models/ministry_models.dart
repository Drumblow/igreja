import 'package:equatable/equatable.dart';

/// Ministry summary for list views (includes leader_name and member_count)
class Ministry extends Equatable {
  final String id;
  final String? churchId;
  final String name;
  final String? description;
  final String? leaderId;
  final String? leaderName;
  final String? congregationId;
  final String? congregationName;
  final bool isActive;
  final int memberCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Detail: list of members (fetched separately from /ministries/:id/members)
  final List<MinistryMember>? members;

  const Ministry({
    required this.id,
    this.churchId,
    required this.name,
    this.description,
    this.leaderId,
    this.leaderName,
    this.congregationId,
    this.congregationName,
    this.isActive = true,
    this.memberCount = 0,
    this.createdAt,
    this.updatedAt,
    this.members,
  });

  /// Parse from MinistrySummary JSON (list endpoint)
  factory Ministry.fromJson(Map<String, dynamic> json) {
    return Ministry(
      id: json['id'] as String,
      churchId: json['church_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      leaderId: json['leader_id'] as String?,
      leaderName: json['leader_name'] as String?,
      congregationId: json['congregation_id'] as String?,
      congregationName: json['congregation_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  /// Build JSON for create request
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (leaderId != null) 'leader_id': leaderId,
      if (congregationId != null) 'congregation_id': congregationId,
    };
  }

  Ministry copyWith({List<MinistryMember>? members}) {
    return Ministry(
      id: id,
      churchId: churchId,
      name: name,
      description: description,
      leaderId: leaderId,
      leaderName: leaderName,
      congregationId: congregationId,
      congregationName: congregationName,
      isActive: isActive,
      memberCount: members?.length ?? memberCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      members: members ?? this.members,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [id];
}

class MinistryMember extends Equatable {
  final String memberId;
  final String fullName;
  final String? roleInMinistry;
  final DateTime? joinedAt;
  final String? phonePrimary;
  final String? email;

  const MinistryMember({
    required this.memberId,
    required this.fullName,
    this.roleInMinistry,
    this.joinedAt,
    this.phonePrimary,
    this.email,
  });

  factory MinistryMember.fromJson(Map<String, dynamic> json) {
    return MinistryMember(
      memberId: json['member_id'] as String,
      fullName: json['full_name'] as String,
      roleInMinistry: json['role_in_ministry'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String)
          : null,
      phonePrimary: json['phone_primary'] as String?,
      email: json['email'] as String?,
    );
  }

  String get formattedRole {
    if (roleInMinistry == null || roleInMinistry!.isEmpty) return 'Membro';
    return roleInMinistry!;
  }

  @override
  List<Object?> get props => [memberId];
}
