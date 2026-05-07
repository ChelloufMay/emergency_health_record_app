class VaccinationModel {
  final String id;
  final String patientId;
  final String vaccineName;
  final String category; // covid, pnv, other
  final int? doseNumber;
  final DateTime? dateAdministered;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaccinationModel({
    required this.id,
    required this.patientId,
    required this.vaccineName,
    required this.category,
    this.doseNumber,
    this.dateAdministered,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  factory VaccinationModel.fromMap(Map<String, dynamic> map) {
    return VaccinationModel(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      vaccineName: map['vaccine_name'] as String,
      category: map['category'] as String? ?? 'other',
      doseNumber: map['dose_number'] is int
          ? map['dose_number'] as int
          : int.tryParse(map['dose_number']?.toString() ?? ''),
      dateAdministered: _parseDate(map['date_administered']),
      notes: map['notes'] as String?,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    return {
      'patient_id': patientId,
      'vaccine_name': vaccineName,
      'category': category,
      'dose_number': doseNumber,
      'date_administered': dateAdministered?.toIso8601String().split('T').first,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}