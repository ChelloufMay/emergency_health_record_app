class FamilyHistoryModel {
  final String id;
  final String patientId;
  final String? relation;
  final String conditionName;
  final String? category;
  final bool? isGenetic;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FamilyHistoryModel({
    required this.id,
    required this.patientId,
    this.relation,
    required this.conditionName,
    this.category,
    this.isGenetic,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory FamilyHistoryModel.fromMap(Map<String, dynamic> map) {
    return FamilyHistoryModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      relation: map['relation'] as String?,
      conditionName: map['condition_name'] as String,
      category: map['category'] as String?,
      isGenetic: map['is_genetic'] as bool?,
      notes: map['notes'] as String?,
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: map['updated_at'] != null ? _parseDateTime(map['updated_at']) : null,
    );
  }

  /// Timestamps are handled by the database.
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