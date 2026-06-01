import 'model_utils.dart';

// Represents a record in the patient's family medical history. --> maps to the 'family_history' table in the database.
class FamilyHistoryModel {
  final String? id;
  final String patientId;
  final String? relation;
  final String conditionName;
  final String? category;
  final bool? isGenetic;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FamilyHistoryModel({
    this.id,
    required this.patientId,
    this.relation,
    required this.conditionName,
    this.category,
    this.isGenetic,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory FamilyHistoryModel.fromMap(Map map) {
    return FamilyHistoryModel(
      id: map['id']?.toString(),
      patientId: map['patient_id']?.toString() ?? '',
      relation: map['relation']?.toString(),
      conditionName: map['condition_name']?.toString() ?? '',
      category: map['category']?.toString(),
      isGenetic: asBool(map['is_genetic']),
      notes: map['notes']?.toString(),
      createdAt: asDateTime(map['created_at']),
      updatedAt: asDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() => cleanMap({
    'patient_id': patientId,
    'relation': relation,
    'condition_name': conditionName,
    'category': category,
    'is_genetic': isGenetic,
    'notes': notes,
  });

  Map<String, dynamic> toUpdateMap() => cleanMap({
    // patient_id should not move between patients.
    'relation': relation,
    'condition_name': conditionName,
    'category': category,
    'is_genetic': isGenetic,
    'notes': notes,
  });

  Map<String, dynamic> toMap() => toInsertMap();
}
