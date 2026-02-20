import 'package:equatable/equatable.dart';

class ChurchRole extends Equatable {
  final String id;
  final String churchId;
  final String key;
  final String displayName;
  final String? investitureType;
  final int sortOrder;
  final bool isDefault;
  final bool isActive;

  const ChurchRole({
    required this.id,
    required this.churchId,
    required this.key,
    required this.displayName,
    this.investitureType,
    this.sortOrder = 0,
    this.isDefault = false,
    this.isActive = true,
  });

  factory ChurchRole.fromJson(Map<String, dynamic> json) {
    return ChurchRole(
      id: json['id'] as String,
      churchId: json['church_id'] as String? ?? '',
      key: json['key'] as String,
      displayName: json['display_name'] as String,
      investitureType: json['investiture_type'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Rótulo amigável para o tipo de investidura
  String get investitureLabel => switch (investitureType) {
        'consagracao' => 'Data de Consagração',
        'ordenacao' => 'Data de Ordenação',
        'eleicao' => 'Data de Eleição',
        'nomeacao' => 'Data de Nomeação',
        _ => 'Data de Investidura',
      };

  @override
  List<Object?> get props => [id];
}
