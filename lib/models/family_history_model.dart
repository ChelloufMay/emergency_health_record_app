class FamilyHistoryModel {
  final String id;
  final String patientId;
  final String? relation;
  final String conditionName;
  final String? category;
  final bool? isGenetic;
  final String? notes;
  final DateTime createdAt;

  FamilyHistoryModel({
    required this.id,
    required this.patientId,
    this.relation,
    required this.conditionName,
    this.category,
    this.isGenetic,
    this.notes,
    required this.createdAt,
  });

  factory FamilyHistoryModel.fromMap(Map<String, dynamic> map) {
    return FamilyHistoryModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      relation: map['relation'] as String?,
      conditionName: map['condition_name'] as String,
      category: map['category'] as String?,
      isGenetic: map['is_genetic'] as bool?,
      notes: map['notes'] as String?,
      createdAt:
      DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'relation': relation,
      'condition_name': conditionName,
      'category': category,
      'is_genetic': isGenetic,
      'notes': notes,
    };
  }
}